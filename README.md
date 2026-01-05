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

---

## 🧭 Estrutura de Navegação

A navegação do app é centralizada através de um `NavigationStack`, controlado por um array de rotas (`[AppRoute]`), garantindo navegação segura e previsível.

### Rotas disponíveis
- Login
- Home
- Sobre
- Treinos (Crossfit, Academia, Em Casa)

---

## 🔐 Tela de Login

- Tela inicial do aplicativo
- Campos de e-mail e senha
- Opção de mostrar/ocultar senha
- Validação básica (campos não vazios)
- Após validação, navega para a Home

> Observação: autenticação apenas demonstrativa, sem backend.

---

## 🏠 Tela Home

Apresenta três opções principais de treino:

- Crossfit  
- Academia  
- Treinos em Casa  

Cada opção possui imagem personalizada, título sobreposto e área totalmente clicável.

O rodapé exibe apenas:
- Home (selecionado)
- Sobre

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

Tela reutilizável e dinâmica conforme o tipo de treino selecionado.

Características:
- Header com título do treino
- Imagem central personalizada
- Texto sobreposto
- Rodapé com:
  - Home
  - Treino atual (ícone personalizado)
  - Sobre

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

### UnderlineTextField
Campo customizado com:
- Linha inferior
- Placeholder estilizado
- Suporte a senha segura
- Botão para mostrar/ocultar senha

Utilizado na tela de login.

---

## 🗂 Estrutura Geral do App

```
rdvperformance-ios
├─ rdvperfomance.xcodeproj
└─ rdvperfomance
   ├─ About
   │  └─ Views
   │     └─ AboutView.swift
   ├─ App
   │  ├─ rdvperfomanceApp.swift
   │  ├─ AppSession.swift
   │  ├─ AppRouter.swift
   │  └─ AppRoute.swift
   ├─ Features
   │  ├─ Auth
   │  │  ├─ Models
   │  │  │  └─ AuthDTOs.swift
   │  │  ├─ Services
   │  │  │  └─ FirebaseAuthService.swift
   │  │  ├─ ViewModels
   │  │  │  ├─ LoginViewModel.swift
   │  │  │  └─ RegisterViewModel.swift
   │  │  └─ Views
   │  │     ├─ AccountTypeSelectionView.swift
   │  │     ├─ EditProfileView.swift
   │  │     ├─ LoginView.swift
   │  │     ├─ ProfileView.swift
   │  │     ├─ RegisterStudentView.swift
   │  │     └─ RegisterTrainerView.swift
   │  ├─ Home
   │  │  └─ Views
   │  │     └─ HomeView.swift
   │  ├─ Settings
   │  │  └─ Views
   │  │     ├─ AccountSecurityService.swift
   │  │     ├─ ChangePasswordView.swift
   │  │     ├─ DeleteAccountView.swift
   │  │     ├─ InfoLegalView.swift
   │  │     └─ SettingsView.swift
   │  ├─ Student
   │  │  ├─ Models
   │  │  │  ├─ TrainingDayFS.swift
   │  │  │  ├─ TrainingFS.swift
   │  │  │  └─ TrainingWeekFS.swift
   │  │  ├─ ViewModels
   │  │  │  ├─ StudentAgendaViewModel.swift
   │  │  │  └─ StudentWeekDetailViewModel.swift
   │  │  └─ Views
   │  │     ├─ StudentAgendaView.swift
   │  │     ├─ StudentDayDetailView.swift
   │  │     ├─ StudentFeedbacksView.swift
   │  │     ├─ StudentMessagesView.swift
   │  │     └─ StudentWeekDetailView.swift
   │  ├─ Teacher
   │  │  ├─ ViewModels
   │  │  │  ├─ CreateTrainingWeekViewModel.swift
   │  │  │  └─ TeacherStudentsListViewModel.swift
   │  │  └─ Views
   │  │     ├─ CreateTrainingWeekView.swift
   │  │     ├─ TeacherDashboardView.swift
   │  │     ├─ TeacherFeedbacksView.swift
   │  │     ├─ TeacherLinkStudentView.swift
   │  │     ├─ TeacherSendMessageView.swift
   │  │     ├─ TeacherStudentDetailView.swift
   │  │     └─ TeacherStudentsListView.swift
   │  └─ Treinos
   │     ├─ Models
   │     │  ├─ FirestoreModels.swift
   │     │  ├─ StudentFeedbackFS.swift
   │     │  ├─ TeacherMessageFS.swift
   │     │  └─ TreinoTipo.swift
   │     └─ Views
   │        ├─ CreateTrainingDayView.swift
   │        ├─ CrossfitMenuView.swift
   │        └─ TreinosView.swift
   ├─ Shared
   │  ├─ Components
   │  │  ├─ FooterBar.swift
   │  │  ├─ HeaderAvatarView.swift
   │  │  ├─ HeaderBar.swift
   │  │  ├─ MiniProfileHeader.swift
   │  │  └─ UnderlineTextField.swift
   │  ├─ Services
   │  │  ├─ FirestoreRepository.swift
   │  │  └─ LocalProfileStore.swift
   │  └─ UI
   │     └─ Theme.swift
   ├─ GoogleService-Info.plist
   └─ README.md
```

---
## 📋 Mapa de Telas e Dependências

Este documento fornece um mapeamento completo das telas do aplicativo RDV Performance e seus arquivos relacionados. Use-o como guia para entender o impacto de alterações no código.

---

### 📊 Relação Completa Telas ↔ Arquivos

| Tela / Módulo                 | Arquivo Principal da View        | ViewModels, Models e Outros Arquivos Relacionados                      | Componentes Compartilhados           |
| ----------------------------- | -------------------------------- | ---------------------------------------------------------------------- | ------------------------------------ |
| **Login**                     | `LoginView.swift`                | `LoginViewModel.swift`, `AuthService.swift`, `AuthDTOs.swift`          | `UnderlineTextField.swift`           |
| **Cadastro (Aluno)**          | `RegisterStudentView.swift`      | `RegisterViewModel.swift`, `AuthService.swift`, `AuthDTOs.swift`       | `UnderlineTextField.swift`           |
| **Cadastro (Professor)**      | `RegisterTrainerView.swift`      | `RegisterViewModel.swift`, `AuthService.swift`, `AuthDTOs.swift`       | `UnderlineTextField.swift`           |
| **Seleção de Conta**          | `AccountTypeSelectionView.swift` | —                                                                      | —                                    |
| **Perfil**                    | `ProfileView.swift`              | `AuthService.swift`, `AuthDTOs.swift`                                  | `MiniProfileHeader.swift`            |
| **Home (Principal)**          | `HomeView.swift`                 | `TreinoTipo.swift` (enum)                                              | `FooterBar.swift`                    |
| **Treinos (Genérica)**        | `TreinosView.swift`              | `TreinoTipo.swift` (enum)                                              | `HeaderBar.swift`, `FooterBar.swift` |
| **Treino – Crossfit**         | `TreinosCrossfitView.swift`      | `TreinoTipo.swift` (enum)                                              | `HeaderBar.swift`, `FooterBar.swift` |
| **Treino – Academia**         | `TreinosAcademiaView.swift`      | `TreinoTipo.swift` (enum)                                              | `HeaderBar.swift`, `FooterBar.swift` |
| **Treino – Em Casa**          | `TreinosEmCasaView.swift`        | `TreinoTipo.swift` (enum)                                              | `HeaderBar.swift`, `FooterBar.swift` |
| **Menu Crossfit**             | `CrossfitMenuView.swift`         | —                                                                      | —                                    |
| **Sobre**                     | `AboutView.swift`                | —                                                                      | `HeaderBar.swift`, `FooterBar.swift` |
| **Configurações**             | `SettingsView.swift`             | —                                                                      | —                                    |
| **Aluno – Agenda**            | `StudentAgendaView.swift`        | `TrainingDay.swift`                                                    | —                                    |
| **Aluno – Detalhe Semana**    | `StudentWeekDetailView.swift`    | `TrainingDay.swift`                                                    | —                                    |
| **Professor – Lista Alunos**  | `TeacherStudentsListView.swift`  | `Student.swift`                                                        | —                                    |
| **Professor – Detalhe Aluno** | `TeacherStudentDetailView.swift` | `Student.swift`                                                        | —                                    |
| **Navegação & App**           | `rdvperformanceApp.swift`        | `AppRouter.swift`, `AppRoute.swift`, `AppSession.swift`, `Theme.swift` | —                                    |
---

# 🔐 AUTH (Login / Cadastro / Perfil)

## 1) Login

### Tela
- `Features/Auth/Views/LoginView.swift`  
  GitHub

### Arquivos relacionados (Auth)
- `Features/Auth/ViewModels/LoginViewModel.swift`  
  GitHub
- `Features/Auth/Services/AuthService.swift`  
  GitHub
- `Features/Auth/Models/AuthDTOs.swift`  
  GitHub

### Dependências globais típicas desta tela
- `AppSession.swift` (estado de login)
- `AppRoute.swift / AppRouter.swift` (navegação pós-login)  
  GitHub

---

## 2) Seleção do tipo de conta

### Tela
- `Features/Auth/Views/AccountTypeSelectionView.swift`  
  GitHub

### Arquivos relacionados
- `Features/Auth/ViewModels/RegisterViewModel.swift`  
  GitHub
- `Features/Auth/Services/AuthService.swift`  
  GitHub
- `Features/Auth/Models/AuthDTOs.swift`  
  GitHub

### Dependências globais
- `AppRoute.swift / AppRouter.swift`  
  GitHub

---

## 3) Cadastro Aluno

### Tela
- `Features/Auth/Views/RegisterStudentView.swift`  
  GitHub

### Arquivos relacionados
- `Features/Auth/ViewModels/RegisterViewModel.swift`  
  GitHub
- `Features/Auth/Services/AuthService.swift`  
  GitHub
- `Features/Auth/Models/AuthDTOs.swift`  
  GitHub

---

## 4) Cadastro Professor / Trainer

### Tela
- `Features/Auth/Views/RegisterTrainerView.swift`  
  GitHub

### Arquivos relacionados
- `Features/Auth/ViewModels/RegisterViewModel.swift`  
  GitHub
- `Features/Auth/Services/AuthService.swift`  
  GitHub
- `Features/Auth/Models/AuthDTOs.swift`  
  GitHub

---

## 5) Perfil

### Tela
- `Features/Auth/Views/ProfileView.swift`  
  GitHub

### Arquivos relacionados (prováveis pelo README)
- `AppSession.swift` (dados do usuário)  
  GitHub
- `Features/Treinos/Models/TreinoTipo.swift` (você mencionou categoria/treino no Profile no histórico)  
  GitHub

---

# 🏠 HOME

## 6) Home

### Tela
- `Features/Home/Views/HomeView.swift`  
  GitHub

### Arquivos relacionados
- `Features/Treinos/Models/TreinoTipo.swift` (tipos de treino)  
  GitHub
- `AppRoute.swift / AppRouter.swift` (ir para Treinos / About etc.)  
  GitHub

---

# ⚙️ SETTINGS

## 7) Settings

### Tela
- `Features/Settings/Views/SettingsView.swift`  
  GitHub

### Arquivos relacionados (mais comuns nesse tipo de tela)
- `AppSession.swift` (logout, limpar sessão, exibir dados)  
  GitHub

---

# ℹ️ ABOUT

## 8) Sobre

### Tela
- `About/Views/AboutView.swift`  
  GitHub

### Arquivos relacionados
- `AppRoute.swift / AppRouter.swift` (voltar / navegar)  
  GitHub

---

# 🏋️ TREINOS

Aqui seu app tem um **“núcleo” de treino + variações por categoria**.

## Arquivos do módulo
- `Features/Treinos/Models/TreinoTipo.swift`  
  GitHub
- `Features/Treinos/Views/TreinosView.swift`  
  GitHub
- `Features/Treinos/Views/TreinosCrossfitView.swift`  
  GitHub
- `Features/Treinos/Views/TreinosAcademiaView.swift`  
  GitHub
- `Features/Treinos/Views/TreinosEmCasaView.swift`  
  GitHub
- `Features/Treinos/Views/CrossfitMenuView.swift`  
  GitHub

## Matriz (telas)
- **Treinos genérico** → `TreinosView.swift` + `TreinoTipo.swift` + router  
  GitHub
- **Crossfit** → `TreinosCrossfitView.swift` + `TreinoTipo.swift` + (possível) `CrossfitMenuView.swift`  
  GitHub
- **Academia** → `TreinosAcademiaView.swift` + `TreinoTipo.swift`  
  GitHub
- **Em Casa** → `TreinosEmCasaView.swift` + `TreinoTipo.swift`  
  GitHub

---

# 👨‍🏫 TEACHER (Lista e detalhe de alunos)

## Arquivos do módulo
- `Features/Teacher/Models/Student.swift`  
  GitHub
- `Features/Teacher/Views/TeacherStudentsListView.swift`  
  GitHub
- `Features/Teacher/Views/TeacherStudentDetailView.swift`  
  GitHub

---

## 9) Lista de alunos (Professor)

### Tela
- `TeacherStudentsListView.swift`  
  GitHub

### Arquivos relacionados
- `Student.swift` (modelo)  
  GitHub
- `TeacherStudentDetailView.swift` (navega para detalhe)  
  GitHub
- (se filtra por treino/categoria) `TreinoTipo.swift`  
  GitHub

---

## 10) Detalhe do aluno

### Tela
- `TeacherStudentDetailView.swift`  
  GitHub

### Arquivos relacionados
- `Student.swift`  
  GitHub

---

## 🎯 Destaques do Projeto

- Navegação centralizada
- Código limpo e organizado
- Layout responsivo
- Reutilização de componentes
- Enum para controle visual e lógico
- Interface moderna e intuitiva

---

## 📌 Próximos Passos

- Integração com backend
- Autenticação real
- Cadastro de alunos
- Persistência de dados
- Evolução de treinos e histórico

---

## 👨‍💻 Projeto focado em boas práticas

Este app foi desenvolvido com foco em clareza, organização e escalabilidade, servindo como base para evolução futura ou portfólio profissional.
