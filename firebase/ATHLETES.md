# Atletas — Firestore, privacidade e compatibilidade

Funcionalidade: busca de atletas, favoritos, privacidade do perfil e consulta (somente leitura) de PRs de perfis públicos.

## Estrutura do Firestore (tudo novo e aditivo; `users/*` não é alterado)

| Caminho | Conteúdo | Quem escreve |
| --- | --- | --- |
| `publicAthletes/{uid}` | `ownerId`, `name`, `nameLower`, `searchPrefixes[]`, `photoThumbBase64` (96 px), `privacy` (`public`/`private`), `prCount` (**somente backend**), `updatedAt` | Dono (exceto `prCount`) |
| `publicAthletes/{uid}/records/{categoria}` | Cópia resumida dos PRs com resultado válido (`items[]`: `key`, `name`, `value`, `unit`) | Somente o dono |
| `users/{uid}/favoriteAthletes/{athleteId}` | `athleteId`, `createdAt` (ID do documento = ID do atleta, sem duplicidade) | Somente o dono |

Categorias: `barbell`, `gymnastic`, `endurance`, `notables`, `girls`, `open`, `heroes`, `campeonatos`, `crossfit_games`.

## Privacidade

- Valor padrão: **privado** (documento ou campo ausente = privado).
- A privacidade fica em `publicAthletes/{uid}.privacy` e é a fonte única consultada pelas regras.
- `records` só pode ser lido por terceiros quando `athleteIsPublic(uid)` for verdadeiro **no servidor**
  (não depende de cache do app). Ao tornar o perfil privado, o app grava primeiro `privacy = private`
  (leitura negada imediatamente) e depois apaga a cópia dos recordes.
- Perfil privado expõe apenas: foto reduzida, nome, privacidade e `prCount`.
- Nada de e-mail, telefone, check-ins, dados administrativos ou de assinatura é copiado.

## Como os dados são criados

- Login (`AppSession.loadUserProfile`): `AthletesService.ensurePublicProfile` cria/atualiza `publicAthletes/{uid}`
  (novos como **privados**, `prCount = 0`). Preserva `privacy` e `prCount` existentes. Contas inativas e ADMIN não são publicadas.
- Sincronização de PRs (`PersonalRecordsSyncService.completeSynchronization`): `AthletesService.publishRecords`
  atualiza, se o perfil for público, `records/*` (não grava mais `prCount`).
- `prCount` é mantido pela Cloud Function `syncPublicAthletePrCount` (`functions/index.js`, cálculo em `functions/prCount.js`),
  disparada por qualquer escrita em `users/{uid}/student_personal_records/*` (inclusão, alteração ou exclusão).
  Somente lê os PRs; grava apenas `publicAthletes/{uid}.prCount`. As regras impedem o cliente de alterá-lo
  (criação exige `0`; atualização exige o valor atual). Visível para perfis públicos e privados; `records/*` segue restrito ao dono/público.
- `prCount` = quantidade de movimentos/provas com resultado válido (Barbell: número > 0; demais: texto não vazio).
  Atualizações históricas do mesmo movimento não são contadas em duplicidade.
- Deploy: `firebase deploy --only functions:syncPublicAthletePrCount` (a região do trigger deve coincidir com a do Firestore;
  parâmetro `FIRESTORE_TRIGGER_REGION`, padrão `us-central1`). Publique as regras e rode o backfill **depois**/em conjunto.

## Compatibilidade com usuários antigos

1. Quem abrir a nova versão passa a ter `publicAthletes/{uid}` automaticamente.
2. Para que usuários que ainda não abriram o app apareçam na busca, execute (uma vez, ambiente confiável):

```
cd firebase/admin-tools && npm install
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/Downloads/<chave>.json"
node backfill-public-athletes.js --project rdvperformanceapp            # dry-run
node backfill-public-athletes.js --project rdvperformanceapp --apply
```

O script cria documentos ausentes (sempre **privados**, sem foto) e, nos existentes, atualiza **somente** `prCount`
(calculado em modo leitura a partir dos PRs). Nunca altera `users/*`.

## Regras do Firestore (aplicação manual)

Alterações **aditivas** na seção "5.1 ATLETAS" de `firebase/firestore-production-proposed.rules`
(`publicAthletes`, `publicAthletes/{uid}/records`, `users/{uid}/favoriteAthletes`).
Compare com as regras vigentes antes de publicar no Console. Nenhuma permissão existente foi alterada.

## Índices

Nenhum índice composto é necessário (busca com `array-contains` em `searchPrefixes` + `limit`).

## Limitações conhecidas

- Busca por início de **qualquer palavra** do nome (até 20 caracteres por palavra), sem acentos/maiúsculas; não encontra trechos no meio de uma palavra.
- Movimentos nativos são identificados só pela chave interna e exibidos com nome derivado dela (ex.: `back_squat` → "Back Squat"); itens criados pelo usuário usam o nome real.
- O histórico de PRs não é compartilhado (somente o recorde atual de cada movimento).
- `prCount` é atualizado pelo backend em segundos após a escrita dos PRs (eventual); perfis sem `publicAthletes/{uid}` são ignorados pela função até serem criados.
- Valores do Barbell são gravados em kg e exibidos na unidade preferida de quem visualiza.
- **Preexistente (não alterado):** a regra atual `allow list: if isSignedIn()` em `users/{userId}` já permite que qualquer usuário autenticado
  liste documentos de `users` (que contêm e-mail, telefone e foto). O recurso Atletas **não depende** dessa regra; recomenda-se
  restringi-la em uma etapa própria, avaliando o impacto em professores/administradores.
- Contas ADMIN não são publicadas no login; ao escolher a privacidade (tela Privacidade), o app cria o `publicAthletes/{uid}` ausente
  a partir de `users/{uid}` (leitura do próprio dono, sem alterá-lo), sempre preservando `prCount`.
- **Diagnóstico:** em DEBUG, o app registra no console `operação / coleção / código` do erro Firestore (7 = `permission-denied`,
  9 = `failed-precondition`/índice, 14 = `unavailable`), sem dados pessoais. `permission-denied` em `publicAthletes` ou
  `favoriteAthletes` indica que as regras publicadas **não** contêm a seção 5.1: publique o arquivo completo no Console.

- Versões antigas do app que tentarem gravar `prCount` terão a escrita negada pelas regras novas (publicação de `records/*`
  por elas pode falhar até atualizarem o app).
