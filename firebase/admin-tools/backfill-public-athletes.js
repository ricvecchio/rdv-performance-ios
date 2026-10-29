#!/usr/bin/env node
// =============================================================================
// RDV Performance — Backfill de publicAthletes (recurso Atletas) — MANUAL
// =============================================================================
//
// Executar SOMENTE em ambiente confiável. Não faz parte do app iOS.
//
// Cria publicAthletes/{uid} para usuários ATIVOS já cadastrados (exceto ADMIN) que ainda não
// possuem o documento, para que apareçam na busca de Atletas antes de abrirem a nova versão.
// Também inicializa/corrige o campo prCount (movimentos/provas com resultado válido, sem duplicar
// histórico) calculado a partir de users/{uid}/student_personal_records (SOMENTE LEITURA).
//
// Segurança / compatibilidade:
//   - NÃO altera, move ou apaga nada em users/*.
//   - Documentos publicAthletes existentes recebem APENAS o campo prCount (e somente se diferente);
//     privacy, nome, foto etc. são preservados.
//   - Perfis criados são PRIVADOS (privacy = "private") com prCount calculado.
//   - Se os PRs de um usuário estiverem inconsistentes/incompletos, o prCount dele não é alterado
//     (novos perfis nascem com 0) e o fato é listado ao final.
//   - Não copia e-mail, telefone ou dados administrativos; a foto é omitida (o app gera a
//     miniatura quando o próprio usuário abre a nova versão).
//   - Sem --apply, apenas mostra o plano (dry-run).
//
// Uso:
//   cd firebase/admin-tools && npm install
//   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/Downloads/<chave>.json"
//   node backfill-public-athletes.js --project rdvperformanceapp            # dry-run
//   node backfill-public-athletes.js --project rdvperformanceapp --apply    # grava
// =============================================================================

"use strict";

const admin = require("firebase-admin");
const { computePrCount } = require("../../functions/prCount");

function parseArgs(argv) {
  const args = { apply: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--project") args.project = argv[++i];
    else if (a === "--apply") args.apply = true;
    else throw new Error(`Argumento desconhecido: ${a}`);
  }
  if (!args.project) throw new Error("Informe --project (ex.: rdvperformanceapp).");
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error("Defina GOOGLE_APPLICATION_CREDENTIALS com o caminho da chave da conta de serviço.");
  }
  return args;
}

function normalize(text) {
  return String(text || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

// Mesma lógica do app (AthleteSearchText.prefixes): prefixos de até 20 caracteres de cada palavra.
function prefixes(name) {
  const result = [];
  const seen = new Set();
  for (const word of normalize(name).split(/\s+/).filter(Boolean)) {
    let current = "";
    for (const ch of Array.from(word).slice(0, 20)) {
      current += ch;
      if (!seen.has(current)) {
        seen.add(current);
        result.push(current);
      }
      if (result.length >= 150) return result;
    }
  }
  return result;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  admin.initializeApp({ projectId: args.project });
  const db = admin.firestore();

  const users = await db.collection("users").get();
  let eligible = 0;
  let existing = 0;
  let created = 0;
  let countUpdates = 0;
  const incomplete = [];
  let batch = db.batch();
  let pending = 0;

  const flush = async () => {
    if (args.apply && pending > 0) await batch.commit();
    batch = db.batch();
    pending = 0;
  };

  for (const doc of users.docs) {
    const data = doc.data();
    const name = String(data.name || "").trim();
    if (data.active === false) continue;
    if (String(data.userType || "").toUpperCase() === "ADMIN") continue;
    if (!name) continue;
    eligible++;

    // Somente leitura em users/{uid}/student_personal_records.
    const { count, complete } = await computePrCount(db, (refs) => db.getAll(...refs), doc.id);
    if (!complete) incomplete.push(doc.id);

    const ref = db.collection("publicAthletes").doc(doc.id);
    const snapshot = await ref.get();

    if (snapshot.exists) {
      existing++;
      // Atualiza somente prCount (preserva privacy, nome, foto etc.).
      if (complete && snapshot.get("prCount") !== count) {
        countUpdates++;
        if (args.apply) {
          batch.update(ref, { prCount: count });
          if (++pending >= 400) await flush();
        }
      }
      continue;
    }

    created++;
    if (!args.apply) continue;

    batch.create(ref, {
      ownerId: doc.id,
      name,
      nameLower: normalize(name),
      searchPrefixes: prefixes(name),
      photoThumbBase64: "",
      privacy: "private",
      prCount: complete ? count : 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    if (++pending >= 400) await flush();
  }

  await flush();

  console.log(`Usuários elegíveis: ${eligible}`);
  console.log(`Já possuíam publicAthletes: ${existing}`);
  console.log(`${args.apply ? "Criados" : "A criar (dry-run)"}: ${created}`);
  console.log(`${args.apply ? "prCount atualizado" : "prCount a atualizar (dry-run)"} em existentes: ${countUpdates}`);
  if (incomplete.length) {
    console.log(`PRs inconsistentes/incompletos (prCount não alterado): ${incomplete.length}`);
    incomplete.forEach((uid) => console.log(`  - ${uid}`));
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
