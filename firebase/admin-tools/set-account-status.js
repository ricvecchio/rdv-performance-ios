#!/usr/bin/env node
// =============================================================================
// RDV Performance — Bloqueio/desbloqueio de conta no Firebase Authentication (MANUAL)
// =============================================================================
//
// Executar SOMENTE em ambiente confiável. Não faz parte do app iOS.
//
// O app (AdminUsersView) altera users/{uid}.active; as regras do Firestore negam
// todo acesso a dados para contas com active == false. Este script complementa o
// bloqueio no Firebase Authentication (plano Spark não permite fazê-lo pelo app):
//
//   --disable : Auth disabled=true + revoga refresh tokens + users/{uid}.active=false
//   --enable  : Auth disabled=false + users/{uid}.active=true
//   --check   : mostra o estado no Auth e no Firestore para o UID (sem alterar)
//   --check-all : lista contas com Auth e Firestore inconsistentes (sem alterar)
//
// Nunca altera contas ADMIN (userType ADMIN ou claim admin). Nunca cria/exclui contas.
// Sem --apply, apenas mostra o plano (dry-run).
//
// Uso:
//   cd firebase/admin-tools && npm install
//   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/Downloads/<chave>.json"
//   node set-account-status.js --project rdvperformanceapp --uid <UID> --check
//   node set-account-status.js --project rdvperformanceapp --uid <UID> --disable --apply
//   node set-account-status.js --project rdvperformanceapp --uid <UID> --enable --apply
//   node set-account-status.js --project rdvperformanceapp --check-all
// =============================================================================

"use strict";

const admin = require("firebase-admin");

function parseArgs(argv) {
  const args = { apply: false };
  const modes = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--uid") args.uid = argv[++i];
    else if (a === "--project") args.project = argv[++i];
    else if (a === "--apply") args.apply = true;
    else if (["--disable", "--enable", "--check", "--check-all"].includes(a)) modes.push(a.slice(2));
    else throw new Error(`Argumento desconhecido: ${a}`);
  }
  if (!args.project) throw new Error("Informe --project (ex.: rdvperformanceapp).");
  if (modes.length !== 1) throw new Error("Informe exatamente um: --disable, --enable, --check ou --check-all.");
  args.mode = modes[0];
  if (args.mode !== "check-all" && (!args.uid || !/^[A-Za-z0-9]{10,128}$/.test(args.uid))) {
    throw new Error("Informe --uid válido.");
  }
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error("Defina GOOGLE_APPLICATION_CREDENTIALS com o caminho da chave da conta de serviço.");
  }
  return args;
}

const firestoreActive = (data) => !(data && data.active === false); // ausente/null = ativa

async function readState(auth, db, uid) {
  const user = await auth.getUser(uid); // erro se o UID não existir
  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  const data = snap.exists ? snap.data() : null;
  return {
    user,
    ref,
    exists: snap.exists,
    userType: data ? data.userType : undefined,
    active: data ? data.active : undefined,
    isAdmin: (data && data.userType === "ADMIN") || (user.customClaims || {}).admin === true,
  };
}

function printState(label, s) {
  const fsActive = s.exists ? firestoreActive({ active: s.active }) : null;
  const authActive = !s.user.disabled;
  console.log(`\n[${label}]`);
  console.log(`  uid ..................: ${s.user.uid}`);
  console.log(`  users/{uid} existe ...: ${s.exists}`);
  console.log(`  userType .............: ${s.userType === undefined ? "(ausente)" : s.userType}`);
  console.log(`  Firestore active .....: ${s.active === undefined ? "(ausente = ativa)" : JSON.stringify(s.active)}`);
  console.log(`  Auth disabled ........: ${s.user.disabled}`);
  console.log(`  Situação .............: ${fsActive === null ? "SEM PERFIL" : fsActive && authActive ? "ATIVA" : !fsActive && !authActive ? "INATIVA (Auth + Firestore)" : "INCONSISTENTE"}`);
}

async function checkAll(auth, db) {
  const fsUsers = new Map();
  const snap = await db.collection("users").select("active", "userType").get();
  snap.forEach((d) => fsUsers.set(d.id, d.data()));

  let pageToken;
  let total = 0;
  const issues = [];
  do {
    const page = await auth.listUsers(1000, pageToken);
    for (const u of page.users) {
      total++;
      const data = fsUsers.get(u.uid);
      if (!data) {
        issues.push(`${u.uid}: conta no Auth sem users/{uid}`);
        continue;
      }
      const fsActive = firestoreActive(data);
      if (fsActive === u.disabled) {
        issues.push(`${u.uid}: Firestore ${fsActive ? "ativa" : "inativa"} x Auth ${u.disabled ? "desativada" : "ativa"}`);
      }
      fsUsers.delete(u.uid);
    }
    pageToken = page.pageToken;
  } while (pageToken);
  for (const uid of fsUsers.keys()) issues.push(`${uid}: users/{uid} sem conta no Auth`);

  console.log(`Contas no Auth: ${total}`);
  console.log(issues.length ? `Inconsistências (${issues.length}):\n  ${issues.join("\n  ")}` : "Nenhuma inconsistência.");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: args.project });
  const auth = admin.auth();
  const db = admin.firestore();

  if (args.mode === "check-all") return checkAll(auth, db);

  const before = await readState(auth, db, args.uid);
  printState("estado atual", before);
  if (args.mode === "check") return;

  if (before.isAdmin) throw new Error("Conta administrativa: operação recusada.");
  if (!before.exists) throw new Error("users/{uid} não existe: operação recusada (o script não cria perfis).");

  const disable = args.mode === "disable";
  console.log(`\nPlano: ${disable
    ? "Auth disabled=true, revogar refresh tokens, Firestore active=false"
    : "Auth disabled=false, Firestore active=true"}.`);

  if (!args.apply) {
    console.log("\nDry-run: nada foi alterado. Repita com --apply para aplicar.");
    return;
  }

  const statusUpdate = {
    active: !disable,
    activeUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    activeUpdatedBy: "admin-tools",
  };

  if (disable) {
    // Firestore primeiro: as regras passam a negar acesso imediatamente
    await before.ref.update(statusUpdate);
    await auth.updateUser(args.uid, { disabled: true });
    await auth.revokeRefreshTokens(args.uid); // ID tokens já emitidos expiram em até 1 hora
  } else {
    await auth.updateUser(args.uid, { disabled: false });
    await before.ref.update(statusUpdate);
  }

  printState("estado final", await readState(auth, db, args.uid));
}

main().catch((err) => {
  console.error(`\nERRO: ${err.message}`);
  process.exit(1);
});

