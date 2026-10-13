# Autorização administrativa para cadastro de Professores

Este documento descreve o mecanismo de código de autorização exigido para criar contas
do tipo **Professor (TRAINER)** no RDV Performance e as etapas **manuais** de implantação.

> Nenhum deploy é feito automaticamente. Até que as regras do Firestore estejam mescladas e
> publicadas, o fluxo **não funciona** e a proteção **não** deve ser considerada ativa.

---

## 0. Histórico — por que a implementação mudou

A versão anterior dependia de quatro Cloud Functions (`getTeacherSignupCode`, `rotateTeacherSignupCode`,
`validateTeacherSignupCode`, `createTeacherAccount`, código em `functions/index.js`).

Verificação feita em 2026-10-12:

- `firebase functions:list --project rdvperformanceapp` → **"No functions found"** (nenhuma região).
- `POST https://us-central1-rdvperformanceapp.cloudfunctions.net/<função>` → **HTTP 404** (página HTML do Google).
- O app convertia o 404 em `.functionUnavailable`, exibido com a mesma mensagem de
  `teacher_authorization.error.not_configured` ("O cadastro de professores ainda não está disponível...").

As funções nunca foram publicadas. Como Cloud Functions exigem o plano **Blaze**, o mecanismo foi
reimplementado com **Firebase Authentication + Cloud Firestore + regras de segurança**, compatível com
o plano **Spark**. O diretório `functions/` permanece no repositório, mas **não é usado pelo app**.

## 1. Visão geral do fluxo

```text
Administrador (AdminProfileSelectionView -> TeacherAuthorizationCodeView)
  ├─ Consultar  -> transação: lê teacher_signup_config/current (gera o inicial no 1º acesso)
  └─ Gerar novo -> transação: cria teacher_signup_codes/{novo}, remove o anterior,
                   atualiza config (version + 1)

Seleção de tipo de conta
  ├─ Aluno     -> cadastro inalterado
  └─ Professor -> modal "Código de autorização"
                   -> get teacher_signup_codes/{código} (servidor, sem cache)
                        ├─ inexistente -> "Código inválido", sem navegação
                        └─ existente   -> get teacher_signup_code_uses/{código} (servidor)
                             ├─ existente  -> "Código já utilizado", sem navegação
                             └─ inexistente -> código mantido apenas em memória
                                          -> RegisterTeacherView (campos inalterados)
                                               -> revalida código e consumo no servidor
                                               -> cria a conta no Firebase Auth
                                               -> transação (relê o consumo no servidor):
                                                    teacher_signup_code_uses/{código} {usedAt}
                                                    teacher_signup_redemptions/{uid} {code}
                                                    users/{uid} {userType: TRAINER, ...}
                                                  (aceita pelas regras SOMENTE com código vigente
                                                   e ainda não consumido)
                                               -> em falha: remove a conta do Auth
                                               -> login automático
```

## 2. Geração, armazenamento e validação

| Item | Detalhe |
|------|---------|
| Geração | No app do administrador, `SecRandomCopyBytes` (criptograficamente seguro). |
| Formato | `RDV-XXXX-XXXX-XXXX` — 12 caracteres do alfabeto `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (≈ 60 bits). |
| `teacher_signup_config/current` | `code`, `codeId`, `version`, `updatedAt`, `updatedBy`. Leitura/escrita **somente administrador**. |
| `teacher_signup_codes/{codeId}` | Um documento por código **vigente**. `get` público (só quem conhece o código obtém resposta); `list` bloqueado. |
| `teacher_signup_redemptions/{uid}` | Registro de qual código autorizou cada professor. Criado só junto com o perfil TRAINER; leitura somente administrador; imutável. |
| Validação | Leitura no servidor (`source: .server`). A proteção efetiva está na regra de criação de `users/{uid}` com `userType = TRAINER`. |
| Substituição | Transação: cria o novo código, remove o anterior e incrementa `version`. As regras exigem a remoção do anterior e versão sequencial (operações concorrentes são rejeitadas). |
| Persistência | O código fica no Firestore: continua o mesmo após fechar/reabrir o app até ser substituído. |
| Consistência | Se o perfil não puder ser gravado, a conta recém-criada no Auth é removida. |

O app não contém o código, não o grava em `UserDefaults`/`AppStorage` e não o registra em logs.

## 3. Perfil ADMIN e implantação manual (obrigatória)

### 3.0. Como o administrador é identificado

Não há mais e-mail fixo no app nem nas regras. Um usuário é administrador quando **as duas** condições
abaixo são verdadeiras — ambas atribuídas somente em ambiente confiável (Admin SDK / Console, que ignoram
as regras), nunca pelo app:

| Fonte | Valor | Quem pode alterar |
|-------|-------|-------------------|
| Custom claim no token do Firebase Auth | `admin: true` | somente Admin SDK |
| `users/{uid}.userType` | `"ADMIN"` | somente Admin SDK / Console (regras bloqueiam clientes) |

- **App** (`AppSession`): lê `users/{uid}` do servidor (`source: .server`) e, se `userType == ADMIN`, renova o
  token (`getIDTokenResult(forcingRefresh: true)`) e confere a claim. Só então `isAdmin = true`.
  Não usa `UserDefaults`/`AppStorage` para autorização. Um perfil `ADMIN` sem claim não entra no app.
- **Regras**: `isTeacherSignupAdmin()` / `isAdmin()` exigem claim **e** `userType == 'ADMIN'`.
- A alternância Administrador/Aluno/Professor (`AdminProfileMode`) é apenas em memória: **não** altera o
  `userType` persistido.

Estado verificado (somente leitura) em 2026-10-12 na conta administrativa atual:

- UID `StkCmATGBiaZJeZPTCtjEpdYwZB3` (e-mail do Auth e do perfil coincidem com o antigo e-mail fixo);
- `users/{uid}.userType = "STUDENT"`; 16 campos preservados (`name`, `photoBase64`, `measurementUnit`, ...);
- **nenhuma** custom claim; `teacher_signup_config`, `teacher_signup_codes` e `teacher_signup_redemptions` vazias.

### 3.1. Regras do Firestore — alterações exatas sobre o ruleset publicado

Ruleset publicado em 2026-10-12: `projects/rdvperformanceapp/rulesets/7cf63bab-e374-49a0-b7ba-352430d37659`.
Ele **não contém** regras para `teacher_signup_*` e termina com `match /{document=**} { allow read, write: if false; }`.

Editar no Console (Firestore Database → Regras), **sem substituir o restante**:

**(1) `isAdmin()` — fase A (transitória):**

```
function isAdmin() {
  return isSignedIn() && (
    request.auth.uid == "StkCmATGBiaZJeZPTCtjEpdYwZB3" // TRANSITÓRIO — remover na fase B
    || isTeacherSignupAdmin()
  );
}
```

**(2) `targetIsStudent()`** — acrescentar `"ADMIN"` à lista (mantém o acesso que professores já têm hoje ao
perfil do administrador, que atualmente é `STUDENT`):

```
"STUDENT", "student", "Student",
"ALUNO", "aluno", "Aluno",
"ADMIN"
```

**(3) `match /users/{userId}`** — trocar `allow write: if isOwner(userId);` por:

```
allow create: if isOwner(userId) && userTypeAllowedOnCreate(userId);
allow update: if isOwner(userId) && userTypeUnchanged();
allow delete: if isOwner(userId);
```

(`allow get` e `allow list` permanecem como estão.)

**(4)** Colar, **antes** de `match /{document=**}`, todo o conteúdo de `firebase/firestore-teacher-authorization.rules`
entre `function isTeacherSignupAdmin()` e o comentário de `match /users/{uid}` (funções e blocos
`teacher_signup_config`, `teacher_signup_codes`, `teacher_signup_redemptions`, `teacherSignupAuthorized`,
`userTypeAllowedOnCreate`, `userTypeUnchanged`).

**(5) Fase B (após a migração validada):** remover o UID fixo:

```
function isAdmin() {
  return isSignedIn() && isTeacherSignupAdmin();
}
```

Validação feita sem deploy (API `projects.test` do Firebase Rules, que apenas compila e simula):
fase A e fase B — **40/40** casos esperados; ruleset publicado — 25/40 (falhas = causa do erro e
brechas de `userType` descritas abaixo). Casos cobertos: administrador consulta/gera/substitui código;
outro UID com claim + ADMIN é aceito (sem dependência de e-mail/UID); claim sem `userType ADMIN` é negado;
aluno/professor/não autenticado não leem nem geram códigos; `list` de códigos negado; ninguém cria ou
altera `userType` para `ADMIN` (nem para si, nem para outros); `TRAINER` só com código vigente; aluno,
professor e administrador atualizam os demais campos do próprio perfil; administrador lista usuários e
atua nos modos Professor e Aluno.

### 3.2. Migração do administrador (ordem obrigatória)

1. **Verificar** o perfil atual (feito: ver 3.0). Opcional: `node set-admin-role.js ... --grant` sem `--apply`.
2. **Preparar a segurança:** publicar as regras da **fase A** (3.1, itens 1 a 4). O UID transitório mantém o
   acesso administrativo atual (versão publicada do app) durante a migração.
3. **Atribuir ADMIN** (ambiente confiável, plano Spark é suficiente):
   1. Console do Firebase → Configurações do projeto → Contas de serviço → *Gerar nova chave privada*.
      Salvar **fora** do repositório.
   2. ```
      cd firebase/admin-tools && npm install
      export GOOGLE_APPLICATION_CREDENTIALS="$HOME/Downloads/<chave>.json"
      node set-admin-role.js --project rdvperformanceapp --uid StkCmATGBiaZJeZPTCtjEpdYwZB3 --grant
      node set-admin-role.js --project rdvperformanceapp --uid StkCmATGBiaZJeZPTCtjEpdYwZB3 --grant --apply
      ```
      O script não cria/exclui contas; usa `update()` (preserva nome, foto e demais campos) e preserva outras claims.
   3. Apagar a chave baixada e, no Console, **excluir a chave** da conta de serviço.
4. **Garantir o acesso:** sair e entrar no app (renova o token). Testar os cenários da seção 5.
5. **App:** publicar a versão que identifica o administrador pelo perfil ADMIN (já sem e-mail fixo).
6. **Remover a dependência antiga:** publicar a **fase B** (3.1, item 5).

Reversão: `node set-admin-role.js --project rdvperformanceapp --uid <UID> --revoke --to STUDENT --apply`
(o `userType` é alterado primeiro, então a revogação vale imediatamente nas regras e no app).

### 3.3. Opcional (recomendado)

- Ativar o **Firebase App Check** para reduzir leituras automatizadas.
- Pré-existente e fora deste escopo: `teachers/{teacherId}` permite ao próprio usuário criar o documento,
  e `exists(teachers/{uid})` concede `isTrainer()` nas regras. Avaliar restringir a criação desse documento.

### 3.4. Correção do login ADMIN ("Seu perfil não foi encontrado") — situação em 2026-10-12

Verificação somente leitura em produção (projeto `rdvperformanceapp`, banco único `(default)`):

| Item | Resultado |
|------|-----------|
| Conta no Auth | 1 conta, UID `StkCmATGBiaZJeZPTCtjEpdYwZB3`, provedor senha, ativa |
| `users/StkCmATGBiaZJeZPTCtjEpdYwZB3` | **existe**, 16 campos, `userType = "ADMIN"` (ID do documento = UID; nenhum outro documento com o mesmo e-mail) |
| Custom claims | **nenhuma** (`admin: true` ausente) |
| Ruleset publicado | `c2ec8aef-c879-4619-a70d-87c685da4249` — `isAdmin()` verifica **apenas** `userType == 'ADMIN'` |

**Causa raiz:** o documento existe e o proprietário pode lê-lo (simulado: `get users/{uid}` → permitido).
O app exige perfil ADMIN **e** claim `admin: true`; como a claim não foi atribuída, `isAdmin = false`, e
`isLoggedIn` recusa perfil ADMIN não validado. O `LoginView` exibe então a mensagem genérica
`auth.login.profile_not_found` (a mesma usada para qualquer `isLoggedIn == false`). Não é documento
inexistente, nem permission-denied, nem projeto/banco/UID divergente.

Divergência: as regras publicadas aceitam ADMIN sem claim; o app exige a claim. Correção (sem remover a claim):

1. **Regras** (Console → Firestore → Regras), alterar somente `isAdmin()`:

   ```
   function isAdmin() {
     return isSignedIn()
       && request.auth.token.get('admin', false) == true
       && myUserType() == 'ADMIN';
   }
   ```

   Simulado na API `projects.test` (sem deploy): 38/38 casos esperados (login de todos os perfis; admin
   consulta, cria, substitui e remove códigos; ADMIN sem claim, claim sem ADMIN, aluno, professor e não
   autenticado negados; ninguém atribui ADMIN; cadastro de professor só com código vigente; modos Professor/Aluno do admin).

2. **Claim** (ambiente confiável, seção 3.2, passo 3): `set-admin-role.js --grant --apply` para o UID acima.
   O `userType` já é `ADMIN` (o script apenas o reafirma com `update()`, preservando os demais campos).

3. **Sair e entrar novamente** no app (o app renova o token com `forcingRefresh: true`).

Ordem sugerida: claim (2) → regras (1) → login (3). Com a ordem inversa, o administrador fica sem acesso
aos códigos até a claim existir (os demais usuários não são afetados).

Se `users/{uid}` estiver ausente em outra conta: não recriar a conta no Auth. Copiar o UID em
Authentication → Usuários, criar no Console o documento `users/<UID>` (mesmo ID) com os campos do perfil e
`userType` adequado; para ADMIN, depois executar `set-admin-role.js --grant --apply`.

Opcional: acrescentar `"ADMIN"` em `targetIsStudent()` para manter o acesso que professores tinham ao perfil
do administrador quando ele era `STUDENT`.

### 3.5. Código de uso único (`teacher_signup_code_uses`)

**Diagnóstico (comprovado):** o registro de uso era `teacher_signup_redemptions/{uid}` — um documento por
**professor**, não por **código**. As regras só exigiam que o código existisse; como o documento do código
permanece até a substituição, cada novo UID podia criar seu próprio registro com o mesmo código. Simulação no
ruleset publicado `ae27d509-…` (2026-10-12): perfil TRAINER com código já consumido → **permitido**.

**Solução:**

| Item | Detalhe |
|------|---------|
| Coleção nova | `teacher_signup_code_uses/{codeId}` — ID = código (12 caracteres, sem prefixo/hífens). |
| Documento | `{ usedAt: timestamp }` (somente; `serverTimestamp()` validado como `request.time`). |
| Vínculo com o professor | `teacher_signup_redemptions/{uid}.code` (criado na mesma operação; imutável; leitura do administrador). |
| Unicidade (servidor) | A regra só tem `create`; `update`/`delete` são negados. Um `set` sobre documento existente é avaliado como `update` → **negado**. O perfil TRAINER e o registro de uso exigem `!exists(consumo)` (antes) **e** `existsAfter(consumo)` (depois) — logo, o consumo precisa ser criado na mesma operação e não pode existir antes. |
| Concorrência | O app usa **transação** que lê o consumo no servidor; o SDK envia a pré-condição "documento inexistente" na confirmação. Se outro cadastro consumir antes, a confirmação falha, a transação é repetida e o código é recusado (`codeAlreadyUsed`). Mesmo sem essa pré-condição, a regra acima recusa o segundo. |
| Consumo somente na conclusão | Validar o código, abrir `RegisterTeacherView`, cancelar ou voltar **não grava nada**. O consumo nasce somente na transação que cria o perfil TRAINER; se ela falhar, nada é gravado (atômica) e a conta recém-criada no Auth é removida (compensação, como antes — Auth e Firestore não compartilham transação). |
| Permanência | O consumo não depende do código vigente nem do perfil: sobrevive a substituição do código, logout, reabertura do app e exclusão do professor. |
| Geração de códigos | A transação do administrador sorteia até 5 candidatos e descarta qualquer um que já tenha documento em `teacher_signup_codes` ou `teacher_signup_code_uses` (nunca sobrescreve). A regra de criação de código exige `!exists(consumo)`. Formato inalterado. |
| Consulta pelo administrador | Se o código vigente já foi consumido, ele não é reapresentado: a consulta gera um novo código (mesmo caminho já usado para estado inconsistente). Sem alteração visual. |
| Mensagens | Novo `TeacherAuthorizationError.codeAlreadyUsed` → `teacher_authorization.error.code_already_used` (pt-BR/en/es). Código inexistente continua "Código inválido"; substituído durante o preenchimento continua "autorização expirou"; falha de rede/permissão continuam com as mensagens próprias (permissão negada só vira "já utilizado" se o consumo for confirmado em nova leitura). |

**Publicação manual (ordem obrigatória — junto com a versão do app):**

1. Console → Firestore → `(default)` → Regras. Confirmar que a versão vigente é `ae27d509-…`.
   - Se for: colar `firebase/firestore-production-proposed.rules` inteiro e publicar.
   - Se não for: aplicar sobre as regras vigentes somente os 5 trechos marcados abaixo (idênticos aos de
     `firebase/firestore-teacher-authorization.rules`).
2. Os 5 trechos (sobre `ae27d509`):
   1. função `teacherSignupCodeUsePath(codeId)`;
   2. `teacher_signup_codes` `create`: `&& !exists(teacherSignupCodeUsePath(codeId))`;
   3. `teacher_signup_redemptions` `create`: `&& !exists(teacherSignupCodeUsePath(request.resource.data.code))
      && existsAfter(teacherSignupCodeUsePath(request.resource.data.code))`;
   4. novo `match /teacher_signup_code_uses/{codeId}` (get público, list admin, só create, sem update/delete);
   5. `teacherSignupAuthorized(uid)`: `&& !exists(...consumo...) && existsAfter(...consumo...)`.
3. **Compatibilidade de ordem:** com as regras novas, um build que ainda grava o cadastro sem o consumo
   (código anterior desta branch) é recusado; com as regras atuais, o build novo é recusado (coleção sem regra
   → curinga `if false`, mensagem "ainda não está disponível"). Publicar as regras no momento da distribuição
   do build novo. A versão da App Store (Cloud Functions inexistentes) já não cadastra professores — sem impacto.

Simulação (`projects.test`, sem deploy): proposta **18/18**; publicado 11/18 (permite reutilização, não tem a
coleção). O arquivo complementar não compila isoladamente por causa do bloco ilustrativo vazio de `users`
(pré-existente; o arquivo não é publicável sozinho).

**Dados existentes (leitura 2026-10-12):** 1 registro em `teacher_signup_redemptions`, cujo código **já foi
substituído** (não é o vigente; seu documento em `teacher_signup_codes` não existe mais) — portanto já é
inválido. O código vigente (versão 2) não tem registro de uso. **Nenhuma migração é necessária.** Se houver
dúvida sobre o histórico em outro momento, basta o administrador gerar um novo código (rotação). Opcional e
idempotente: para cada `teacher_signup_redemptions/{uid}`, criar pelo Console/Admin SDK
`teacher_signup_code_uses/{code}` com `usedAt` = `createdAt` do registro, **somente se ainda não existir**.

## 4. Riscos e limitações

- **Sem as regras publicadas**, o modal do administrador exibe "Você não tem permissão..." (comprovado em
  2026-10-12: o ruleset publicado não tem regras para `teacher_signup_*`, e o curinga final `if false` nega
  o `get` em `teacher_signup_config/current`, primeira leitura da transação) e a validação
  do professor exibe "O cadastro de professores ainda não está disponível...". Nenhum cadastro é liberado.
- **Sem as regras de `users`**, versões que gravam o perfil diretamente continuam podendo criar `TRAINER` sem código.
- **Versões antigas do app** (anteriores à autorização) gravam `TRAINER` diretamente: após publicar as regras,
  essa gravação será negada depois da criação no Auth, podendo deixar contas sem perfil. Versões que usam as
  Cloud Functions continuam sem conseguir cadastrar professores (funções inexistentes). Recomenda-se exigir
  atualização (`AppUpdateGateView`).
- **Sem limite de tentativas no servidor** (o plano Spark não executa código no backend). A proteção contra
  força bruta é a entropia do código (≈ 60 bits, inviável de enumerar). Leituras em massa, porém, consomem a
  cota diária gratuita do Firestore — App Check reduz esse risco.
- O código é **reutilizável** até ser substituído (mesma semântica anterior: cada professor autorizado usa o
  código vigente). Para revogar, o administrador gera um novo código.
- O administrador é identificado pelo perfil ADMIN (claim `admin: true` + `userType = ADMIN`), vinculado ao UID.
- Após a migração, o administrador aparece na aba de professores em `AdminUsersView` (o filtro considera
  "não aluno" como professor). Nenhum layout foi alterado.
- O diretório `functions/` (não publicado, não usado pelo app) ainda contém `ADMIN_EMAILS` como valor padrão.

## 5. Cenários de validação (Xcode)

1. Administrador migrado: login → seleção Administrador/Aluno/Professor; alternar entre os três e voltar
   por "Trocar perfil (Admin)"; `userType` no Firestore continua `ADMIN`.
2. "Código de autorização de professores": 1º acesso gera o código; reabrir mostra o mesmo; copiar; gerar novo;
   o código anterior passa a ser recusado no cadastro de professor.
3. Administrador nos modos Professor (alunos, envio de treinos, biblioteca) e Aluno (Home, treinos, recordes, perfil).
4. Aluno e professor existentes: login, Home, treinos, recordes, perfil, edição de nome/foto/unidade.
5. Cadastro de aluno; cadastro de professor com código válido, inválido e substituído.
6. Conta com `userType = ADMIN` **sem** claim: login exibe "perfil não encontrado" (não entra como admin nem aluno).
7. Conta com claim mas `userType` diferente de ADMIN: entra no fluxo normal do seu tipo, sem opções de admin.
8. Fechar e reabrir o app (build Release/TestFlight) com o administrador logado.
9. Antes da migração, a nova versão **não** reconhece o administrador (perfil `STUDENT`): executar a seção 3.2 antes dos testes.
10. Uso único (após publicar a seção 3.5): código A cadastra o professor 1 → `teacher_signup_code_uses/A` criado;
    professor 2 com A → "Este código de autorização já foi utilizado..." já no modal; reabrir o app → A continua recusado.
11. Código B: abrir o cadastro e cancelar/voltar → B continua aceito (nenhum documento em `teacher_signup_code_uses`).
12. Código B com falha na gravação (ex.: modo avião após criar a conta) → nenhum consumo gravado; conta do Auth removida.
13. Concorrência: dois aparelhos validam B, preenchem e confirmam quase juntos → um conclui; o outro recebe
    "já utilizado" e sua conta do Auth é removida; só um `users/{uid}` TRAINER com B em `teacher_signup_redemptions`.
14. Administrador reabre a tela após o uso de A → um novo código é exibido; gerar C → C funciona uma vez; A e B seguem recusados.
15. Console/Playground: criar `users/{uid}` TRAINER sem `teacher_signup_code_uses` no mesmo lote → negado;
    excluir/alterar `teacher_signup_code_uses/{id}` como cliente → negado.

