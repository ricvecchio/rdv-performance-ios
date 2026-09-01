# 📱 RDV Perfomance – App Mobile iOS (SwiftUI)

O **RDV Perfomance** é um aplicativo iOS para gestão e acompanhamento de treinos. A aplicação oferece experiências específicas para alunos e professores, com modalidades de Crossfit, Academia e Treinos em Casa.

---

## 🚀 Tecnologias Utilizadas

- Swift e SwiftUI
- Firebase Authentication e Cloud Firestore
- PhotosUI e UIKit para seleção e tratamento de foto de perfil
- CoreData e UserDefaults para persistência local
- MapKit e CoreLocation para recursos de mapa e localização
- ARKit, RealityKit e CoreMotion para recursos de realidade aumentada
- SpriteKit para gamificação
- CoreXLSX para importação de planilhas Excel
- WebKit, AVFoundation e AVKit para vídeos do YouTube
- Combine, `NavigationStack`, `AppStorage` e SF Symbols

---

## 🧭 Estrutura de Navegação

`AppRouter` controla o fluxo de autenticação e as rotas declaradas em `AppRoute`. Após a autenticação, `AppSession` identifica o tipo de usuário e direciona o fluxo para `StudentRootView` ou `TeacherRootView`.

- **Aluno:** agenda, records pessoais e perfil.
- **Professor:** dashboard, alunos, bibliotecas de treino e perfil.

As seções principais usam `MainSectionNavigation`, enquanto cada fluxo mantém sua própria pilha de navegação.

---

## 🔐 Autenticação, Sessão e Perfil

O aplicativo possui login, cadastro de aluno e cadastro de professor com Firebase Authentication. `AppSession` observa o estado de autenticação, carrega o perfil em Firestore e mantém os dados essenciais da sessão.

### 👤 Perfil

`ProfileView` apresenta informações do perfil e atalhos para configurações, mensagens, feedbacks, professores vinculados e ícones. Para alunos, os atalhos de Mensagens, Feedbacks e Meus professores exibem indicadores locais de atividades ainda não visualizadas.

`EditProfileView` permite atualizar:

- foto de perfil ou Avatar local;
- WhatsApp;
- área de foco;
- CREF e biografia para professores.

O Avatar e a foto da biblioteca seguem o mesmo pipeline: `UIImage`, processamento JPEG, Base64 e persistência em `photoBase64`. A foto é sincronizada com Firestore e armazenada em cache por usuário em `LocalProfileStore`; após o login, a foto remota também restaura esse cache quando necessário. `HeaderAvatarView` reage às notificações do cache, sem consultar Firestore individualmente.

### ⚙️ Configurações

O módulo de configurações inclui edição de perfil, troca de senha, exclusão de conta e informações legais. A exclusão exige senha atual e a confirmação textual `EXCLUIR`.

---

## 🏋️ Modalidades

As modalidades suportadas por `TreinoTipo` são:

- **Crossfit**
- **Academia**
- **Treinos em Casa**

As modalidades organizam bibliotecas, templates, vínculos e a apresentação de treinos.

---

## 🎓 Área do Aluno

### 📅 Agenda, treinos e progresso

- agenda semanal de treinos;
- detalhes de semana e de dia;
- visualização de treinos recebidos;
- acompanhamento de progresso;
- gamificação com métricas, badges e cenas SpriteKit.

### 💬 Comunicação e vínculos

- mensagens enviadas por professores;
- feedbacks recebidos;
- visualização de professores vinculados;
- recebimento e aceite de convites;
- solicitação de vínculo com professor.

### 🏅 Records e recursos adicionais

O módulo de records pessoais possui categorias para barra, ginástica, endurance, notáveis, Girls, Heroes, Open, campeonatos e CrossFit Games. O projeto também inclui recursos de mapa, demonstração de mapa, AR para exercícios e visualização de vídeos.

---

## 👨‍🏫 Área do Professor

### 👥 Alunos e vínculos

O professor pode:

- visualizar alunos vinculados e filtrar por modalidade;
- enviar convites por e-mail;
- cancelar convites enviados;
- receber solicitações de vínculo iniciadas por alunos;
- aceitar uma solicitação escolhendo a categoria do vínculo;
- recusar uma solicitação sem criar vínculo;
- desvincular alunos;
- acessar detalhes do aluno, mensagens e feedbacks.

### 📝 Treinos, WODs e templates

O professor cria semanas e dias de treino, envia treinos para alunos e administra templates reutilizáveis. As bibliotecas incluem WODs, benchmarks, Girls, Heroes/Tributes, Opens, Qualifiers/Competições e treinos nomeados, além de treinos para Academia e Treinos em Casa.

Os defaults de templates são semeados quando necessário, sem bloquear o carregamento inicial da lista.

### 📊 Importação de treinos

O módulo `ImportWorkouts` importa planilhas Excel por `DocumentPicker`, usando o template `rdv_import_treinos_template_pt_crossfit.xlsx`. Os treinos importados podem ser visualizados, editados, excluídos e enviados para alunos.

### 📹 Importação de vídeos

O módulo `ImportVideos` permite cadastrar vídeos do YouTube, organizá-los por modalidade, reproduzi-los em player WebView com suporte a AirPlay e enviá-los para alunos.

---

## 🗃️ Persistência e Firestore

`FirestoreRepository` centraliza a interface de dados e delega operações aos repositórios especializados:

| Repositório | Responsabilidade |
|---|---|
| `UserRepository` | usuários, vínculos, convites e solicitações |
| `TrainingRepository` | semanas, dias e envio de treinos |
| `ProgressRepository` | progresso de treinos |
| `MessageRepository` | mensagens entre professor e aluno |
| `FeedbackRepository` | feedbacks de alunos |
| `WorkoutTemplateRepository` | templates de treino |

Collections e subcollections relevantes:

| Caminho | Uso |
|---|---|
| `users` | perfis de aluno e professor |
| `teacher_students` | alunos associados ao professor |
| `teacher_student_relations` | relações e categorias de vínculo |
| `teacher_student_invites` | convites enviados pelo professor |
| `teacher_student_link_requests` | solicitações de vínculo iniciadas pelo aluno |
| `teacher_messages` | mensagens para alunos |
| `student_feedbacks` | feedbacks de alunos |
| `workout_templates` | templates e WODs reutilizáveis |
| `training_weeks/{weekId}/days` | semanas e dias de treino |
| `training_weeks/{weekId}/student_progress` | progresso por aluno |
| `teachers/{teacherId}/importedWorkouts` | treinos importados |
| `teachers/{teacherId}/youtubeVideos` | vídeos importados |

`LocalProfileStore` usa `UserDefaults` com chaves por usuário para cache de foto, WhatsApp, área de foco e preferências locais relacionadas ao mapa. CoreData mantém as atividades locais do aplicativo.

---

## 🧩 Componentes Compartilhados

- `FooterBar` e `HeaderBar` padronizam a navegação visual.
- `HeaderAvatarView` e `MiniProfileHeader` exibem a foto de perfil em cache.
- `PhoneTextField` aplica a máscara brasileira e limita o número a 11 dígitos.
- `UnderlineTextField` fornece campos com linha inferior e suporte a senha.
- `BlockDraft` é usado na montagem de blocos de treino.
- `Theme` centraliza cores, fontes e medidas compartilhadas.

---

## 🗂 Estrutura Geral do App

```text
rdvperformance-ios/
├── rdvperfomance.xcodeproj/
└── rdvperfomance/
    ├── App/
    │   ├── AppRouter.swift
    │   ├── AppRoute.swift
    │   ├── AppSession.swift
    │   ├── StudentRootView.swift
    │   └── TeacherRootView.swift
    ├── About/
    ├── Features/
    │   ├── AR/
    │   ├── Auth/
    │   │   ├── Models/
    │   │   ├── Services/
    │   │   ├── ViewModels/
    │   │   └── Views/
    │   ├── CoreData/
    │   ├── Gamification/
    │   ├── Home/
    │   ├── Map/
    │   ├── Settings/
    │   ├── Sprites/
    │   ├── Student/
    │   │   ├── Models/
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
    └── Shared/
        ├── Components/
        ├── Extensions/
        ├── Navigation/
        ├── Services/
        │   └── Firestore/
        │       ├── Base/
        │       ├── Communication/
        │       ├── Templates/
        │       ├── Training/
        │       └── Users/
        ├── UI/
        └── Utilities/
```

---

## 🔧 Build / Execução

1. Abra `rdvperfomance.xcodeproj` no Xcode compatível com o deployment target configurado no projeto.
2. Configure um `GoogleService-Info.plist` válido para o ambiente de desenvolvimento.
3. Execute em simulador ou dispositivo com as permissões necessárias para os recursos utilizados.

---

## 🎯 Destaques do Projeto

- navegação por rotas e sessão autenticada;
- experiências distintas para aluno e professor;
- gestão de treinos, WODs, templates e vínculos;
- mensagens, feedbacks e indicadores locais de atividades;
- importação de treinos Excel e vídeos do YouTube;
- persistência local e sincronização com Cloud Firestore;
- recursos de mapa, AR, records pessoais e gamificação.
