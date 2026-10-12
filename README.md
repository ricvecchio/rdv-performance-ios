# RDV Performance - App iOS (SwiftUI)

O **RDV Performance** é um aplicativo iOS em SwiftUI para gerenciamento e acompanhamento de treinos. O produto atende às modalidades **Crossfit**, **Academia** e **Treinos em Casa**, com experiências distintas para **Aluno**, **Professor** e **Administrador**.

---

## Tecnologias utilizadas

- **Swift** e **SwiftUI**, com `NavigationStack`, `AppStorage` e SF Symbols;
- **Firebase Authentication** para autenticação;
- **Cloud Firestore** para perfis, vínculos, treinos, comunicação, templates, vídeos, recordes e configuração de versão;
- **Cloud Functions for Firebase** (Node.js 22) para a autorização de cadastro de professores, chamadas pelo app via HTTPS com `URLSession`;
- **Combine** para estados observáveis dos fluxos (`ObservableObject` e `@Published`);
- **PhotosUI** e **UIKit** para foto e avatar do perfil;
- **CoreXLSX** e `UIDocumentPickerViewController` para importação de planilhas Excel;
- **WebKit** e **AVKit** para reprodução de vídeos do YouTube e AirPlay;
- **Swift Charts** para os gráficos de histórico dos Recordes Pessoais;
- **SpriteKit** para a prévia visual de progresso;
- **Security (Keychain)** para as sessões das integrações NextFit e Tecnofit;
- **UserDefaults** para preferências e cache local, incluindo dados pendentes de sincronização de recordes.

As dependências externas do app são gerenciadas pelo Swift Package Manager: `firebase-ios-sdk` (produtos `FirebaseCore`, `FirebaseAuth` e `FirebaseFirestore`) e `CoreXLSX`.

---

## Estrutura de navegação

`rdvperfomanceApp` inicializa o Firebase e apresenta `AppUpdateGateView`, que verifica a versão mínima exigida antes de liberar `AppRouter`. `AppRouter` controla o fluxo principal a partir de `AppSession`. A sessão observa a autenticação, carrega o perfil em Firestore e encaminha o usuário para a experiência correspondente:

```text
Abertura do app
  -> AppUpdateGateView
  -> ForceUpdateView (quando a versão instalada é inferior à mínima)
  -> AppRouter

Usuário não autenticado
  -> Login
  -> Seleção do tipo de conta
  -> Cadastro de Aluno
  -> Código de autorização -> Cadastro de Professor

Aluno autenticado
  -> StudentRootView

Professor autenticado
  -> TeacherRootView

Administrador autenticado
  -> AdminProfileSelectionView
  -> Perfil Administrador, Perfil Aluno ou Perfil Professor
```

As raízes de aluno e professor mantêm pilhas de navegação independentes para suas seções principais (`StudentMainSection` e `TeacherMainSection`). Ao trocar de seção pelo `FooterBar`, a pilha da seção de destino é reiniciada, separando a troca de seção da navegação hierárquica de cada tela.

### Controle de versão

`AppVersionService` lê o documento `app_config/ios` no Firestore e compara a versão e o build instalados com `minimumVersion`, `minimumBuild` e `latestVersion`. Quando uma atualização obrigatória é exigida, `ForceUpdateView` bloqueia o acesso e direciona o usuário para a App Store. A verificação é repetida sempre que o app volta a ficar ativo.

---

## Autenticação, sessão e perfil

O login e o cadastro de alunos usam Firebase Authentication. `AppSession` acompanha a sessão autenticada, recupera nome, tipo de usuário, foto e unidade de medida no Firestore e prepara a sincronização de Recordes Pessoais para o UID ativo. Em builds de produção, os dados essenciais da sessão são persistidos com `AppStorage`; em builds `DEBUG`, a sessão é encerrada a cada inicialização.

O perfil de administrador é identificado pelo e-mail da conta autenticada e, nesse caso, `AppSession` controla o modo de perfil selecionado (`AdminProfileMode`).

### Autorização de cadastro de professores

O cadastro de professor depende de um código de autorização emitido pelo administrador:

```text
Seleção do tipo de conta
  -> Professor
  -> Informar código de autorização
  -> Validação no backend (validateTeacherSignupCode)
  -> Cadastro de Professor
  -> Criação da conta no backend (createTeacherAccount)
```

`TeacherAuthorizationService` chama as Cloud Functions e `TeacherSignupAuthorizationStore` mantém temporariamente a autorização emitida pelo servidor até a conclusão do cadastro. A conta do professor é criada pela Cloud Function, e não diretamente pelo app.

### Perfil

`ProfileView` exibe foto ou avatar, nome, unidade, e-mail, WhatsApp, CREF e biografia quando disponíveis. A edição de perfil (`EditProfileView`) permite atualizar foto/avatar, nome, WhatsApp e área de foco; CREF e biografia são editáveis no perfil de professor. O e-mail é apenas informativo nessa tela.

As opções exibidas respeitam o perfil ativo:

| Perfil | Opções específicas |
|---|---|
| Aluno | Trocar unidade, Mensagens, Feedbacks, Meus professores e Unidade de Medida |
| Professor | Trocar unidade e Unidade de Medida |
| Administrador em perfil de aluno ou professor | Trocar perfil (Admin) e Meus Ícones, além das opções do perfil selecionado |

**Trocar unidade** altera o nome da unidade (academia) salvo no perfil. **Unidade de Medida** alterna entre `kg` e `lbs`, com persistência local e no documento do usuário. As opções Mensagens, Feedbacks e Meus professores exibem indicadores de novidades a partir do estado de notificações salvo por usuário.

### Configurações

`SettingsView` oferece:

- Editar perfil;
- Alterar senha, com reautenticação pela senha atual;
- Excluir conta, com reautenticação, remoção do documento `users/{uid}` e exclusão do usuário no Firebase Authentication;
- Idioma;
- Sobre, Central de ajuda, Política de privacidade e Termos de uso;
- Preview do Progresso.

### Idiomas

O app está disponível em **Português (Brasil)**, **English** e **Español**. Os textos ficam em `Localizable.xcstrings` (idioma base `pt-BR`), e a escolha feita em `LanguageSettingsView` é persistida na chave `selectedAppLanguage` e aplicada ao ambiente SwiftUI por meio de `Locale`. `AppLocalization` e `DefaultWorkoutLocalization` resolvem textos fora das views, incluindo os templates padrão das bibliotecas.

O app não possui seletor de tema claro/escuro; a identidade visual é definida pelas cores e medidas de `Theme`.

---

## Modalidades

As modalidades (`TreinoTipo`) organizam os vínculos entre professores e alunos, as bibliotecas, os templates, os vídeos e os treinos enviados:

- **Crossfit**
- **Academia**
- **Treinos em Casa**

---

## Área do aluno

`StudentRootView` disponibiliza quatro seções principais:

| Seção | Funcionalidades ativas |
|---|---|
| Home | Avisos de convites, solicitação de vínculo com professor, progresso da semana, check-ins da semana e WOD do dia |
| Treinos | Treinos da Semana, filtros de situação, dias de treino, detalhes, vídeos e conclusão dos dias |
| Recordes | Categorias de Recordes Pessoais, histórico, importação do Tecnofit quando disponível e Meus Vídeos |
| Perfil | Dados da conta, unidade, mensagens, feedbacks, professores vinculados e unidade de medida |

### Home

`StudentDashboardView` apresenta:

- **Avisos**, quando existem convites pendentes de professores;
- **Solicitar vínculo**, quando o aluno ainda não possui professor vinculado, informando o e-mail do professor;
- **Progresso da semana**, com dias concluídos e percentual da semana atual, quando há vínculo ativo;
- **Check-in**, com os dias da semana atual em que há check-in registrado na NextFit;
- **WOD do dia**, com acesso aos detalhes quando a conta NextFit está conectada ou com a opção **Conectar NextFit**.

### Treinos e progresso

Na tela **Treinos da Semana** (`StudentWorkoutsView`), o aluno consulta as semanas recebidas de professores com vínculo ativo, com filtros **Atuais**, **Próximos** e **Concluídos**. Cada semana exibe período, professor e percentual de progresso, e pode ser expandida para listar os dias agrupados por data, com indicação de concluído ou atrasado.

O aluno marca os dias como concluídos nas semanas já iniciadas; a conclusão é gravada no Firestore e o progresso da semana é recalculado a partir dos dias concluídos. Vídeos enviados pelo professor podem ser reproduzidos e salvos em **Meus Vídeos**.

O detalhe do dia (`StudentDayDetailView`) apresenta título, data, descrição, vídeos e blocos do treino. Para o aluno, o card **Cálculo por % do PR (Barbell)** permite escolher um movimento de Barbell e informar um percentual; o app calcula o peso correspondente a partir do recorde salvo pelo aluno e exibe o resultado na unidade de medida preferida.

### WOD do dia (NextFit)

A integração com a NextFit é implementada por `NextFitService`, com a sessão armazenada no Keychain por `NextFitKeychainStore`. O fluxo disponível ao aluno é:

```text
Home
  -> Conectar NextFit (e-mail e senha da NextFit)
  -> WOD do dia
  -> Abas por modalidade com WOD e aba de agenda
  -> Seleção da data
  -> Horários disponíveis
  -> Agendar ou cancelar check-in
```

Na tela `StudentNextFitWodView`, o aluno visualiza as atividades do WOD das modalidades do seu contrato, seleciona a data da agenda (hoje e datas com WOD futuro disponível), consulta horários, ocupação e participantes, realiza check-in com **Agendar** e cancela check-ins com confirmação. Também é possível **Desconectar NextFit**.

Os dados da NextFit são consultados sob demanda e não são persistidos no Firestore, nem convertidos em treinos internos do app.

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

Em cada categoria é possível registrar novos resultados, consultar o histórico com gráfico de progresso, excluir registros do histórico e, quando disponível na categoria, adicionar itens personalizados (como novos movimentos de Barbell).

Os recordes são vinculados ao UID autenticado e sincronizados com uma estrutura própria de Personal Records no Firestore. Alterações locais e remotas são preservadas por merge, inclusive em cenários de dados pendentes e exclusões.

### Importar do Tecnofit

No fluxo de Recorde Pessoal, a primeira importação segue este processo:

```text
Recorde Pessoal
  -> Importar do Tecnofit
  -> Informar credenciais
  -> Buscar recordes
  -> Visualizar resumo
  -> Importar
```

`TecnofitImportService` realiza a consulta e o mapeamento dos dados, e `TecnofitKeychainStore` guarda a sessão no Keychain. Os recordes existentes são preservados; itens compatíveis são importados e itens sem mapeamento são ignorados. A conclusão da primeira importação fica registrada por usuário e, depois de concluída, o botão de importação deixa de ser exibido.

### Meus Vídeos do aluno

Na seção Recordes, **Meus Vídeos** reúne os vídeos do YouTube salvos pelo aluno, com reprodução, edição do título e remoção.

### Professores, mensagens e feedbacks

`StudentTeachersView` lista os professores vinculados, permite desvincular professores, enviar e cancelar solicitações de vínculo e aceitar ou recusar convites recebidos. `StudentMessagesView` e `StudentFeedbacksView` exibem, em modo de leitura, as mensagens e os feedbacks enviados pelos professores.

---

## Área do professor

`TeacherRootView` organiza a experiência do professor em quatro seções:

| Seção | Funcionalidades ativas |
|---|---|
| Home | Resumo de hoje e Acesso rápido personalizável |
| Alunos | Vínculos, filtros por modalidade, convites, solicitações e acompanhamento individual |
| Treinos | Enviar treino, Criar treino, Biblioteca de Treinos, Importar, Meus Recordes e Meus Vídeos |
| Perfil | Dados da conta, unidade e unidade de medida |

### Home

`TeacherDashboardView` exibe o **Resumo de hoje**, com a quantidade de alunos com treino no dia, alunos que concluíram e alunos sem treino. O **Acesso rápido** apresenta três atalhos escolhidos pelo professor entre Enviar treino, Criar treino, Biblioteca de Treinos, Importar, Meus Recordes e Meus Vídeos. Por padrão são exibidos Biblioteca de Treinos, Importar e Meus Vídeos, e a escolha é salva no perfil do professor.

### Alunos e vínculos

O professor pode listar alunos vinculados, pesquisar e filtrar por modalidade, convidar alunos por e-mail, acompanhar e cancelar convites enviados. Também pode analisar solicitações de vínculo, definir uma ou mais categorias ao aceitar, recusar solicitações e alterar a categoria de alunos já vinculados.

No detalhe de um aluno (`TeacherStudentDetailView`), o professor consulta o progresso e a categoria do treino e acessa as ações **Treinos**, **Mensagens**, **Feedbacks**, **Preview do Progresso** e desvincular aluno. Na tela de treinos do aluno, o botão **Publicar Treino** abre o fluxo de envio com o aluno pré-selecionado.

### Treinos do professor

A seção **Treinos** (`TeacherWorkoutsView`) oferece os acessos:

- **Enviar treino** para alunos vinculados;
- **Criar treino**;
- **Biblioteca de Treinos**;
- **Importar** planilhas Excel;
- **Meus Recordes**;
- **Meus Vídeos**.

#### Enviar treino

`TeacherSendWorkoutView` conduz o envio em três etapas:

```text
Enviar treino
  -> 1. Alunos: busca, filtro por modalidade e seleção de um ou mais alunos
  -> 2. Treino: escolha de um template por modalidade (seção e treino)
  -> 3. Dia: semana atual ou próximas semanas
  -> Enviar treino
```

Para cada aluno selecionado, o app localiza ou cria a semana de treino correspondente à data escolhida e grava um dia com os blocos do template. O fluxo também pode ser iniciado com um template, um aluno ou um vídeo pré-selecionado; no envio de vídeo, o dia é criado com o link do YouTube.

#### Criar treino

**Criar treino** permite escolher a modalidade e cadastrar um novo treino com título, descrição e blocos. O treino é salvo como template em **Meus Treinos** da modalidade, e é possível anexar blocos de um template existente da biblioteca.

#### Bibliotecas por modalidade

As bibliotecas ativas são organizadas conforme a modalidade:

| Modalidade | Seções |
|---|---|
| Crossfit | Girls WODs, Hero & Tribute Workouts, Open WODs, WODs Nomeados, Qualifiers / WODs de Competições e Meus Treinos |
| Academia | Peito, Costas, Pernas, Ombros, Braços, Core / Abdômen, Full Body e Meus Treinos |
| Treinos em Casa | Peito, Costas, Pernas, Ombros, Braços, Core / Abdômen, Full Body e Meus Treinos |

Em cada seção, o professor visualiza os templates, edita seus blocos, exclui templates, adiciona novos treinos e envia um template diretamente pelo fluxo **Enviar treino**. `WorkoutTemplateDefaultsSeeder` cadastra uma única vez, por professor e seção, os templates padrão das seções pré-definidas; a seção **Meus Treinos** não recebe templates padrão.

### Importação de treinos por Excel

O fluxo **Importar** permite baixar e compartilhar o modelo de planilha Excel incluído no app, selecionar um arquivo `.xlsx` e ler seus treinos a partir da aba `IMPORT_TREINOS`. Os itens importados podem ser visualizados, editados, removidos e enviados com **Enviar para Treinos**, que os converte em templates na seção **Meus Treinos** da modalidade escolhida. A partir daí, eles podem ser enviados aos alunos pelo fluxo **Enviar treino**.

### Meus Recordes

**Meus Recordes** reutiliza as categorias de Recordes Pessoais no contexto do professor, com os registros vinculados ao UID do próprio professor.

### Meus Vídeos

O professor pode cadastrar links do YouTube com título e modalidade, reproduzir os vídeos salvos, editar o título, removê-los e enviá-los para alunos pelo fluxo **Enviar treino**. A reprodução usa WebView e inclui suporte a AirPlay.

---

## Administração

`AdminProfileSelectionView` permite que o administrador escolha entre **Perfil Administrador**, **Perfil Aluno** e **Perfil Professor**. A escolha pode ser alterada posteriormente pela tela de Perfil ou pelo atalho da tela de usuários.

Na mesma tela, a opção **Código de autorização de professores** abre `TeacherAuthorizationCodeView`, que exibe e copia o código vigente e permite gerar um novo código mediante confirmação.

No perfil de administrador, `AdminUsersView` lista usuários, permite filtrar todos, alunos e professores e consultar os dados disponíveis de cada perfil, incluindo vínculos e treinos relacionados. A exclusão de usuários pelo administrador ainda não está disponível e exibe um aviso informativo.

---

## Persistência e Firestore

`FirestoreRepository` centraliza a interface usada pelas telas e delega operações aos repositórios especializados.

| Repositório | Responsabilidade |
|---|---|
| `UserRepository` | Perfis, vínculos, convites, solicitações, unidade, preferências e acesso rápido do professor |
| `TrainingRepository` | Semanas, dias, publicação, envio de treinos e resolução da semana por data |
| `ProgressRepository` | Conclusão de dias e progresso de treino |
| `MessageRepository` | Mensagens entre professor e aluno |
| `FeedbackRepository` | Feedbacks destinados ao aluno |
| `WorkoutTemplateRepository` | Templates reutilizáveis de treino |
| `StudentPersonalRecordsRepository` | Armazenamento remoto dos Recordes Pessoais |

Serviços e repositórios complementares:

| Componente | Responsabilidade |
|---|---|
| `TeacherImportedWorkoutsRepository` | Treinos importados por planilha |
| `TeacherYoutubeVideosRepository` | Vídeos do professor e do aluno |
| `AppVersionService` | Configuração de versão mínima do app |
| `TeacherAuthorizationService` | Chamadas às Cloud Functions de autorização de professores |
| `AccountSecurityService` | Alteração de senha e exclusão de conta |
| `NextFitService` | Integração com WOD, agenda e check-in da NextFit |
| `TecnofitImportService` | Importação de recordes do Tecnofit |
| `LocalProfileStore` | Cache local de foto e dados do perfil por usuário |

Os caminhos usados pelos fluxos ativos incluem:

| Caminho | Uso |
|---|---|
| `users` | Perfis, preferências, unidade, unidade de medida e acesso rápido do usuário |
| `users/{uid}/notification_state` | Controle de mensagens, feedbacks e atividades já visualizados |
| `users/{uid}/student_personal_records` | Dados e metadados dos Recordes Pessoais |
| `users/{uid}/youtubeVideos` | Vídeos salvos pelo aluno |
| `teacher_students` | Associações entre professor e alunos |
| `teacher_student_relations` | Relações e categorias de vínculo |
| `teacher_student_invites` | Convites enviados por professores |
| `teacher_student_link_requests` | Solicitações de vínculo iniciadas por alunos |
| `teacher_messages` | Mensagens entre professor e aluno |
| `student_feedbacks` | Feedbacks destinados a alunos |
| `workout_templates` | Templates de treino |
| `training_weeks/{weekId}/days` | Semanas e dias de treino |
| `training_weeks/{weekId}/student_progress` | Progresso do aluno na semana |
| `teachers/{teacherId}/importedWorkouts` | Treinos importados por planilha |
| `teachers/{teacherId}/youtubeVideos` | Vídeos cadastrados pelo professor |
| `app_config/ios` | Versão mínima e mais recente do app |

### Sincronização de Recordes Pessoais

`PersonalRecordsSyncService` sincroniza os registros locais e remotos para o UID autenticado. O serviço vincula o cache ao usuário atual, trata alterações pendentes, evita a exposição de dados de outra conta depois de uma troca de sessão e preserva exclusões e dados concorrentes durante o merge (`PersonalRecordsPayloadMerger`) antes da gravação no Firestore. A sincronização é preparada na abertura do app, executada após o login e após alterações locais, e os dados pendentes são preservados no logout.

### Cloud Functions e regras

A pasta `functions/` contém as Cloud Functions de autorização de cadastro de professores:

| Função | Uso |
|---|---|
| `getTeacherSignupCode` | Consulta do código vigente pelo administrador |
| `rotateTeacherSignupCode` | Geração de um novo código pelo administrador |
| `validateTeacherSignupCode` | Validação do código informado no cadastro, com limite de tentativas |
| `createTeacherAccount` | Criação da conta e do perfil do professor a partir de uma autorização válida |

Os documentos de controle dessa autorização (`teacher_signup_config`, `teacher_signup_tickets` e `teacher_signup_attempts`) são acessados apenas pelas Cloud Functions. O arquivo `firebase/firestore-teacher-authorization.rules` contém o trecho de regras do Firestore para essas coleções, e `firebase/TEACHER_AUTHORIZATION.md` descreve a configuração e a publicação. O repositório não versiona o conjunto completo de regras nem índices do Firestore.

---

## Componentes compartilhados

Os componentes reutilizados pelos fluxos ativos incluem:

- `FooterBar` e `HeaderBar` para navegação e cabeçalhos;
- `HeaderAvatarView` e `MiniProfileHeader` para apresentação do perfil;
- `PhoneTextField` e `UnderlineTextField` para campos de formulário;
- `BlockDraft` para montagem de blocos de treino;
- `WorkoutTemplateAttachment` para anexar blocos de templates existentes;
- `WeightUnitSheetView` para escolha da unidade de medida;
- `PrimaryGreenActionButton` para os botões de ação principais;
- `Theme` para cores, tipografia e medidas compartilhadas.

### Recursos experimentais

O projeto também contém módulos que não fazem parte dos fluxos ativos ou que funcionam apenas como demonstração:

- **Preview do Progresso** (`SpriteDemoView` e `Features/Gamification`) é acessível pelas Configurações e pelo detalhe do aluno, como uma prévia visual em SpriteKit com métricas de demonstração;
- `Features/AR`, `Features/Map`, `Features/CoreData`, `Features/Home` e as telas `TreinosView` e `CrossfitMenuView` permanecem no código, mas não são acessíveis pela navegação atual.

---

## Estrutura geral do app

```text
rdvperfomance/
├── About/
│   └── Views/
├── App/
│   ├── AppRouter.swift
│   ├── AppRoute.swift
│   ├── AppSession.swift
│   ├── AppUpdateGateView.swift
│   ├── ForceUpdateView.swift
│   ├── TeacherRootView.swift
│   └── rdvperfomanceApp.swift
├── Features/
│   ├── Admin/
│   ├── AR/
│   ├── Auth/
│   ├── CoreData/
│   ├── Gamification/
│   ├── Home/
│   ├── Map/
│   ├── Settings/
│   ├── Sprites/
│   ├── Student/
│   │   ├── Models/
│   │   ├── Navigation/
│   │   ├── PersonalRecords/
│   │   ├── ViewModels/
│   │   └── Views/
│   ├── Teacher/
│   │   ├── ImportVideos/
│   │   ├── ImportWorkouts/
│   │   ├── ViewModels/
│   │   └── Views/
│   └── Treinos/
│       ├── Models/
│       └── Views/
├── Resources/
│   ├── Assets.xcassets/
│   └── Templates/
├── Shared/
│   ├── Components/
│   ├── Extensions/
│   ├── Navigation/
│   ├── Services/
│   │   ├── Firestore/
│   │   ├── NextFit/
│   │   └── Tecnofit/
│   ├── UI/
│   └── Utilities/
├── GoogleService-Info.plist
└── Localizable.xcstrings

functions/
├── index.js
└── package.json

firebase/
├── firestore-teacher-authorization.rules
└── TEACHER_AUTHORIZATION.md
```

---

## Build e execução

1. Abra `rdvperfomance.xcodeproj` em uma versão do Xcode compatível com o deployment target do app (iOS 26.0, iPhone).
2. Aguarde a resolução dos pacotes Swift (`firebase-ios-sdk` e `CoreXLSX`).
3. Configure um `GoogleService-Info.plist` válido para o ambiente de desenvolvimento.
4. Para o cadastro de professores, publique as Cloud Functions de `functions/` e aplique as regras descritas em `firebase/TEACHER_AUTHORIZATION.md`.
5. Execute o scheme `rdvperfomance` em simulador ou dispositivo iOS.

