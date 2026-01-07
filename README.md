# 📱 RDV Perfomance – App Mobile iOS (SwiftUI)

O **RDV Perfomance** é um aplicativo mobile iOS desenvolvido em **SwiftUI**, voltado para **personal trainers e profissionais de atividade física**, com o objetivo de facilitar o gerenciamento e a visualização de treinos personalizados para alunos.

O app possui uma navegação simples, interface moderna e layout responsivo, com foco em **experiência do usuário**, **clareza visual** e **arquitetura limpa**.

---

## 🚀 Tecnologias Utilizadas

- SwiftUI
- NavigationStack
- AppStorage
- SF Symbols
- Arquitetura declarativa
- iOS 16+
- Firebase (configuração parcial via `GoogleService-Info.plist` – serviços de autenticação / Firestore presentes como referência)

---

## 🧭 Estrutura de Navegação

A navegação do app é centralizada através de um `NavigationStack`, controlada por um conjunto de rotas (`[AppRoute]`) e orquestrada em `AppRouter`. Isso garante navegação previsível entre telas como Login, Home, Treinos e Sobre.

### Rotas principais
- Login
- Home
- Treinos (Crossfit, Academia, Em Casa)
- Sobre
- Perfil / Settings

---

## 🔐 Tela de Login

- Tela inicial do aplicativo
- Campos de e-mail e senha
- Opção de mostrar/ocultar senha
- Validação básica (campos não vazios)
- Após validação, navega para a Home

> Observação: o projeto contém uma camada de autenticação (FirebaseAuthService) — dependendo da configuração do `GoogleService-Info.plist`, a autenticação pode ser habilitada; por padrão aqui está preparada apenas como referência.

---

## 🏠 Tela Home

Apresenta três opções principais de treino:

- Crossfit
- Academia
- Treinos em Casa

Cada opção possui imagem personalizada, título sobreposto e área totalmente clicável. O rodapé exibe navegação principal (Home, Treinos/Atual, Sobre).

---

## 🏋️ Tipos de Treino

Os tipos de treino são controlados por um enum central (`TreinoTipo`), responsável por:

- Título da tela
- Texto sobreposto na imagem
- Imagem principal
- Ícone personalizado no rodapé

Tipos disponíveis:
- Crossfit
- Academia
- Treinos em Casa

---

## 📊 Tela de Treinos

Tela reutilizável e dinâmica conforme o tipo de treino selecionado. Componentes chave:
- Header com título do treino
- Imagem central personalizada
- Texto sobreposto
- Rodapé com Home / Treino atual / Sobre

---

## ℹ️ Tela Sobre

Tela institucional do aplicativo contendo:
- Logo do app
- Texto explicativo
- Lista de funcionalidades
- Layout em card centralizado
- Header com botão Voltar
- Rodapé com Home e Sobre

---

## 🧩 Componentes Reutilizáveis

Alguns componentes compartilhados:
- `UnderlineTextField` — campo customizado com linha inferior e suporte a senha (mostrar/ocultar)
- `HeaderBar`, `FooterBar` — cabeçalho e rodapé usados em várias telas
- `MiniProfileHeader`, `HeaderAvatarView` — cabeçalhos específicos de perfis
- `Theme` — definições visuais centrais

---

## 🗂 Estrutura Geral do App 

```
rdvperformance-ios
├─ rdvperfomance.xcodeproj/
└─ rdvperfomance/
   ├─ About/
   │  └─ Views/
   │     └─ AboutView.swift
   ├─ App/
   │  ├─ rdvperfomanceApp.swift
   │  ├─ AppSession.swift
   │  ├─ AppRouter.swift
   │  └─ AppRoute.swift
   ├─ Features/
   │  ├─ Auth/
   │  │  ├─ Models/
   │  │  │  └─ AuthDTOs.swift
   │  │  ├─ Services/
   │  │  │  └─ FirebaseAuthService.swift
   │  │  ├─ ViewModels/
   │  │  │  ├─ LoginViewModel.swift
   │  │  │  └─ RegisterViewModel.swift
   │  │  └─ Views/
   │  │     ├─ AccountTypeSelectionView.swift
   │  │     ├─ EditProfileView.swift
   │  │     ├─ LoginView.swift
   │  │     ├─ ProfileView.swift
   │  │     ├─ RegisterStudentView.swift
   │  │     └─ RegisterTrainerView.swift
   │  ├─ Home/
   │  │  └─ Views/
   │  │     └─ HomeView.swift
   │  ├─ Settings/
   │  │  └─ Views/
   │  │     ├─ AccountSecurityService.swift
   │  │     ├─ ChangePasswordView.swift
   │  │     ├─ DeleteAccountView.swift
   │  │     ├─ InfoLegalView.swift
   │  │     └─ SettingsView.swift
   │  ├─ Student/
   │  │  ├─ Models/
   │  │  │  ├─ TrainingDayFS.swift
   │  │  │  ├─ TrainingFS.swift
   │  │  │  └─ TrainingWeekFS.swift
   │  │  ├─ ViewModels/
   │  │  │  ├─ StudentAgendaViewModel.swift
   │  │  │  └─ StudentWeekDetailViewModel.swift
   │  │  └─ Views/
   │  │     ├─ StudentAgendaView.swift
   │  │     ├─ StudentDayDetailView.swift
   │  │     ├─ StudentFeedbacksView.swift
   │  │     ├─ StudentMessagesView.swift
   │  │     └─ StudentWeekDetailView.swift
   │  ├─ Teacher/
   │  │  ├─ ViewModels/
   │  │  │  ├─ CreateTrainingWeekViewModel.swift
   │  │  │  └─ TeacherStudentsListViewModel.swift
   │  │  └─ Views/
   │  │     ├─ CreateTrainingWeekView.swift
   │  │     ├─ TeacherDashboardView.swift
   │  │     ├─ TeacherFeedbacksView.swift
   │  │     ├─ TeacherLinkStudentView.swift
   │  │     ├─ TeacherSendMessageView.swift
   │  │     ├─ TeacherStudentDetailView.swift
   │  │     └─ TeacherStudentsListView.swift
   │  └─ Treinos/
   │     ├─ Models/
   │     │  ├─ FirestoreModels.swift
   │     │  ├─ StudentFeedbackFS.swift
   │     │  ├─ TeacherMessageFS.swift
   │     │  └─ TreinoTipo.swift
   │     └─ Views/
   │        ├─ CreateTrainingDayView.swift
   │        ├─ CrossfitMenuView.swift
   │        └─ TreinosView.swift
   ├─ Shared/
   │  ├─ Components/
   │  │  ├─ FooterBar.swift
   │  │  ├─ HeaderAvatarView.swift
   │  │  ├─ HeaderBar.swift
   │  │  ├─ MiniProfileHeader.swift
   │  │  └─ UnderlineTextField.swift
   │  ├─ Services/
   │  │  ├─ FirestoreRepository.swift
   │  │  └─ LocalProfileStore.swift
   │  └─ UI/
   │     └─ Theme.swift
   ├─ Resources/
   │  └─ Assets.xcassets/
   │     ├─ AccentColor.colorset/
   │     ├─ AppIcon.appiconset/
   │     ├─ Default.colorset/
   │     ├─ rdv_crossfit_benchmark_horizontal.imageset/
   │     ├─ rdv_crossfit_meusrecordes_horizontal.imageset/
   │     ├─ rdv_crossfit_monteseutreino_horizontal.imageset/
   │     ├─ rdv_crossfit_progressos_horizontal.imageset/
   │     ├─ rdv_crossfit_wod_horizontal.imageset/
   │     ├─ rdv_fundo.imageset/
   │     ├─ rdv_logo.imageset/
   │     ├─ rdv_programa_academia_horizontal.imageset/
   │     ├─ rdv_programa_crossfit_horizontal.imageset/
   │     ├─ rdv_programa_treinos_em_casa_horizontal.imageset/
   │     ├─ rdv_treino1_vertical.imageset/
   │     ├─ rdv_treino2_vertical.imageset/
   │     ├─ rdv_treino3_vertical.imageset/
   │     └─ rdv_user_default.imageset/
   ├─ GoogleService-Info.plist
   └─ README.md
```

---

## 📋 Mapa de Telas e Dependências (detalhado)

Abaixo um mapeamento por tela/módulo com os arquivos principais usados (Views) e os arquivos relacionados (ViewModels, Models, Services, Componentes compartilhados).

### Auth
- Views:
  - `Features/Auth/Views/LoginView.swift`
  - `Features/Auth/Views/RegisterStudentView.swift`
  - `Features/Auth/Views/RegisterTrainerView.swift`
  - `Features/Auth/Views/AccountTypeSelectionView.swift`
  - `Features/Auth/Views/ProfileView.swift`
  - `Features/Auth/Views/EditProfileView.swift`
- ViewModels:
  - `Features/Auth/ViewModels/LoginViewModel.swift`
  - `Features/Auth/ViewModels/RegisterViewModel.swift`
- Models:
  - `Features/Auth/Models/AuthDTOs.swift`
- Services:
  - `Features/Auth/Services/FirebaseAuthService.swift`
- Componentes compartilhados:
  - `Shared/Components/UnderlineTextField.swift`
  - `Shared/Components/MiniProfileHeader.swift`

---

### Home
- View:
  - `Features/Home/Views/HomeView.swift`
- Relacionados:
  - `Features/Treinos/Models/TreinoTipo.swift`
  - `App/AppRoute.swift`, `App/AppRouter.swift`
  - `Shared/Components/FooterBar.swift`

---

### Settings
- Views:
  - `Features/Settings/Views/SettingsView.swift`
  - `Features/Settings/Views/ChangePasswordView.swift`
  - `Features/Settings/Views/DeleteAccountView.swift`
  - `Features/Settings/Views/InfoLegalView.swift`
- Services/Helpers:
  - `Features/Settings/Views/AccountSecurityService.swift` (serviço ligado a mudanças de senha / segurança)

---

### Student (Aluno)
- Views:
  - `Features/Student/Views/StudentAgendaView.swift`
  - `Features/Student/Views/StudentDayDetailView.swift`
  - `Features/Student/Views/StudentFeedbacksView.swift`
  - `Features/Student/Views/StudentMessagesView.swift`
  - `Features/Student/Views/StudentWeekDetailView.swift`
- ViewModels:
  - `Features/Student/ViewModels/StudentAgendaViewModel.swift`
  - `Features/Student/ViewModels/StudentWeekDetailViewModel.swift`
- Models:
  - `Features/Student/Models/TrainingDayFS.swift`
  - `Features/Student/Models/TrainingFS.swift`
  - `Features/Student/Models/TrainingWeekFS.swift`

---

### Teacher (Professor)
- Views:
  - `Features/Teacher/Views/TeacherStudentsListView.swift`
  - `Features/Teacher/Views/TeacherStudentDetailView.swift`
  - `Features/Teacher/Views/TeacherDashboardView.swift`
  - `Features/Teacher/Views/CreateTrainingWeekView.swift`
  - `Features/Teacher/Views/TeacherFeedbacksView.swift`
  - `Features/Teacher/Views/TeacherSendMessageView.swift`
  - `Features/Teacher/Views/TeacherLinkStudentView.swift`
- ViewModels:
  - `Features/Teacher/ViewModels/TeacherStudentsListViewModel.swift`
  - `Features/Teacher/ViewModels/CreateTrainingWeekViewModel.swift`

---

### Treinos
- Views:
  - `Features/Treinos/Views/TreinosView.swift`
  - `Features/Treinos/Views/CrossfitMenuView.swift`
  - `Features/Treinos/Views/CreateTrainingDayView.swift`
- Models:
  - `Features/Treinos/Models/TreinoTipo.swift`
  - `Features/Treinos/Models/FirestoreModels.swift`
  - `Features/Treinos/Models/StudentFeedbackFS.swift`
  - `Features/Treinos/Models/TeacherMessageFS.swift`

---

### Shared
- Componentes:
  - `Shared/Components/HeaderBar.swift`
  - `Shared/Components/HeaderAvatarView.swift`
  - `Shared/Components/FooterBar.swift`
  - `Shared/Components/MiniProfileHeader.swift`
  - `Shared/Components/UnderlineTextField.swift`
- Services:
  - `Shared/Services/FirestoreRepository.swift`
  - `Shared/Services/LocalProfileStore.swift`
- UI:
  - `Shared/UI/Theme.swift`

---

## 🖼️ Recursos / Assets

Os assets do projeto ficam em `Resources/Assets.xcassets`. Resumo dos assets incluídos (cada `.imageset` contém as imagens usadas nas telas):

- `AccentColor.colorset`
- `AppIcon.appiconset`
- `Default.colorset`
- `rdv_crossfit_benchmark_horizontal.imageset`
- `rdv_crossfit_meusrecordes_horizontal.imageset`
- `rdv_crossfit_monteseutreino_horizontal.imageset`
- `rdv_crossfit_progressos_horizontal.imageset`
- `rdv_crossfit_wod_horizontal.imageset`
- `rdv_fundo.imageset`
- `rdv_logo.imageset`
- `rdv_programa_academia_horizontal.imageset`
- `rdv_programa_crossfit_horizontal.imageset`
- `rdv_programa_treinos_em_casa_horizontal.imageset`
- `rdv_treino1_vertical.imageset`
- `rdv_treino2_vertical.imageset`
- `rdv_treino3_vertical.imageset`
- `rdv_user_default.imageset`

(Se desejar, posso gerar uma listagem completa dos arquivos dentro de cada `.imageset` — por padrão deixei como resumo para manter o README enxuto.)

---

## 🔧 Build / Execução (notas rápidas)

- Abra o workspace `rdvperfomance.xcodeproj` no Xcode 14+ / Xcode compatível com iOS 16.
- Configure o `GoogleService-Info.plist` caso queira habilitar Firebase (Auth/Firestore) em ambiente de desenvolvimento.
- Execute o app em um simulador iOS 16+ ou dispositivo físico com as permissões necessárias.

### Permissão de localização (necessária para o demo de Mapa)

Para que a opção "Mapa (demo)" funcione corretamente você precisa adicionar a chave de privacidade no `Info.plist` do target do app. Abra o arquivo `Info.plist` no Xcode e adicione a chave abaixo (valor em português ou conforme sua política de privacidade):

- `NSLocationWhenInUseUsageDescription` = "Usamos sua localização para centrar o mapa e mostrar a posição da academia (demo)."

> Observação: não alterei o `Info.plist` automaticamente para evitar mudanças no projeto que você prefere controlar pelo Xcode; a adição manual é simples e segura.

---

## 🎯 Destaques do Projeto

- Navegação centralizada por rotas (`AppRoute` / `AppRouter`)
- Componentes reutilizáveis e layout responsivo
- Integração básica com Firebase preparada (services/Firestore)
- Organização por features (Auth, Home, Student, Teacher, Treinos)

---

## 📌 Próximos Passos 

- Completar integração com backend (Firebase) e testar autenticação real
- Adicionar testes unitários / UI tests
- Documentar contratos de rede e modelos Firestore
- Internacionalização (strings em Localizable)
- Melhorar cobertura de assets e imagens de alta resolução
- Funções para importar planilhas em Excel
- Lista com exercícios pré-definidos para montagem rápida de treinos

---

## 👨‍💻 Projeto focado em boas práticas

Este app foi desenvolvido com foco em clareza, organização e escalabilidade, servindo como base para evolução futura ou portfólio profissional.
