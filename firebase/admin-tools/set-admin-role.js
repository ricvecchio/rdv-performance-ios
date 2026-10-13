#!/usr/bin/env node
// =============================================================================
// RDV Performance — Atribuição/revogação MANUAL do perfil ADMIN
// =============================================================================
//
// Executar SOMENTE em ambiente confiável (computador do responsável pelo projeto).
// Este script NÃO faz parte do app iOS e NÃO é publicado em lugar algum.
//
// O que faz (para um UID existente; nunca cria nem exclui contas):
//   --grant  : custom claim { admin: true } (preservando outras claims)
//              + users/{uid}.userType = "ADMIN" (demais campos preservados)
//   --revoke : users/{uid}.userType = <--to STUDENT|TRAINER>
//              + remove a claim "admin" (preservando outras claims)
//
// Sem --apply, apenas mostra o estado atual e o que seria feito (dry-run).
//
// Credenciais: chave de conta de serviço do Firebase Admin SDK, informada por
// GOOGLE_APPLICATION_CREDENTIALS. Guarde a chave FORA do repositório e apague-a
// após o uso. Nunca adicione a chave ao app iOS nem ao Git.
//
// Uso:
//   cd firebase/admin-tools && npm install
//   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/Downloads/<chave>.json"
//   node set-admin-role.js --project rdvperformanceapp --uid <UID> --grant            # dry-run
//   node set-admin-role.js --project rdvperformanceapp --uid <UID> --grant --apply    # aplica
//   node set-admin-role.js --project rdvperformanceapp --uid <UID> --revoke --to STUDENT --apply
// =============================================================================

"use strict";

const admin = require("firebase-admin");

const ADMIN_CLAIM = "admin";
const ADMIN_TYPE = "ADMIN";
const REVOKE_TARGETS = new Set(["STUDENT", "TRAINER"]);

function parseArgs(argv) {
  const args = { apply: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--uid") args.uid = argv[++i];
    else if (a === "--project") args.project = argv[++i];
    else if (a === "--to") args.to = argv[++i];
    else if (a === "--grant") args.mode = args.mode ? "conflict" : "grant";
    else if (a === "--revoke") args.mode = args.mode ? "conflict" : "revoke";
    else if (a === "--apply") args.apply = true;
    else throw new Error(`Argumento desconhecido: ${a}`);
  }
  if (!args.project) throw new Error("Informe --project (ex.: rdvperformanceapp).");
  if (!args.uid || !/^[A-Za-z0-9]{10,128}$/.test(args.uid)) throw new Error("Informe --uid válido.");
  if (args.mode !== "grant" && args.mode !== "revoke") throw new Error("Informe exatamente um: --grant ou --revoke.");
  if (args.mode === "revoke" && !REVOKE_TARGETS.has(args.to || "")) {
    throw new Error("Na revogação, informe --to STUDENT ou --to TRAINER.");
  }
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error("Defina GOOGLE_APPLICATION_CREDENTIALS com o caminho da chave da conta de serviço.");
  }
  return args;
}

function maskEmail(email) {
  if (!email) return "(sem e-mail)";
  const [user, domain] = email.split("@");
  return `${user.slice(0, 2)}***@${domain || ""}`;
}

async function readState(auth, db, uid) {
  const user = await auth.getUser(uid); // lança erro se o UID não existir (nenhuma conta é criada)
  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  return {
    user,
    ref,
    exists: snap.exists,
    userType: snap.exists ? snap.get("userType") : undefined,
    fieldCount: snap.exists ? Object.keys(snap.data() || {}).length : 0,
    claims: user.customClaims || {},
  };
}

function printState(label, s) {
  console.log(`\n[${label}]`);
  console.log(`  uid ................: ${s.user.uid}`);
  console.log(`  e-mail (mascarado) .: ${maskEmail(s.user.email)}`);
  console.log(`  users/{uid} existe .: ${s.exists}`);
  console.log(`  userType ...........: ${s.userType === undefined ? "(ausente)" : s.userType}`);
  console.log(`  campos no perfil ...: ${s.fieldCount}`);
  console.log(`  custom claims ......: ${JSON.stringify(s.claims)}`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: args.project });
  const auth = admin.auth();
  const db = admin.firestore();

  const before = await readState(auth, db, args.uid);
  printState("estado atual", before);

  if (!before.exists) {
    throw new Error("users/{uid} não existe. Nada foi alterado (o script não cria perfis).");
  }

  const otherClaims = Object.assign({}, before.claims);
  delete otherClaims[ADMIN_CLAIM];

  if (args.mode === "grant") {
    console.log(`\nPlano: claim ${ADMIN_CLAIM}=true e userType "${before.userType}" -> "${ADMIN_TYPE}".`);
  } else {
    console.log(`\nPlano: userType "${before.userType}" -> "${args.to}" e remoção da claim ${ADMIN_CLAIM}.`);
  }

  if (!args.apply) {
    console.log("\nDry-run: nada foi alterado. Repita com --apply para aplicar.");
    return;
  }

  if (args.mode === "grant") {
    // 1) claim (sozinha não concede acesso: regras e app exigem também userType ADMIN)
    await auth.setCustomUserClaims(args.uid, Object.assign({}, otherClaims, { [ADMIN_CLAIM]: true }));
    // 2) perfil: update() altera somente os campos indicados e falha se o documento não existir
    await before.ref.update({ userType: ADMIN_TYPE, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
  } else {
    // 1) perfil primeiro: a revogação passa a valer imediatamente nas regras e no app
    await before.ref.update({ userType: args.to, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    // 2) claim
    await auth.setCustomUserClaims(args.uid, Object.keys(otherClaims).length ? otherClaims : null);
  }

  const after = await readState(auth, db, args.uid);
  printState("estado final", after);
  console.log("\nConcluído. O usuário deve sair e entrar novamente no app para renovar o token.");
}

main().catch((err) => {
  console.error(`\nERRO: ${err.message}`);
  process.exit(1);
});

