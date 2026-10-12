/**
 * RDV Performance — Autorização administrativa para cadastro de Professores.
 *
 * Funções "callable" (HTTPS) consumidas pelo app iOS:
 *  - getTeacherSignupCode      (somente administrador) consulta o código vigente.
 *  - rotateTeacherSignupCode   (somente administrador) gera um novo código e invalida o anterior.
 *  - validateTeacherSignupCode (público, com limite de tentativas) valida o código e emite
 *                              uma autorização temporária de uso único (ticket).
 *  - createTeacherAccount      (público, exige ticket válido) cria a conta no Firebase Auth e o
 *                              perfil TRAINER no Firestore, consumindo o ticket.
 *
 * Coleções utilizadas (acesso exclusivo pelo Admin SDK; bloqueadas para clientes nas regras):
 *  - teacher_signup_config/current
 *  - teacher_signup_tickets/{sha256(ticket)}
 *  - teacher_signup_attempts/{sha256(ip)}
 *
 * IMPORTANTE: nunca registrar em logs o código, o ticket, a senha ou dados pessoais.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineString } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const db = admin.firestore();
const { FieldValue, Timestamp } = admin.firestore;

// A região precisa coincidir com a utilizada pelo app iOS (TeacherAuthorizationService.swift).
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

// Lista de e-mails administradores separados por vírgula (ver functions/.env).
// Alternativamente, contas com a custom claim { admin: true } também são aceitas.
const ADMIN_EMAILS = defineString("ADMIN_EMAILS", { default: "ric.vecchio@gmail.com" });

const CONFIG_DOC = db.collection("teacher_signup_config").doc("current");
const TICKETS = db.collection("teacher_signup_tickets");
const ATTEMPTS = db.collection("teacher_signup_attempts");
const USERS = db.collection("users");

// Alfabeto sem caracteres ambíguos (sem I, O, 0 e 1): 32 símbolos => 5 bits por caractere.
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const CODE_PREFIX = "RDV";
const CODE_GROUPS = 3;
const CODE_GROUP_LENGTH = 4;
const CODE_LENGTH = CODE_GROUPS * CODE_GROUP_LENGTH; // 12 caracteres aleatórios (60 bits)

const TICKET_TTL_MS = 30 * 60 * 1000; // autorização temporária válida por 30 minutos
const MAX_FAILED_ATTEMPTS = 5; // tentativas inválidas permitidas por janela
const ATTEMPT_WINDOW_MS = 15 * 60 * 1000; // janela de contagem
const LOCK_DURATION_MS = 30 * 60 * 1000; // bloqueio após exceder o limite

const FOCUS_AREAS = new Set(["CROSSFIT", "GYM", "HOME"]);

// ---------------------------------------------------------------------------
// Utilitários
// ---------------------------------------------------------------------------

function sha256(value) {
  return crypto.createHash("sha256").update(value, "utf8").digest("hex");
}

function safeEqualHex(a, b) {
  if (typeof a !== "string" || typeof b !== "string" || a.length !== b.length) return false;
  return crypto.timingSafeEqual(Buffer.from(a, "hex"), Buffer.from(b, "hex"));
}

function toMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (typeof value === "number") return value;
  return 0;
}

function generateRawCode() {
  let raw = "";
  for (let i = 0; i < CODE_LENGTH; i += 1) {
    raw += CODE_ALPHABET[crypto.randomInt(0, CODE_ALPHABET.length)];
  }
  return raw;
}

function formatCode(raw) {
  const groups = [];
  for (let i = 0; i < raw.length; i += CODE_GROUP_LENGTH) {
    groups.push(raw.slice(i, i + CODE_GROUP_LENGTH));
  }
  return `${CODE_PREFIX}-${groups.join("-")}`;
}

// Normaliza a entrada do usuário: ignora hífens/espaços, aceita com ou sem o prefixo "RDV".
function normalizeCode(input) {
  if (typeof input !== "string" || input.length > 64) return null;
  let value = input.toUpperCase().replace(/[^A-Z0-9]/g, "");
  if (value.length === CODE_PREFIX.length + CODE_LENGTH && value.startsWith(CODE_PREFIX)) {
    value = value.slice(CODE_PREFIX.length);
  }
  if (value.length !== CODE_LENGTH) return null;
  for (const ch of value) {
    if (!CODE_ALPHABET.includes(ch)) return null;
  }
  return value;
}

function clientIp(request) {
  const raw = request.rawRequest;
  const forwarded = raw && raw.headers ? raw.headers["x-forwarded-for"] : undefined;
  if (typeof forwarded === "string" && forwarded.trim()) {
    // O último valor é o adicionado pela infraestrutura do Google (não controlado pelo cliente).
    const parts = forwarded.split(",").map((p) => p.trim()).filter(Boolean);
    if (parts.length) return parts[parts.length - 1];
  }
  return (raw && raw.ip) || "unknown";
}

function fail(code, reason, message) {
  return new HttpsError(code, message, { reason });
}

function assertAdmin(request) {
  const auth = request.auth;
  if (!auth) {
    throw fail("unauthenticated", "permission-denied", "Authentication required.");
  }
  if (auth.token && auth.token.admin === true) return;

  const email = String((auth.token && auth.token.email) || "").trim().toLowerCase();
  const allowed = ADMIN_EMAILS.value()
    .split(",")
    .map((item) => item.trim().toLowerCase())
    .filter(Boolean);

  if (email && allowed.includes(email)) return;
  throw fail("permission-denied", "permission-denied", "Not allowed.");
}

function buildConfig(raw, version, uid) {
  return {
    code: formatCode(raw),
    codeHash: sha256(raw),
    version,
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: uid || null,
  };
}

function configResponse(data) {
  return {
    code: data.code,
    version: data.version,
  };
}

// ---------------------------------------------------------------------------
// Administração do código
// ---------------------------------------------------------------------------

exports.getTeacherSignupCode = onCall(async (request) => {
  assertAdmin(request);

  const data = await db.runTransaction(async (tx) => {
    const snap = await tx.get(CONFIG_DOC);
    if (snap.exists && snap.get("code") && snap.get("codeHash")) {
      return snap.data();
    }
    // Primeiro acesso: gera o código inicial.
    const created = buildConfig(generateRawCode(), 1, request.auth.uid);
    tx.set(CONFIG_DOC, created);
    return created;
  });

  return configResponse(data);
});

exports.rotateTeacherSignupCode = onCall(async (request) => {
  assertAdmin(request);

  const data = await db.runTransaction(async (tx) => {
    const snap = await tx.get(CONFIG_DOC);
    const currentVersion = snap.exists ? Number(snap.get("version") || 0) : 0;
    const updated = buildConfig(generateRawCode(), currentVersion + 1, request.auth.uid);
    tx.set(CONFIG_DOC, updated);
    return updated;
  });

  logger.info("Teacher signup code rotated.", { version: data.version });
  return configResponse(data);
});

// ---------------------------------------------------------------------------
// Validação do código (emite autorização temporária de uso único)
// ---------------------------------------------------------------------------

exports.validateTeacherSignupCode = onCall(async (request) => {
  const normalized = normalizeCode(request.data && request.data.code);
  const attemptRef = ATTEMPTS.doc(sha256(`ip:${clientIp(request)}`));

  const outcome = await db.runTransaction(async (tx) => {
    const now = Date.now();
    const [attemptSnap, configSnap] = await Promise.all([tx.get(attemptRef), tx.get(CONFIG_DOC)]);
    const attempt = attemptSnap.exists ? attemptSnap.data() : {};

    if (toMillis(attempt.lockedUntil) > now) {
      return { status: "locked" };
    }

    if (!configSnap.exists || !configSnap.get("codeHash")) {
      return { status: "not-configured" };
    }

    const matches = normalized !== null && safeEqualHex(sha256(normalized), configSnap.get("codeHash"));

    if (!matches) {
      const windowStart = toMillis(attempt.windowStart);
      const inWindow = windowStart > 0 && now - windowStart < ATTEMPT_WINDOW_MS;
      const failures = (inWindow ? Number(attempt.failures || 0) : 0) + 1;

      if (failures >= MAX_FAILED_ATTEMPTS) {
        tx.set(attemptRef, {
          failures: 0,
          windowStart: Timestamp.fromMillis(now),
          lockedUntil: Timestamp.fromMillis(now + LOCK_DURATION_MS),
          expiresAt: Timestamp.fromMillis(now + LOCK_DURATION_MS + ATTEMPT_WINDOW_MS),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return { status: "locked" };
      }

      tx.set(attemptRef, {
        failures,
        windowStart: inWindow ? attempt.windowStart : Timestamp.fromMillis(now),
        lockedUntil: null,
        expiresAt: Timestamp.fromMillis(now + ATTEMPT_WINDOW_MS),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { status: "invalid" };
    }

    const ticket = crypto.randomBytes(32).toString("base64url");
    tx.set(TICKETS.doc(sha256(ticket)), {
      status: "issued",
      codeVersion: configSnap.get("version"),
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(now + TICKET_TTL_MS),
    });

    if (attemptSnap.exists) {
      tx.delete(attemptRef);
    }

    return { status: "ok", ticket, expiresAtMillis: now + TICKET_TTL_MS };
  });

  switch (outcome.status) {
    case "ok":
      return { ticket: outcome.ticket, expiresAtMillis: outcome.expiresAtMillis };
    case "locked":
      throw fail("resource-exhausted", "too-many-attempts", "Too many attempts.");
    case "not-configured":
      throw fail("failed-precondition", "not-configured", "Teacher signup is not configured.");
    default:
      throw fail("invalid-argument", "invalid-code", "Invalid authorization code.");
  }
});

// ---------------------------------------------------------------------------
// Criação efetiva da conta de Professor (consome o ticket)
// ---------------------------------------------------------------------------

function readString(value, maxLength, { required = false, trim = true } = {}) {
  if (value === undefined || value === null) {
    if (required) throw fail("invalid-argument", "invalid-data", "Invalid data.");
    return "";
  }
  if (typeof value !== "string") throw fail("invalid-argument", "invalid-data", "Invalid data.");
  const result = trim ? value.trim() : value;
  if (result.length > maxLength) throw fail("invalid-argument", "invalid-data", "Invalid data.");
  if (required && !result) throw fail("invalid-argument", "invalid-data", "Invalid data.");
  return result;
}

function sanitizeTeacherInput(data) {
  const name = readString(data.name, 120, { required: true });
  const email = readString(data.email, 254, { required: true }).toLowerCase();
  const password = readString(data.password, 128, { required: true, trim: false });
  const phone = readString(data.phone, 20).replace(/\D/g, "");
  const focusArea = readString(data.focusArea, 20, { required: true }).toUpperCase();
  const cref = readString(data.cref, 40);
  const bio = readString(data.bio, 2000);
  const gymName = readString(data.gymName, 120);

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw fail("invalid-argument", "invalid-email", "Invalid email.");
  }
  if (password.length < 6) {
    throw fail("invalid-argument", "weak-password", "Weak password.");
  }
  if (!FOCUS_AREAS.has(focusArea)) {
    throw fail("invalid-argument", "invalid-data", "Invalid data.");
  }

  return { name, email, password, phone, focusArea, cref, bio, gymName };
}

function mapAuthError(error) {
  const code = error && error.code ? String(error.code) : "";
  switch (code) {
    case "auth/email-already-exists":
      return fail("already-exists", "email-already-exists", "Email already in use.");
    case "auth/invalid-email":
      return fail("invalid-argument", "invalid-email", "Invalid email.");
    case "auth/invalid-password":
      return fail("invalid-argument", "weak-password", "Weak password.");
    default:
      logger.error("Teacher account creation failed in Firebase Auth.", { code });
      return fail("internal", "unknown", "Unable to create account.");
  }
}

async function releaseTicket(ticketRef) {
  try {
    await ticketRef.update({ status: "issued", processingAt: FieldValue.delete() });
  } catch (error) {
    // Sem liberação, o ticket permanece bloqueado e o usuário precisa validar o código novamente.
    logger.warn("Unable to release teacher signup ticket.", { code: error && error.code });
  }
}

exports.createTeacherAccount = onCall(async (request) => {
  const data = request.data || {};
  const ticket = typeof data.ticket === "string" ? data.ticket : "";

  if (!ticket || ticket.length > 128) {
    throw fail("failed-precondition", "authorization-expired", "Authorization expired.");
  }

  const input = sanitizeTeacherInput(data);
  const ticketRef = TICKETS.doc(sha256(ticket));

  // 1) Reserva o ticket de forma atômica (impede uso concorrente ou repetido).
  await db.runTransaction(async (tx) => {
    const now = Date.now();
    const [ticketSnap, configSnap] = await Promise.all([tx.get(ticketRef), tx.get(CONFIG_DOC)]);

    const expired = fail("failed-precondition", "authorization-expired", "Authorization expired.");

    if (!ticketSnap.exists) throw expired;
    const ticketData = ticketSnap.data();

    if (ticketData.status !== "issued") throw expired;
    if (toMillis(ticketData.expiresAt) <= now) throw expired;

    // Um novo código gerado pelo administrador invalida as autorizações anteriores.
    if (!configSnap.exists || configSnap.get("version") !== ticketData.codeVersion) throw expired;

    tx.update(ticketRef, { status: "processing", processingAt: Timestamp.fromMillis(now) });
  });

  // 2) Cria a conta no Firebase Authentication.
  let userRecord;
  try {
    userRecord = await admin.auth().createUser({
      email: input.email,
      password: input.password,
    });
  } catch (error) {
    await releaseTicket(ticketRef);
    throw mapAuthError(error);
  }

  // 3) Cria o perfil TRAINER (mesma estrutura gravada anteriormente pelo app).
  try {
    await USERS.doc(userRecord.uid).create({
      name: input.name,
      email: input.email,
      userType: "TRAINER",
      phone: input.phone || null,
      focusArea: input.focusArea,
      cref: input.cref || null,
      bio: input.bio || null,
      gymName: input.gymName || null,
      defaultCategory: null,
      active: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    // Evita contas parcialmente cadastradas.
    try {
      await admin.auth().deleteUser(userRecord.uid);
    } catch (deleteError) {
      logger.error("Unable to roll back teacher Auth account.", { code: deleteError && deleteError.code });
    }
    await releaseTicket(ticketRef);
    logger.error("Unable to create teacher profile.", { code: error && error.code });
    throw fail("internal", "unknown", "Unable to create account.");
  }

  // 4) Marca o ticket como utilizado.
  try {
    await ticketRef.update({
      status: "used",
      usedAt: FieldValue.serverTimestamp(),
      usedByUid: userRecord.uid,
      processingAt: FieldValue.delete(),
    });
  } catch (error) {
    // O ticket permanece em "processing" e não pode ser reutilizado.
    logger.warn("Unable to mark teacher signup ticket as used.", { code: error && error.code });
  }

  return { uid: userRecord.uid };
});

