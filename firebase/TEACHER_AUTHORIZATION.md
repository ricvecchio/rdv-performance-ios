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
                        └─ existente   -> código mantido apenas em memória
                                          -> RegisterTeacherView (campos inalterados)
                                               -> revalida o código no servidor
                                               -> cria a conta no Firebase Auth
                                               -> lote atômico:
                                                    teacher_signup_redemptions/{uid} {code}
                                                    users/{uid} {userType: TRAINER, ...}
                                                  (aceito pelas regras SOMENTE com código vigente)
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

## 3. Implantação manual (obrigatória)

### 3.1. Regras do Firestore

O arquivo `firebase/firestore-teacher-authorization.rules` contém **trechos para mesclar** nas regras atuais
(Console do Firebase → Firestore Database → Regras). Ele **não** substitui as regras existentes.

1. Copiar as funções `isTeacherSignupAdmin`, `teacherSignupCodePath`, `teacherSignupConfigPath`,
   `validTeacherSignupConfig`, `teacherSignupAuthorized`, `userTypeAllowedOnCreate` e `userTypeUnchanged`
   para dentro de `match /databases/{database}/documents`.
2. Copiar os blocos `match` de `teacher_signup_config`, `teacher_signup_codes` e `teacher_signup_redemptions`.
3. Em `match /users/{uid}`, acrescentar com `&&`:
   - `userTypeAllowedOnCreate(uid)` à regra de **create**;
   - `userTypeUnchanged()` à regra de **update**.
4. Verificar se existe curinga amplo (`match /{document=**}`) que libere essas coleções ou `users`.
   Regras são combinadas por **OU**: um curinga permissivo anula a proteção. Se existir, restringi-lo.
5. Validar no **Rules Playground** antes de publicar:
   - não autenticado: `get teacher_signup_codes/<código válido>` → permitido; `list` → negado;
   - não autenticado ou aluno: `get teacher_signup_config/current` → negado;
   - administrador: `get teacher_signup_config/current` → permitido;
   - aluno criando o próprio perfil `STUDENT` → permitido;
   - usuário criando perfil `TRAINER` **sem** `teacher_signup_redemptions/{uid}` no mesmo lote → negado;
   - aluno alterando o próprio `userType` para `TRAINER` → negado;
   - professor existente atualizando nome/telefone/foto → permitido.

### 3.2. Opcional (recomendado)

- Marcar o e-mail administrador como verificado e acrescentar `&& request.auth.token.email_verified == true`
  em `isTeacherSignupAdmin()`; ou configurar a custom claim `admin: true` (via Admin SDK, localmente).
- Ativar o **Firebase App Check** para reduzir leituras automatizadas.

## 4. Riscos e limitações

- **Sem as regras publicadas**, o modal do administrador exibe "Você não tem permissão..." e a validação
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
- O administrador é identificado pelo e-mail do token (mesmo critério de `AppSession`).

