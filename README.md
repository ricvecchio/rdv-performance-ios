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
rdv-performance-ios
├─ rdvperfomance.xcodeproj
└─ rdvperfomance
   │  ├─ About
   │  │  └─ Views
   │  │     └─ AboutView.swift
   ├─ App
   │  ├─ rdvperformanceApp.swift
   │  ├─ AppSession.swift
   │  ├─ AppRouter.swift
   │  └─ AppRoute.swift
   │
   ├─ Features
   │  ├─ Auth
   │  │  ├─ Models
   │  │  │  └─ AuthDTOs.swift
   │  │  ├─ Services
   │  │  │  └─ AuthService.swift
   │  │  ├─ ViewModels
   │  │  │  ├─ LoginViewModel.swift
   │  │  │  └─ RegisterViewModel.swift
   │  │  └─ Views
   │  │     ├─ AccountTypeSelectionView.swift
   │  │     ├─ LoginView.swift
   │  │     ├─ ProfileView.swift
   │  │     ├─ RegisterStudentView.swift
   │  │     └─ RegisterTrainerView.swift
   │  │
   │  ├─ Home
   │  │  └─ Views
   │  │     └─ HomeView.swift
   │  │
   │  ├─ Settings
   │  │  └─ Views
   │  │     └─ SettingsView.swift
   │  │
   │  ├─ Treinos
   │  │  ├─ Models
   │  │  │  └─ TreinoTipo.swift
   │  │  └─ Views
   │  │     ├─ TreinosView.swift
   │  │     ├─ TreinosCrossfitView.swift
   │  │     ├─ TreinosAcademiaView.swift
   │  │     ├─ TreinosEmCasaView.swift
   │  │     └─ CrossfitMenuView.swift
   │  │
   │  ├─ Teacher
   │  │  ├─ Models
   │  │     ├─ MockStudents.swift
   │  │  │  └─ Student.swift
   │  │  └─ Views
   │  │     ├─ TeacherStudentDetailView.swift
   │  │     └─ TeacherStudentsListView.swift
   │  │
   │  └─ Student
   │     ├─ Models
   │     │  ├─ MockWeeks.swift
   │     │  └─ TrainingDay.swift
   │     └─ Views
   │        ├─ StudentAgendaView.swift
   │        └─ StudentWeekDetailView.swift
   │
   ├─ Shared
   │  ├─ Components
   │  │  ├─ FooterBar.swift
   │  │  ├─ HeaderBar.swift
   │  │  ├─ MiniProfileHeader.swift
   │  │  └─ UnderlineTextField.swift
   │  ├─ UI
   │  │  └─ Theme.swift
   │  └─ Extensions
   │     └─ (quando necessário)
   │
   └─ Resources
      └─ Assets.xcassets
```

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
