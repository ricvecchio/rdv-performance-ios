# Autorização administrativa para cadastro de Professores

Este documento descreve o mecanismo de código de autorização exigido para criar contas
do tipo **Professor (TRAINER)** no RDV Performance, e as etapas **manuais** de implantação.

> Nenhum deploy é feito automaticamente. Até que as Cloud Functions estejam publicadas e as
> regras do Firestore estejam mescladas, a proteção **não** deve ser considerada ativa.

---

## 1. Visão geral do fluxo

```text
Seleção de tipo de conta
  ├─ Aluno     -> cadastro inalterado (Firebase Auth + Firestore pelo app)
  └─ Professor -> modal "Código de autorização"
                   -> validateTeacherSignupCode (Cloud Function)
                        ├─ inválido  -> mensagem amigável, sem navegação
                        └─ válido    -> ticket temporário de uso único (30 min, em memória)
                                         -> RegisterTeacherView (campos inalterados)
                                              -> createTeacherAccount (Cloud Function)
                                                   ├─ valida e consome o ticket
                                                   ├─ cria o usuário no Firebase Auth
                                                   └─ cria users/{uid} com userType = TRAINER
                                              -> login automático no app
```

## 2. Geração, armazenamento e validação do código

| Item | Detalhe |
|------|---------|
| Geração | `crypto.randomInt` (Node.js, criptograficamente seguro), somente no backend. |
| Formato | `RDV-XXXX-XXXX-XXXX` — 12 caracteres aleatórios do alfabeto `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (sem `I`, `O`, `0`, `1`), ≈ 60 bits de entropia. |
| Armazenamento | `teacher_signup_config/current`: `code`, `codeHash` (SHA-256), `version`, `updatedAt`, `updatedBy`. Coleção bloqueada para clientes. |
| Validação | Comparação em tempo constante do hash. Entrada normalizada (maiúsculas, ignora hífens/espaços, prefixo `RDV` opcional). |
| Limite de tentativas | 5 tentativas inválidas por IP em 15 min → bloqueio de 30 min (`teacher_signup_attempts`, chave = SHA-256 do IP). |
| Autorização emitida | Ticket aleatório de 256 bits, guardado no servidor apenas como hash em `teacher_signup_tickets`, válido por 30 min e vinculado à `version` do código. |
| Uso único | `createTeacherAccount` reserva o ticket em transação (`issued` → `processing` → `used`). Ticket já usado, expirado ou de versão anterior é rejeitado. |
| Substituição | `rotateTeacherSignupCode` gera um novo código e incrementa `version`: o código anterior **e** os tickets ainda não usados deixam de funcionar imediatamente. |
| Consistência | Se a gravação do perfil falhar, a conta criada no Auth é removida e o ticket é liberado para nova tentativa. |

O app **não** contém o código, não o grava em `UserDefaults`/`AppStorage` e não o registra em logs.
O ticket fica apenas em memória (`TeacherSignupAuthorizationStore`) até o cadastro ser concluído.

## 3. Uso pelo administrador

1. Entrar no app com a conta administradora.
2. Na tela de seleção de perfis, tocar em **"Código de autorização de professores"** (abaixo dos três perfis).
3. O modal consulta o backend e exibe o código vigente (no primeiro acesso, o código inicial é gerado automaticamente).
4. **Copiar**: copia apenas para o dispositivo local, com expiração automática de 2 minutos na área de transferência.
5. **Gerar novo código**: pede confirmação, substitui o código e invalida o anterior.

A permissão de administrador é verificada **no servidor**: e-mail do token de autenticação presente em
`ADMIN_EMAILS` (`functions/.env`) **ou** custom claim `admin: true`. O `AppSession.isAdmin` controla apenas a exibição do botão.

## 4. Implantação manual

### 4.1. Pré-requisitos

- Projeto Firebase `rdvperformanceapp` no plano **Blaze** (obrigatório para Cloud Functions).
- Firebase CLI instalada (`npm install -g firebase-tools`) e autenticada (`firebase login`).
- Node.js 22 (o runtime Node.js 20 foi descontinuado em 2026-04-30 e o deploy é bloqueado a partir de 2026-10-30).

### 4.2. Cloud Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

Funções publicadas (região `us-central1`):

- `getTeacherSignupCode`
- `rotateTeacherSignupCode`
- `validateTeacherSignupCode`
- `createTeacherAccount`

As funções `validateTeacherSignupCode` e `createTeacherAccount` são chamadas por usuários **não autenticados**.
Ao publicar funções callable de 2ª geração, a CLI concede a invocação pública (`allUsers`) automaticamente.
Caso a organização do Google Cloud bloqueie esse acesso, conceda manualmente o papel *Cloud Run Invoker* para `allUsers`
nas quatro funções. A autorização efetiva é feita dentro de cada função.

Se a região for alterada, atualizar também `region` em `TeacherAuthorizationService.swift`.

### 4.3. Regras do Firestore

O arquivo `firebase/firestore-teacher-authorization.rules` contém **trechos para mesclar** nas regras atuais
(Console do Firebase → Firestore Database → Regras). Ele **não** substitui as regras existentes e não está
referenciado no `firebase.json`, para evitar sobrescrever as regras de produção.

1. Adicionar os blocos `deny` das coleções `teacher_signup_config`, `teacher_signup_tickets` e `teacher_signup_attempts`.
2. Verificar se existe algum curinga amplo (por exemplo `match /{document=**}`) que libere essas coleções. Regras são
   combinadas por **OU**: um curinga permissivo anula o bloqueio. Se existir, restringi-lo.
3. Em `match /users/{uid}`, acrescentar com `&&`:
   - `userTypeAllowedOnCreate()` à regra de **create**;
   - `userTypeUnchanged()` à regra de **update**.
4. Validar no *Rules Playground* antes de publicar:
   - aluno criando o próprio perfil `STUDENT` → permitido;
   - cliente criando perfil `TRAINER` → negado;
   - aluno alterando o próprio `userType` para `TRAINER` → negado;
   - professor existente atualizando nome/telefone/foto → permitido;
   - qualquer cliente lendo `teacher_signup_config/current` → negado.

### 4.4. Opcional — limpeza automática

Criar políticas de TTL (Firestore → TTL) no campo `expiresAt` das coleções
`teacher_signup_tickets` e `teacher_signup_attempts` para remover documentos expirados.

## 5. Riscos e dependências pendentes

- **Sem deploy, o cadastro de professor falha** na versão nova do app (mensagem de falha de conexão). O cadastro de alunos não é afetado.
- **Versões antigas do app** (já publicadas) gravam o perfil `TRAINER` diretamente pelo cliente. Após publicar as regras,
  essa gravação será negada; o cadastro falhará depois da criação no Firebase Auth, podendo deixar contas sem perfil.
  Recomenda-se publicar a nova versão do app e, se necessário, exigir atualização (`AppUpdateGateView`).
  **Sem as regras**, versões antigas continuam permitindo criar professores sem código.
- A contagem de tentativas usa o IP informado pela infraestrutura do Google (`x-forwarded-for`). Redes compartilhadas (NAT)
  podem compartilhar o mesmo limite.
- Recomenda-se ativar o **Firebase App Check** futuramente para reduzir chamadas automatizadas às funções públicas.
- A senha do professor é enviada por HTTPS à função `createTeacherAccount` para criação da conta pelo Admin SDK; ela não é armazenada nem registrada em logs.

