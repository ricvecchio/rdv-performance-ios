# RDV Performance - App iOS (SwiftUI)

O **RDV Performance** e um aplicativo iOS em SwiftUI para gerenciamento e acompanhamento de treinos. O produto atende as modalidades **Crossfit**, **Academia** e **Treinos em Casa**, com experiencias distintas para **Aluno**, **Professor** e **Administrador**.

---

## Tecnologias utilizadas

- **Swift** e **SwiftUI**, com `NavigationStack`, `AppStorage` e SF Symbols;
- **Firebase Authentication** para autenticacao;
- **Cloud Firestore** para perfis, vinculos, treinos, comunicacao, templates e recordes;
- **Combine** para estados observaveis dos fluxos;
- **PhotosUI** e **UIKit** para foto e avatar do perfil;
- **CoreXLSX** e `UIDocumentPickerViewController` para importacao de planilhas Excel;
- **WebKit** e **AVKit** para reproducao de videos do YouTube e AirPlay;
- **UserDefaults** para preferencias e cache local, incluindo dados pendentes de sincronizacao de recordes.

---

## Estrutura de navegacao

`AppRouter` controla o fluxo principal a partir de `AppSession`. A sessao observa a autenticacao, carrega o perfil em Firestore e encaminha o usuario para a experiencia correspondente:

```text
Usuario nao autenticado
  -> Login
  -> Selecao do tipo de conta
  -> Cadastro de Aluno ou Professor

Aluno autenticado
  -> StudentRootView

Professor autenticado
  -> TeacherRootView

Administrador autenticado
  -> AdminProfileSelectionView
  -> Perfil Administrador, Perfil Aluno ou Perfil Professor
```

As raizes de aluno e professor mantem pilhas de navegacao independentes para suas secoes principais. Isso separa a troca de secao da navegacao hierarquica de cada tela.

---

## Autenticacao, sessao e perfil

O login e os cadastros de aluno e professor usam Firebase Authentication. `AppSession` acompanha a sessao autenticada, recupera os dados essenciais do perfil no Firestore e prepara a sincronizacao de Recordes Pessoais para o UID ativo.

### Perfil

`ProfileView` exibe foto ou avatar, nome, unidade, e-mail, WhatsApp, CREF e biografia quando disponiveis. A edicao de perfil permite atualizar foto/avatar, nome, WhatsApp, area de foco, CREF e biografia; o e-mail e apenas informativo nessa tela.

As opcoes exibidas respeitam o perfil ativo:

| Perfil | Opcoes especificas |
|---|---|
| Aluno | Trocar unidade, Mensagens, Feedbacks e Meus professores |
| Professor | Trocar unidade e Meus Icones |
| Administrador em perfil de aluno ou professor | Trocar perfil (Admin), alem das opcoes do perfil selecionado |

O modulo de configuracoes oferece edicao de perfil, unidade de medida, troca de senha, exclusao da propria conta, central de ajuda, politica de privacidade e termos de uso.

---

## Modalidades

As modalidades organizam os vinculos entre professores e alunos, as bibliotecas, os templates e os treinos enviados:

- **Crossfit**
- **Academia**
- **Treinos em Casa**

---

## Area do aluno

`StudentRootView` disponibiliza quatro secoes principais:

| Secao | Funcionalidades ativas |
|---|---|
| Home | Avisos de vinculo, solicitacao de vinculo com professor, progresso semanal e proximos treinos |
| Treinos | Semanas recebidas, filtros de situacao, dias de treino, detalhes e progresso |
| Recordes | Categorias de Recordes Pessoais, edicao e importacao do Tecnofit quando disponivel |
| Perfil | Dados da conta, unidade, mensagens, feedbacks e professores vinculados |

### Treinos e progresso

O aluno consulta semanas de treino recebidas e seus dias, com filtros para semanas atuais, proximas e concluidas. O detalhe do treino apresenta os blocos, videos associados e o acompanhamento de conclusao por dia.

Quando um bloco utiliza percentual de Recorde Pessoal de **Barbell**, o app calcula o peso correspondente a partir do recorde salvo pelo aluno. O progresso da semana e atualizado conforme os dias sao marcados como concluidos.

### Recordes Pessoais

O aluno pode visualizar e editar recordes nas categorias:

- Barbell
- Gymnastic
- Endurance
- Notables
- Girls
- Open
- The Heroes
- Campeonatos
- Crossfit Games

Os recordes sao vinculados ao usuario e sincronizados com uma estrutura propria de Personal Records no Firestore. Alteracoes locais e remotas sao preservadas por merge, inclusive em cenarios de dados pendentes.

### Importar do Tecnofit

No fluxo de Recorde Pessoal, a primeira importacao segue este processo:

```text
Recorde Pessoal
  -> Importar do Tecnofit
  -> Informar credenciais
  -> Buscar recordes
  -> Visualizar resumo
  -> Importar
```

Os recordes existentes sao preservados; itens compativeis sao importados e itens sem mapeamento sao ignorados. A conclusao da primeira importacao fica registrada por usuario e, depois de concluida, o botao de importacao deixa de ser exibido.

---

## Area do professor

`TeacherRootView` organiza a experiencia do professor em quatro secoes:

| Secao | Funcionalidades ativas |
|---|---|
| Home | Visao geral de alunos e treinos publicados, com acesso rapido a Biblioteca de Treinos, Importar e Meus Videos |
| Alunos | Viculos, convites, solicitacoes e acesso ao acompanhamento individual |
| Treinos | Biblioteca, criacao, envio, importacao, videos e recordes |
| Perfil | Dados da conta, unidade e Meus Icones |

### Alunos e vinculos

O professor pode listar alunos vinculados e filtrar por modalidade, convidar alunos por e-mail e cancelar convites enviados. Tambem pode analisar solicitacoes de vinculo, definir a categoria ao aceitar, recusar solicitacoes e desvincular alunos.

No detalhe de um aluno, o professor consulta o progresso, acessa os treinos, envia mensagens e feedbacks, cria e envia treinos.

### Treinos do professor

A secao **Treinos** oferece os acessos:

- **Enviar treino** para alunos vinculados;
- **Criar treino**;
- **Biblioteca de Treinos**;
- **Importar** planilhas Excel;
- **Meus Recordes**;
- **Meus Videos**.

#### Bibliotecas por modalidade

As bibliotecas ativas sao organizadas conforme a modalidade:

| Modalidade | Secoes |
|---|---|
| Crossfit | Girls WODs, Hero & Tribute Workouts, Open WODs, WODs Nomeados, Qualifiers / WODs de Competicoes e Meus Treinos |
| Academia | Peito, Costas, Pernas, Ombros, Bracos, Core / Abdomen, Full Body e Meus Treinos |
| Treinos em Casa | Peito, Costas, Pernas, Ombros, Bracos, Core / Abdomen, Full Body e Meus Treinos |

Em cada secao, o professor administra templates e cria treinos apropriados para a modalidade.

### Importacao de treinos por Excel

O fluxo **Importar** permite baixar e utilizar o modelo de planilha Excel incluido no app, selecionar um arquivo `.xlsx` e ler seus treinos. Os itens importados podem ser visualizados, editados, excluidos e enviados a alunos.

### Meus Videos

O professor pode cadastrar links do YouTube com titulo e modalidade, organizar os videos salvos, reproduzi-los e envia-los para um aluno em uma semana e dia de treino. A reproducao usa WebView e inclui suporte a AirPlay.

---

## Administracao

`AdminProfileSelectionView` permite que o administrador escolha entre **Perfil Administrador**, **Perfil Aluno** e **Perfil Professor**. A escolha pode ser alterada posteriormente pela tela de Perfil.

No perfil de administrador, `AdminUsersView` lista usuarios, permite filtrar alunos e professores e consultar os dados disponiveis de cada perfil, incluindo vinculos e treinos relacionados.

---

## Persistencia e Firestore

`FirestoreRepository` centraliza a interface usada pelas telas e delega operacoes aos repositorios especializados.

| Repositorio | Responsabilidade |
|---|---|
| `UserRepository` | Perfis, vinculos, convites, solicitacoes e preferencias do usuario |
| `TrainingRepository` | Semanas, dias, publicacao e envio de treinos |
| `ProgressRepository` | Conclusao de dias e progresso de treino |
| `MessageRepository` | Mensagens entre professor e aluno |
| `FeedbackRepository` | Feedbacks destinados ao aluno |
| `WorkoutTemplateRepository` | Templates reutilizaveis de treino |
| `StudentPersonalRecordsRepository` | Armazenamento remoto dos Recordes Pessoais |

Os caminhos usados pelos fluxos ativos incluem:

| Caminho | Uso |
|---|---|
| `users` | Perfis, preferencias e unidade do usuario |
| `teacher_students` | Associacoes entre professor e alunos |
| `teacher_student_relations` | Relacoes e categorias de vinculo |
| `teacher_student_invites` | Convites enviados por professores |
| `teacher_student_link_requests` | Solicitacoes de vinculo iniciadas por alunos |
| `teacher_messages` | Mensagens entre professor e aluno |
| `student_feedbacks` | Feedbacks destinados a alunos |
| `workout_templates` | Templates de treino |
| `training_weeks/{weekId}/days` | Semanas e dias de treino |
| `training_weeks/{weekId}/student_progress` | Progresso do aluno na semana |
| `users/{uid}/student_personal_records` | Dados e metadados dos Recordes Pessoais |
| `teachers/{teacherId}/importedWorkouts` | Treinos importados por planilha |
| `teachers/{teacherId}/youtubeVideos` | Videos cadastrados pelo professor |

### Sincronizacao de Recordes Pessoais

`PersonalRecordsSyncService` sincroniza os registros locais e remotos para o UID autenticado. O servico vincula o cache ao usuario atual, trata alteracoes pendentes, evita a exposicao de dados de outra conta depois de uma troca de sessao e preserva exclusoes e dados concorrentes durante o merge antes da gravacao no Firestore.

---

## Componentes compartilhados

Os componentes reutilizados pelos fluxos ativos incluem:

- `FooterBar` e `HeaderBar` para navegacao e cabecalhos;
- `HeaderAvatarView` e `MiniProfileHeader` para apresentacao do perfil;
- `PhoneTextField` e `UnderlineTextField` para campos de formulario;
- `BlockDraft` para montagem de blocos de treino;
- `Theme` para cores, tipografia e medidas compartilhadas.

---

## Estrutura geral do app

```text
rdvperfomance/
├── App/
│   ├── AppRouter.swift
│   ├── AppRoute.swift
│   ├── AppSession.swift
│   └── TeacherRootView.swift
├── Features/
│   ├── Admin/
│   ├── Auth/
│   ├── Settings/
│   ├── Student/
│   │   ├── PersonalRecords/
│   │   └── Views/
│   ├── Teacher/
│   │   ├── ImportVideos/
│   │   ├── ImportWorkouts/
│   │   └── Views/
│   └── Treinos/
│       ├── Models/
│       └── Views/
├── Resources/
│   └── Templates/
└── Shared/
    ├── Components/
    ├── Navigation/
    ├── Services/
    │   └── Firestore/
    ├── UI/
    └── Utilities/
```

---

## Build e execucao

1. Abra `rdvperfomance.xcodeproj` em uma versao do Xcode compativel com o deployment target do projeto.
2. Configure um `GoogleService-Info.plist` valido para o ambiente de desenvolvimento.
3. Execute em simulador ou dispositivo iOS.
