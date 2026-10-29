/**
 * Cálculo do `prCount` (publicAthletes/{uid}) a partir dos Personal Records.
 *
 * Fonte (somente leitura): users/{uid}/student_personal_records — estrutura inalterada:
 *   - _metadata_v2          : tombstones de itens personalizados removidos
 *   - <payloadKey>          : cabeçalho do payload (inline `payload` ou `chunked`)
 *   - chunk_v3_<key>_<gen>_<i> : partes do payload
 *   - v1                    : documento legado (payloads inline + tombstones)
 *
 * Regra: prCount = quantidade de movimentos/provas distintos com resultado válido
 * (Barbell: número finito > 0; demais: texto não vazio). Apenas os mapas "values" são
 * considerados (um item por chave), portanto o histórico nunca duplica a contagem.
 * Itens personalizados removidos (tombstones) são ignorados, como no app.
 *
 * Mantenha sincronizado com AthleteRecordsSummary.swift / PersonalRecordsRepository.swift.
 * Módulo sem dependências: usado pela Cloud Function e pelo script administrativo de backfill.
 */

"use strict";

const COLLECTION = "student_personal_records";
const METADATA_ID = "_metadata_v2";
const LEGACY_ID = "v1";
const MAX_CHUNKS = 10000;

const CATEGORIES = [
  { key: "barbell", values: "student_pr_barbell_values_v1", custom: "student_pr_barbell_custom_moves_v1", numeric: true },
  { key: "gymnastic", values: "student_pr_gymnastic_values_v1", custom: "student_pr_gymnastic_custom_items_v1" },
  { key: "endurance", values: "student_pr_endurance_values_v1", custom: "student_pr_endurance_custom_items_v1" },
  { key: "notables", values: "student_pr_notables_values_v1", custom: "student_pr_notables_custom_items_v1" },
  { key: "girls", values: "student_pr_girls_values_v1", custom: "student_pr_girls_custom_items_v1" },
  { key: "open", values: "student_pr_open_values_v1", custom: "student_pr_open_custom_items_v1" },
  { key: "heroes", values: "student_pr_heroes_values_v1", custom: "student_pr_heroes_custom_items_v1" },
  { key: "campeonatos", values: "student_pr_campeonatos_values_v1", custom: "student_pr_campeonatos_custom_items_v1" },
  { key: "crossfit_games", values: "student_pr_crossfit_games_values_v1", custom: "student_pr_crossfit_games_custom_items_v1" },
];

const CHUNK_PREFIX = "chunk_v3_";

function isChunkDocumentId(documentId) {
  return typeof documentId === "string" && documentId.startsWith(CHUNK_PREFIX);
}

function chunkId(key, generation, index) {
  return `${CHUNK_PREFIX}${key}_${generation}_${index}`;
}

function isOwned(data, uid, versions) {
  return !!data && data.ownerId === uid && versions.includes(Number(data.schemaVersion));
}

function exactNonNegativeInt(value) {
  return typeof value === "number" && Number.isInteger(value) && value >= 0 ? value : null;
}

function parseValues(buffer, numeric) {
  let parsed;
  try {
    parsed = JSON.parse(Buffer.from(buffer).toString("utf8"));
  } catch (_) {
    return new Set();
  }
  const valid = new Set();
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return valid;
  for (const [key, value] of Object.entries(parsed)) {
    if (numeric) {
      if (typeof value === "number" && Number.isFinite(value) && value > 0) valid.add(key);
    } else if (typeof value === "string" && value.trim() !== "") {
      valid.add(key);
    }
  }
  return valid;
}

function tombstoneSet(data, customKey) {
  const raw = data && data.customTombstones && data.customTombstones[customKey];
  return new Set(Array.isArray(raw) ? raw.filter((item) => typeof item === "string") : []);
}

/**
 * @param {(refs: FirebaseFirestore.DocumentReference[]) => Promise<FirebaseFirestore.DocumentSnapshot[]>} getAll
 *        leitura em lote (db.getAll ou tx.getAll).
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 * @returns {Promise<{count: number, complete: boolean}>}
 *          complete=false quando algum payload está inconsistente/incompleto (ex.: gravação em andamento);
 *          nesse caso o valor NÃO deve ser gravado.
 */
async function computePrCount(db, getAll, uid) {
  const records = db.collection("users").doc(uid).collection(COLLECTION);
  const headerRefs = [
    records.doc(METADATA_ID),
    records.doc(LEGACY_ID),
    ...CATEGORIES.map((c) => records.doc(c.values)),
  ];
  const headerSnaps = await getAll(headerRefs);
  const metadataSnap = headerSnaps[0];
  const legacySnap = headerSnaps[1];
  const valueSnaps = headerSnaps.slice(2);

  const metadata =
    metadataSnap.exists && isOwned(metadataSnap.data(), uid, [2, 3]) && metadataSnap.get("documentType") === "metadata"
      ? metadataSnap.data()
      : null;
  const legacy = legacySnap.exists && isOwned(legacySnap.data(), uid, [1]) ? legacySnap.data() : null;
  const legacyBlobs = (legacy && legacy.payloads) || {};

  // Planeja a leitura dos chunks dos payloads particionados.
  const plans = CATEGORIES.map((category, index) => {
    const snap = valueSnaps[index];
    const data = snap.exists ? snap.data() : null;
    if (!isOwned(data, uid, [2, 3]) || data.documentType !== "payload" || data.payloadKey !== category.values) {
      return { inline: null, chunks: null, invalid: snap.exists };
    }
    if (data.payload && typeof data.payload.length === "number" && !(typeof data.payload === "string")) {
      return { inline: data.payload, chunks: null, invalid: false };
    }
    const count = exactNonNegativeInt(data.chunkCount);
    if (
      data.payloadFormat !== "chunked" ||
      typeof data.payloadGeneration !== "string" ||
      !data.payloadGeneration ||
      count === null ||
      count > MAX_CHUNKS
    ) {
      return { inline: null, chunks: null, invalid: true };
    }
    return { inline: null, chunks: { generation: data.payloadGeneration, count }, invalid: false };
  });

  const chunkRefs = [];
  plans.forEach((plan, index) => {
    if (!plan.chunks) return;
    for (let i = 0; i < plan.chunks.count; i += 1) {
      chunkRefs.push({ index, i, ref: records.doc(chunkId(CATEGORIES[index].values, plan.chunks.generation, i)) });
    }
  });
  const chunkSnaps = chunkRefs.length ? await getAll(chunkRefs.map((item) => item.ref)) : [];
  const chunkBuffers = new Map(); // categoryIndex -> Buffer[]
  let complete = true;

  chunkSnaps.forEach((snap, position) => {
    const { index, i } = chunkRefs[position];
    const category = CATEGORIES[index];
    const data = snap.exists ? snap.data() : null;
    if (
      !isOwned(data, uid, [3]) ||
      data.documentType !== "payloadChunk" ||
      data.payloadKey !== category.values ||
      data.payloadGeneration !== plans[index].chunks.generation ||
      data.chunkIndex !== i ||
      !data.payload
    ) {
      complete = false;
      return;
    }
    if (!chunkBuffers.has(index)) chunkBuffers.set(index, []);
    chunkBuffers.get(index)[i] = Buffer.from(data.payload);
  });

  let count = 0;

  CATEGORIES.forEach((category, index) => {
    const plan = plans[index];
    const valid = new Set();

    if (plan.invalid) complete = false;

    let partitioned = null;
    if (plan.inline) {
      partitioned = plan.inline;
    } else if (plan.chunks) {
      if (plan.chunks.count === 0) {
        partitioned = Buffer.alloc(0);
      } else {
        const parts = chunkBuffers.get(index);
        if (parts && parts.length === plan.chunks.count && parts.every(Boolean)) {
          partitioned = Buffer.concat(parts);
        } else {
          complete = false;
        }
      }
    }

    if (partitioned && partitioned.length) {
      parseValues(partitioned, !!category.numeric).forEach((key) => valid.add(key));
    }
    const legacyBlob = legacyBlobs[category.values];
    if (legacyBlob && legacyBlob.length) {
      parseValues(legacyBlob, !!category.numeric).forEach((key) => valid.add(key));
    }

    const removed = new Set([...tombstoneSet(metadata, category.custom), ...tombstoneSet(legacy, category.custom)]);
    for (const key of valid) {
      if (!removed.has(key)) count += 1;
    }
  });

  return { count, complete };
}

module.exports = { computePrCount, isChunkDocumentId, COLLECTION };

