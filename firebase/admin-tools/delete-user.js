#!/usr/bin/env node
// =============================================================================
// RDV Performance — Exclusão DEFINITIVA de conta (MANUAL, Firebase Admin SDK)
// =============================================================================
//
// Executar SOMENTE em ambiente confiável. Não faz parte do app iOS.
// No plano Spark não há backend (Cloud Functions exige Blaze); por isso a exclusão
// definitiva é feita por esta ferramenta, e não pelo aplicativo.
//
// Política de dados (ver firebase/ADMIN_USER_MANAGEMENT.md, seção 4):
//   EXCLUÍDOS (pertencem ao usuário excluído):
//     - users/{uid} e todas as subcoleções (recordes, notification_state, vídeos...)
//     - teachers/{uid} e subcoleções (treinos importados do professor)
//     - workout_templates com teacherId == uid (biblioteca do professor)
//     - vínculos: teacher_students, teacher_student_relations, teacher_student_link_requests
//       e teacher_student_invites em que o usuário é teacherId/studentId (ou studentEmail)
//     - SE ALUNO: training_weeks com studentId == uid (com days e student_progress),
//       teacher_messages e student_feedbacks com studentId == uid
//   MANTIDOS (pertencem também a outros usuários / auditoria):
//     - SE PROFESSOR: training_weeks, teacher_messages e student_feedbacks com teacherId == uid
//       (são dados dos alunos; o teacherId fica como referência histórica)
//     - teacher_signup_redemptions/{uid} (auditoria do código usado; sem dados pessoais)
//
// Ordem (cada etapa é idempotente; reexecutar continua de onde parou):
//   1. bloqueio: Firestore active=false, Auth disabled=true, revogação de tokens
//   2. dados relacionados (consultas acima)
//   3. users/{uid} (recursivo)
//   4. conta no Firebase Authentication (por último)
// O andamento fica em admin_account_deletions/{uid} (sem acesso de clientes: regra padrão nega).
//
// Contas ADMIN (userType ADMIN ou claim admin) são recusadas.
//
// Uso:
//   cd firebase/admin-tools && npm install
//   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/Downloads/<chave>.json"
//   node delete-user.js --project rdvperformanceapp --uid <UID>                          # inventário (dry-run)
//   node delete-user.js --project rdvperformanceapp --uid <UID> --apply --confirm <UID>  # executa
// =============================================================================

"use strict";

const admin = require("firebase-admin");

function parseArgs(argv) {
  const args = { apply: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--uid") args.uid = argv[++i];
    else if (a === "--project") args.project = argv[++i];
    else if (a === "--confirm") args.confirm = argv[++i];
    else if (a === "--apply") args.apply = true;
    else throw new Error(`Argumento desconhecido: ${a}`);
  }
  if (!args.project) throw new Error("Informe --project (ex.: rdvperformanceapp).");
  if (!args.uid || !/^[A-Za-z0-9]{10,128}$/.test(args.uid)) throw new Error("Informe --uid válido.");
  if (args.apply && args.confirm !== args.uid) {
    throw new Error("Para executar, repita o UID em --confirm <UID> (proteção contra exclusão acidental).");
  }
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error("Defina GOOGLE_APPLICATION_CREDENTIALS com o caminho da chave da conta de serviço.");
  }
  return args;
}

const TRAINER_TYPES = new Set(["TRAINER", "PROFESSOR", "TEACHER"]);
const STUDENT_TYPES = new Set(["STUDENT", "ALUNO"]);

async function main() {
  const args = parseArgs(process.argv.slice(2));
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: args.project });
  const auth = admin.auth();
  const db = admin.firestore();
  const { uid } = args;

  const jobRef = db.collection("admin_account_deletions").doc(uid);
  const job = (await jobRef.get()).data() || null;

  // ---- Estado atual (Auth pode já ter sido removido em execução anterior concluída)
  let authUser = null;
  try {
    authUser = await auth.getUser(uid);
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
  }
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  const profile = userSnap.exists ? userSnap.data() : null;

  const userType = String((profile && profile.userType) || (job && job.userType) || "").trim().toUpperCase();
  const email = String((profile && profile.email) || (authUser && authUser.email) || (job && job.pendingEmail) || "")
    .trim().toLowerCase();

  if (userType === "ADMIN" || (authUser && (authUser.customClaims || {}).admin === true)) {
    throw new Error("Conta administrativa: exclusão recusada.");
  }
  if (!authUser && !profile && !job) {
    throw new Error("UID não encontrado no Auth nem em users/{uid}. Nada a fazer.");
  }

  const isTrainer = TRAINER_TYPES.has(userType);
  const isStudent = STUDENT_TYPES.has(userType) || (!isTrainer && userType !== "");

  console.log(`UID: ${uid}`);
  console.log(`Tipo: ${userType || "(desconhecido)"} | Auth: ${authUser ? (authUser.disabled ? "existe (desativada)" : "existe (ativa)") : "inexistente"} | users/{uid}: ${profile ? "existe" : "inexistente"}`);
  if (job) console.log(`Execução anterior encontrada: status=${job.status}, etapas concluídas=${Object.keys(job.steps || {}).join(", ") || "nenhuma"}`);
  if (!userType) console.log("AVISO: tipo desconhecido; dados compartilhados de treinos/mensagens/feedbacks serão MANTIDOS.");

  // ---- Inventário de dados relacionados
  const q = (col, field, value) => db.collection(col).where(field, "==", value);
  const related = [
    ["teacher_students (teacherId)", q("teacher_students", "teacherId", uid)],
    ["teacher_students (studentId)", q("teacher_students", "studentId", uid)],
    ["teacher_student_relations (teacherId)", q("teacher_student_relations", "teacherId", uid)],
    ["teacher_student_relations (studentId)", q("teacher_student_relations", "studentId", uid)],
    ["teacher_student_link_requests (teacherId)", q("teacher_student_link_requests", "teacherId", uid)],
    ["teacher_student_link_requests (studentId)", q("teacher_student_link_requests", "studentId", uid)],
    ["teacher_student_invites (teacherId)", q("teacher_student_invites", "teacherId", uid)],
    ["teacher_student_invites (studentId)", q("teacher_student_invites", "studentId", uid)],
    ["workout_templates (teacherId)", q("workout_templates", "teacherId", uid)],
  ];
  if (email) related.push(["teacher_student_invites (studentEmail)", q("teacher_student_invites", "studentEmail", email)]);
  if (isStudent) {
    related.push(
      ["training_weeks (studentId) + days/student_progress", q("training_weeks", "studentId", uid)],
      ["teacher_messages (studentId)", q("teacher_messages", "studentId", uid)],
      ["student_feedbacks (studentId)", q("student_feedbacks", "studentId", uid)]
    );
  }

  const kept = isTrainer
    ? [
        ["MANTIDOS training_weeks (teacherId)", q("training_weeks", "teacherId", uid)],
        ["MANTIDOS teacher_messages (teacherId)", q("teacher_messages", "teacherId", uid)],
        ["MANTIDOS student_feedbacks (teacherId)", q("student_feedbacks", "teacherId", uid)],
      ]
    : [];

  console.log("\nInventário:");
  const plan = [];
  for (const [label, query] of related) {
    const snap = await query.get();
    console.log(`  excluir  ${label}: ${snap.size}`);
    plan.push([label, snap.docs.map((d) => d.ref)]);
  }
  for (const [label, query] of kept) {
    const c = (await query.count().get()).data().count;
    console.log(`  ${label}: ${c}`);
  }
  const teachersRef = db.collection("teachers").doc(uid);
  const teacherSubs = await teachersRef.listCollections();
  console.log(`  excluir  teachers/{uid} (subcoleções: ${teacherSubs.map((c) => c.id).join(", ") || "nenhuma"})`);
  const userSubs = profile ? await userRef.listCollections() : [];
  console.log(`  excluir  users/{uid} (subcoleções: ${userSubs.map((c) => c.id).join(", ") || "nenhuma"})`);
  console.log(`  excluir  conta no Firebase Authentication: ${authUser ? "sim" : "já inexistente"}`);
  console.log("  manter   teacher_signup_redemptions/{uid} (auditoria)");

  if (!args.apply) {
    console.log("\nDry-run: nada foi alterado. Para executar: --apply --confirm <UID>.");
    return;
  }

  // ---- Execução
  const markStep = async (step, extra = {}) =>
    jobRef.set(
      {
        status: "in_progress",
        userType: userType || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        steps: { [step]: Object.assign({ doneAt: admin.firestore.FieldValue.serverTimestamp() }, extra) },
      },
      { merge: true }
    );

  await jobRef.set(
    {
      status: "in_progress",
      userType: userType || null,
      pendingEmail: email || null, // removido ao concluir
      startedAt: (job && job.startedAt) || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  // 1. Bloqueio
  if (profile) {
    await userRef.update({
      active: false,
      activeUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      activeUpdatedBy: "admin-tools",
    });
  }
  if (authUser) {
    await auth.updateUser(uid, { disabled: true });
    await auth.revokeRefreshTokens(uid);
  }
  await markStep("block");
  console.log("\n1. Conta bloqueada.");

  // 2. Dados relacionados
  for (const [label, refs] of plan) {
    for (const ref of refs) {
      await db.recursiveDelete(ref); // inclui subcoleções (ex.: days, student_progress)
    }
    console.log(`2. ${label}: ${refs.length} removido(s).`);
  }
  await db.recursiveDelete(teachersRef);
  await markStep("related_data");

  // 3. Perfil
  await db.recursiveDelete(userRef);
  await markStep("profile");
  console.log("3. users/{uid} removido.");

  // 4. Authentication (por último)
  if (authUser) {
    await auth.deleteUser(uid);
  }
  await markStep("auth");
  console.log("4. Conta removida do Firebase Authentication.");

  await jobRef.set(
    {
      status: "completed",
      pendingEmail: admin.firestore.FieldValue.delete(),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  console.log("\nExclusão concluída.");
}

main().catch((err) => {
  console.error(`\nERRO: ${err.message}`);
  console.error("Nenhuma etapa posterior foi executada. Corrija a causa e execute novamente o mesmo comando (as etapas são idempotentes).");
  process.exit(1);
});

