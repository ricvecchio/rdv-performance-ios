# 📱 RDV Perfomance – App Mobile iOS (SwiftUI)

O **RDV Perfomance** é um aplicativo mobile iOS desenvolvido em **SwiftUI**, voltado para **personal trainers e profissionais de atividade física**, com o objetivo de facilitar o gerenciamento e a visualização de treinos personalizados para alunos.

O app possui uma navegação simples, interface moderna e layout responsivo, com foco em **experiência do usuário**, **clareza visual** e **arquitetura limpa**.

---

## 🚀 Tecnologias Utilizadas

- SwiftUI
- NavigationStack
- AppStorage
- SF Symbols
- ARKit (Realidade Aumentada)
- CoreData (Persistência Local)
- MapKit (Mapas e Localização)
- SpriteKit (Animações e Jogos)
- Arquitetura declarativa
- iOS 16+
- Firebase (configuração parcial via `GoogleService-Info.plist` – serviços de autenticação / Firestore presentes como referência).

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
   │  ├─ AR/
   │  │  ├─ Models/
   │  │  │  └─ ARCorrectionPoint.swift
   │  │  ├─ Services/
   │  │  │  └─ ARLocalStorage.swift
   │  │  ├─ ARExerciseView.swift
   │  │  ├─ ARExerciseViewModel.swift
   │  │  ├─ ARViewContainer.swift
   │  │  └─ DebugAROverlay.swift
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
   │  ├─ CoreData/
   │  │  ├─ ActivityListView.swift
   │  │  ├─ PersistenceController.swift
   │  │  └─ UserActivity.swift
   │  ├─ Gamification/
   │  │  ├─ Models/
   │  │  │  ├─ Badge.swift
   │  │  │  ├─ ProgressGameMode.swift
   │  │  │  └─ ProgressMetrics.swift
   │  │  ├─ Services/
   │  │  │  ├─ ProgressMetricsCalculator.swift
   │  │  │  ├─ ProgressMetricsMock.swift
   │  │  │  └─ ProgressMetricsProvider.swift
   │  │  ├─ SpriteKit/
   │  │  │  ├─ ProgressGameScene.swift
   │  │  │  └─ ProgressGameSceneFactory.swift
   │  │  ├─ ViewModels/
   │  │  │  └─ ProgressGameViewModel.swift
   │  │  └─ Views/
   │  │     ├─ ProgressGamePreviewView.swift
   │  │     └─ ProgressGameView.swift
   │  ├─ Home/
   │  │  └─ Views/
   │  │     └─ HomeView.swift
   │  ├─ Map/
   │  │  ├─ MapDemoView.swift
   │  │  ├─ MapView.swift
   │  │  └─ MapViewModel.swift
   │  ├─ Settings/
   │  │  └─ Views/
   │  │     ├─ AccountSecurityService.swift
   │  │     ├─ ChangePasswordView.swift
   │  │     ├─ DeleteAccountView.swift
   │  │     ├─ InfoLegalView.swift
   │  │     └─ SettingsView.swift
   │  ├─ Sprites/
   │  │  ├─ GameScene.swift
   │  │  └─ SpriteDemoView.swift
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
   │  │     ├─ TeacherStudentsListView.swift
   │  │     └─ TeacherMapView.swift
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

## 📋 Análise de Requisitos do Projeto

### ✅ Requisitos Atendidos

#### 1. **Navegação em Diversas Telas**
**Implementação:** Sistema de navegação baseado em rotas usando `AppRouter` e `AppRoute`

- **`AppRouter.swift`**: Gerencia a navegação entre telas usando enum de rotas
- **`AppRoute.swift`**: Define todas as rotas disponíveis no app
- **Telas implementadas:**
  - Login (`LoginView.swift`)
  - Registro (estudante e treinador: `RegisterStudentView.swift`, `RegisterTrainerView.swift`)
  - Perfil (`ProfileView.swift`, `EditProfileView.swift`)
  - Página Principal/Home (`Home/Views/`)
  - Configurações (`Settings/Views/`)
  - Sobre (`About/Views/AboutView.swift`)
  - Treinos (`Treinos/Views/`)
  - Gamificação (`Gamification/Views/`)

---

#### 2. **Persistência: Core Data**
**Implementação:** Sistema completo de persistência local

- **`PersistenceController.swift`**: Controlador singleton do Core Data com preview para testes
- **`UserActivity.swift`**: Entidade para armazenar atividades do usuário
- **`ActivityListView.swift`**: Interface para visualização das atividades persistidas
- **Uso:** Armazena histórico de atividades, treinos e progresso do usuário localmente

---

#### 3. **Persistência na Nuvem / Acesso a API**
**Implementação:** Firebase para autenticação e Firestore para banco de dados na nuvem

- **`FirebaseAuthService.swift`**: Serviço de autenticação usando Firebase Auth (login, registro, recuperação de senha)
- **`FirestoreRepository.swift`**: Repository genérico para operações CRUD no Firestore
- **`GoogleService-Info.plist`**: Configuração do Firebase
- **Uso:** Sincroniza dados de usuários, treinos e progresso na nuvem

---

#### 4. **MapKit / Core Location**
**Implementação:** Visualização de mapas e localização

- **`MapView.swift`**: View principal do mapa usando MapKit
- **`MapViewModel.swift`**: ViewModel que gerencia a lógica de localização e pontos no mapa
- **`MapDemoView.swift`**: Demonstração das funcionalidades do mapa
- **Uso:** Exibe localização do usuário, academias ou pontos de interesse para treino

---

#### 5. **Sprite Kit**
**Implementação:** Sistema de gamificação visual

- **`GameScene.swift`**: Cena principal do SpriteKit com lógica de jogo
- **`SpriteDemoView.swift`**: View de demonstração do SpriteKit integrado ao SwiftUI
- **`Gamification/SpriteKit/`**: Diretório com recursos adicionais de sprites
- **Uso:** Adiciona elementos de gamificação interativos (badges, animações, progresso visual)

---

#### 6. **AR Kit**
**Implementação:** Realidade aumentada para correção de exercícios

- **`ARExerciseView.swift`**: View principal de exercícios em AR
- **`ARExerciseViewModel.swift`**: ViewModel que gerencia a lógica do AR
- **`ARViewContainer.swift`**: Container UIViewRepresentable que encapsula ARView
- **`DebugAROverlay.swift`**: Overlay de debug para visualizar pontos de correção
- **`ARCorrectionPoint.swift`**: Model para pontos de correção de postura em AR
- **`ARLocalStorage.swift`**: Armazena dados de sessões AR localmente
- **Uso:** Detecta e corrige postura do usuário durante exercícios em tempo real usando câmera

---

### 📊 Resumo

Todos os **6 requisitos foram completamente implementados** no projeto:

1. ✅ **Navegação múltipla** - Sistema robusto com router pattern
2. ✅ **Core Data** - Persistência local de atividades
3. ✅ **Cloud/API** - Firebase Auth + Firestore para dados na nuvem
4. ✅ **MapKit** - Mapas e localização integrados
5. ✅ **SpriteKit** - Gamificação visual com sprites
6. ✅ **ARKit** - Correção de postura em exercícios via realidade aumentada

---

## 🔧 Build / Execução (notas rápidas)

- Abra o workspace `rdvperfomance.xcodeproj` no Xcode 14+ / Xcode compatível com iOS 16.
- Configure o `GoogleService-Info.plist` caso queira habilitar Firebase (Auth/Firestore) em ambiente de desenvolvimento.
- Execute o app em um simulador iOS 16+ ou dispositivo físico com as permissões necessárias.

### Permissão de localização (necessária para o Mapa da Academia)

Para que a opção "Mapa da Academia" funcione corretamente você precisa adicionar a chave de privacidade no `Info.plist` do target do app (se ainda não estiver presente). Abra o arquivo `Info.plist` no Xcode e confirme que a chave abaixo existe (valor em português ou conforme sua política de privacidade):

- `NSLocationWhenInUseUsageDescription` = "Usamos sua localização para centrar o mapa e mostrar a posição da academia (demo)."

> Observação: o recurso de mapa foi movido da tela de Configurações para a `Área do Professor` (Menu do Professor > "Mapa da Academia"). A entrada "Mapa (demo)" nas Configurações foi removida para evitar duplicidade. A rota antiga `.mapFeature` continua mapeada para a nova tela para compatibilidade (acesso restrito a professores).

---

## 🎯 Destaques do Projeto

- **Navegação centralizada** por rotas (`AppRoute` / `AppRouter`)
- **Componentes reutilizáveis** e layout responsivo
- **Realidade Aumentada (AR)** para análise de exercícios e correção de postura
- **Gamificação** com sistema de badges, conquistas e visualização de progressos
- **SpriteKit** para animações e jogos interativos
- **CoreData** para persistência local de atividades
- **MapKit** para visualização de localizações e academias
- **Integração com Firebase** (Auth/Firestore) preparada
- **Organização por features** (AR, Auth, CoreData, Gamification, Home, Map, Settings, Sprites, Student, Teacher, Treinos)
- **Arquitetura MVVM** com separação clara de responsabilidades

---

## 📌 Próximos Passos 

- Completar integração com backend (Firebase) e testar autenticação real
- Aprimorar sistema de AR com mais exercícios e detecção de postura
- Expandir sistema de gamificação com mais badges e desafios
- Adicionar sincronização de dados CoreData com Firestore
- Implementar notificações push para lembretes de treino
- Adicionar testes unitários / UI tests
- Documentar contratos de rede e modelos Firestore
- Internacionalização (strings em Localizable)
- Melhorar cobertura de assets e imagens de alta resolução
- Funções para importar planilhas em Excel
- Lista com exercícios pré-definidos para montagem rápida de treinos
- Melhorar overlay de debug do AR para facilitar desenvolvimento
- Adicionar mais modos de jogo no sistema de gamificação

---

## 👨‍💻 Projeto focado em boas práticas

Este app foi desenvolvido com foco em clareza, organização e escalabilidade, servindo como base para evolução futura ou portfólio profissional.
