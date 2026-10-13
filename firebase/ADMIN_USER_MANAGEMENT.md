# Administração de usuários — status da conta, exclusão e versão instalada

> Nenhum deploy, migração ou exclusão é feito automaticamente. Regras e ferramentas abaixo são
> aplicadas **manualmente** pelo responsável pelo projeto.

## 1. Diagnóstico (2026-10-12, leitura somente)

- `AdminUsersView`: a lixeira abria uma confirmação e, ao confirmar, apenas exibia
  "Exclusão indisponível". Nenhuma operação era executada.
- O app não pode excluir/bloquear **outra** conta no Firebase Authentication: o SDK cliente só
  opera sobre o próprio usuário. Isso exige Firebase Admin SDK em ambiente confiável.
- Plano **Spark**: Cloud Functions (e Cloud Run) exigem o plano Blaze (cobrança habilitada).
  Um backend HTTPS próprio fora do Firebase também teria custo/infraestrutura. Portanto:
  - **Desativar/reativar**: feito pelo app, com bloqueio efetivo pelas **regras do Firestore**;
    o bloqueio no Authentication é complementar, por ferramenta local.
  - **Excluir definitivamente**: feito somente pela ferramenta local `admin-tools/delete-user.js`.
    O app mostra o UID (com opção de copiar) e informa que a exclusão exige a operação administrativa.
- Produção: 24 perfis; `active` = `true` (alunos/ADMIN), `null` (professores); nenhum `false`.
  `app_config/ios` **não existe** e as regras publicadas **não permitem lê-lo** — hoje a verificação
  de atualização (`AppUpdateGateView`) sempre resulta em "atualizado".

## 2. Campos em `users/{uid}`

| Campo | Origem | Observação |
|-------|--------|------------|
| `active` (reutilizado) | cadastro (`true` aluno, `null` professor); administrador | Único uso no projeto é a situação da conta. `false` = inativa; `true`, `null` ou ausente = **ativa** (compatibilidade com registros legados). |
| `activeUpdatedAt`, `activeUpdatedBy` (novos) | administrador / admin-tools | Auditoria da última mudança de status. |
| `appVersion` (novo) | dispositivo do próprio usuário | `CFBundleShortVersionString` (somente se numérica válida). |
| `appBuild` (novo) | dispositivo do próprio usuário | `CFBundleVersion`. |
| `appVersionUpdatedAt` (novo) | dispositivo do próprio usuário | `serverTimestamp()` da última comunicação. |

## 3. Desativação / reativação

**Pelo app (AdminUsersView → lixeira → Desativar/Reativar conta → confirmação):**

1. `AdminUsersViewModel.setAccountActive` grava somente `active`, `activeUpdatedAt`, `activeUpdatedBy`.
2. As **regras** validam: claim `admin` + perfil ADMIN, nunca a própria conta, nunca outro ADMIN,
   somente esses três campos. A lista é atualizada após a confirmação da gravação.
3. Efeito imediato: `isSignedIn()` passa a exigir conta ativa, então **todas** as coleções
   (inclusive as amplas `training_weeks`, `teacher_student_*`, `messages`, `workout_templates`,
   `teachers/*`, recordes) negam leitura e escrita para a conta inativa — também nas sessões já abertas.
4. No próximo login/abertura, o app lê o perfil (o dono pode ler o próprio documento mesmo inativo),
   encerra a sessão e mostra "Esta conta está desativada…".
5. O próprio usuário não consegue alterar `active` (regra `accountStatusUnchanged`).

**Bloqueio também no Authentication (recomendado, manual):**

```
cd firebase/admin-tools && npm install
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/<fora-do-repo>/chave.json"
node set-account-status.js --project rdvperformanceapp --uid <UID> --disable            # dry-run
node set-account-status.js --project rdvperformanceapp --uid <UID> --disable --apply    # Auth disabled + revoga tokens + active=false
node set-account-status.js --project rdvperformanceapp --uid <UID> --enable --apply     # reativa (mesmo UID e dados)
node set-account-status.js --project rdvperformanceapp --check-all                      # inconsistências Auth x Firestore
```

Após `revokeRefreshTokens`, ID tokens já emitidos continuam válidos por até 1 hora no Auth, mas as
regras do Firestore já negam o acesso pelo `active == false`.

## 4. Exclusão definitiva (somente ferramenta local)

```
node delete-user.js --project rdvperformanceapp --uid <UID>                          # inventário (dry-run)
node delete-user.js --project rdvperformanceapp --uid <UID> --apply --confirm <UID>  # executa
```

Ordem: bloqueio → dados relacionados → `users/{uid}` (recursivo) → conta no Authentication (por último).
Andamento em `admin_account_deletions/{uid}` (clientes sem acesso). Em falha, nenhuma etapa posterior é
executada; repetir o mesmo comando continua com segurança (etapas idempotentes). Contas ADMIN são recusadas.

| Dado | Aluno excluído | Professor excluído |
|------|----------------|--------------------|
| `users/{uid}` + subcoleções (recordes, notificações, vídeos) | exclui | exclui |
| `teachers/{uid}` + subcoleções | exclui | exclui |
| `teacher_students`, `teacher_student_relations`, `teacher_student_link_requests`, `teacher_student_invites` | exclui (studentId / studentEmail) | exclui (teacherId) |
| `workout_templates` (teacherId) | — | exclui |
| `training_weeks` (+ `days`, `student_progress`) | exclui (studentId) | **mantém** (pertencem aos alunos) |
| `teacher_messages`, `student_feedbacks` | exclui (studentId) | **mantém** (pertencem aos alunos) |
| `teacher_signup_redemptions/{uid}` | — | **mantém** (auditoria, sem dados pessoais) |

Coleções legadas sem campos de vínculo conhecidos (`progress`, `messages`, `feedbacks`, `training_days`
na raiz) não são tratadas pela ferramenta. Verificado em 2026-10-12 (leitura): essas coleções **não
existem** em produção; as coleções raiz existentes são todas cobertas pela política acima.

Observações da revisão (2026-10-12, somente leitura):

- `teacher_student_invites` não possui `studentId`: o vínculo com o aluno é `studentEmail`
  (todos gravados em minúsculas); a ferramenta exclui por `studentEmail` e por `teacherId`.
- `teachers/{uid}` pode existir apenas como caminho de subcoleções (documento-pai inexistente);
  `listCollections()` + `recursiveDelete()` cobrem esse caso.

Dados que **permanecem** após a exclusão (decisão de retenção, sem alteração nesta revisão):

| Dado | Conteúdo remanescente | Motivo / consequência |
|------|----------------------|------------------------|
| Professor excluído: `training_weeks`, `teacher_messages`, `student_feedbacks` (teacherId) | UID do professor e textos/treinos que ele escreveu | Pertencem aos alunos; excluir apagaria o histórico deles. O app do aluno pode encontrar um `teacherId` sem perfil (validar no Xcode). |
| `teacher_signup_redemptions/{uid}` | UID + código usado + data | Auditoria do cadastro de professores; sem nome/e-mail. |
| `admin_account_deletions/{uid}` | UID, tipo, datas e etapas (e-mail temporário é removido ao concluir) | Recuperação segura de execuções parciais. |
| Dispositivo do usuário | Cache local (perfil/foto/recordes) | Fora do alcance do servidor. |
| Backups/PITR do Firestore (se ativados) | Cópias anteriores | Expiram conforme a configuração do projeto. |

Alterar essa política (por exemplo, apagar treinos criados por um professor excluído) removeria dados
de alunos ativos e não é recomendado.

## 5. Regras do Firestore (publicação manual)

Proposta completa, derivada do ruleset publicado `c2ec8aef-c879-4619-a70d-87c685da4249`:
`firebase/firestore-production-proposed.rules`. Antes de publicar, compare com as regras vigentes.

Alterações (somente estas):

1. `isSignedIn()` → `request.auth != null && accountActive()` (nova função; ausente/`null` = ativa;
   perfil inexistente = ativa, para não quebrar cadastro).
2. `isAdmin()` → exige também `request.auth.token.admin == true` (alinhado com o app).
3. Novas funções `activeAllowedOnCreate`, `accountStatusUnchanged`, `installedVersionValid`,
   `adminChangesAccountStatus`.
4. `users/{userId}`: `get` do próprio documento sem exigir conta ativa; `create` com
   `activeAllowedOnCreate()` e `installedVersionValid()`; `update` =
   (dono && `userTypeUnchanged` && `accountStatusUnchanged` && `installedVersionValid`)
   **ou** `adminChangesAccountStatus(userId)`.
5. `match /app_config/{docId} { allow get: if true; allow list, write: if false; }`.

Simulação na API `projects.test` (sem deploy): **49/49** casos esperados na proposta; o ruleset
publicado falha 20 (ex.: usuário altera o próprio `active`, conta inativa mantém acesso,
`app_config/ios` ilegível). Cobertura: admin desativa/reativa aluno e professor legado; admin não
desativa a si nem outro ADMIN, nem altera outros campos/versão/userType; ADMIN sem claim, professor
e aluno não alteram status; conta inativa não lê/grava treinos, vínculos, recordes, modelos,
mensagens nem `teachers/*`; usuário informa a própria versão (tipos validados) e não a de outros;
cadastros de aluno e professor (com e sem código), atualização de perfil e exclusão da própria conta preservados.

Custo: `accountActive()` consulta o perfil do solicitante em cada requisição (leituras de documentos
dependentes são cobradas e contam na cota diária do Spark — 50 mil leituras/dia; repetidas no mesmo
pedido são reaproveitadas).

## 6. Versão instalada

- Registro: `AppSession.loadUserProfile` (após login ou ao restaurar sessão) compara `appVersion`/`appBuild`
  do perfil (lido do servidor) com o bundle; grava somente se diferentes, em tarefa separada (não bloqueia
  o app; falha é ignorada e tentada no próximo carregamento). Sem listeners. Conta inativa não grava.
- Classificação na lista: `AppVersion` (comparação numérica por componentes, já existente) contra
  `latestVersion` de `app_config/ios` (validado por `AppVersionConfig`), lido uma vez por carregamento:
  - instalada ≥ `latestVersion` → **Atualizado** (verde);
  - instalada < `latestVersion` → **Desatualizado** (amarelo);
  - sem referência válida → "Versão X — Sem informação";
  - versão não registrada → "Versão não informada".
  O build não é usado: `latestVersion` não tem build associado (o `minimumBuild` existente só se aplica
  à atualização obrigatória).
- **Pendência externa:** criar `app_config/ios` manualmente (o app nunca o cria). Ordem recomendada:
  1. Publicar as regras propostas (sem `match /app_config/{docId}` com leitura, o documento é ilegível
     para o app e a lista mostra "Sem informação").
  2. Console → Firestore Database → Iniciar coleção `app_config` → ID do documento `ios`, campos:

     | Campo | Tipo | Exemplo | Regra |
     |-------|------|---------|-------|
     | `minimumVersion` | string | `"1.0.23"` | obrigatório; números separados por ponto; ≤ `latestVersion` |
     | `latestVersion` | string | `"1.0.23"` | obrigatório; referência de "Atualizado" na lista |
     | `forceUpdate` | boolean | `false` | obrigatório; `true` bloqueia versões abaixo de `minimumVersion` |
     | `appStoreURL` | string | link do app na App Store | obrigatório e não vazio |
     | `minimumBuild` | number | `25` | opcional; só usado com `forceUpdate` quando a versão instalada = `minimumVersion` |
     | `message` | string | — | opcional |

     Documento sem um campo obrigatório ou com versões inválidas é **ignorado** (o app segue normalmente e
     a lista mostra "Sem informação" — nunca "Atualizado").
  3. Ao publicar uma nova versão na App Store, atualizar `latestVersion`; usar `forceUpdate: true` somente
     quando a atualização obrigatória for desejada.

## 7. Limitações

- Exclusão definitiva e bloqueio no Authentication dependem da execução manual das ferramentas
  (ou de migração para Blaze + backend). O app não declara uma exclusão concluída.
- O app não lê o estado `disabled` do Authentication; o status exibido é o `active` do Firestore,
  que é o efetivamente aplicado pelas regras. Use `--check-all` para detectar divergências.
- Versões já publicadas (sem esta implementação) não informam versão e não mostram a mensagem de
  conta desativada; ainda assim, as regras bloqueiam os dados de uma conta inativa.
- Sessão aberta antes da desativação: não há listener do perfil (por decisão de desempenho). As regras
  negam os dados imediatamente; o app só identifica a conta inativa e encerra a sessão no próximo
  carregamento do perfil (login ou reabertura). Até lá, as telas exibem erros de permissão.
- Até a publicação das regras propostas, "Desativar/Reativar" no app falha com erro de permissão
  (a regra publicada só permite ao dono alterar o próprio perfil) — nenhuma alteração é simulada.
- Pré-existente e fora deste escopo: `users/{uid}/notification_state/profile` é usado pelo app, mas não
  há regra para esse caminho (publicada nem proposta), logo é negado pela regra padrão.

