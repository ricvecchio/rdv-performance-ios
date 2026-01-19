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
- Firebase (configuração parcial via `GoogleService-Info.plist` – serviços de autenticação / Firestore presentes como referência)

---

## 🧭 Estrutura de Navegação

A navegação do app é centralizada através de um `NavigationStack`, controlada por um conjunto de rotas (`[AppRoute]`) e orquestrada em `AppRouter`. Isso garante navegação previsível e segura entre telas, com validação de permissões baseada no tipo de usuário.

### Rotas principais

#### 🎓 Fluxo do Aluno
- Login / Registro
- **Agenda** (tela inicial) — visualização de semanas de treino
- Detalhes de Semana — treinos programados por dia
- Detalhes de Dia — exercícios específicos do treino
- Mensagens — comunicação com o professor
- Feedbacks — histórico de avaliações enviadas
- Perfil / Configurações
- Sobre
- AR Demo — visualização de exercícios em realidade aumentada
- Gamificação — progresso e conquistas

#### 👨‍🏫 Fluxo do Professor
- Login / Registro
- **Dashboard** (tela inicial) — menu de opções da área do professor
- Lista de Alunos — gerenciamento por categoria (Crossfit/Academia/Casa)
- Detalhes do Aluno — visualização individual e ações
- Criação de Semana de Treino — planejamento semanal para alunos
- Criação de Treino do Dia — definição de exercícios
- Biblioteca de Treinos — templates e treinos salvos
- Importar Treinos — upload via planilhas Excel
- Importar Vídeos — gerenciamento de vídeos do YouTube
- Enviar Mensagem — comunicação com alunos
- Feedbacks — visualização de feedbacks dos alunos
- Mapa da Academia — localização e visualização
- Templates de Treino — biblioteca organizada por seções
- Perfil / Configurações
- Sobre

### Sistema de Guards

O `AppRouter` implementa proteções (guards) para garantir que:
- Usuários não autenticados sejam redirecionados ao Login
- Professores não acessem rotas exclusivas de alunos
- Alunos não acessem rotas exclusivas de professores
- Redirecionamento automático para a tela inicial apropriada

---

## 🔐 Tela de Login

- Tela inicial do aplicativo
- Campos de e-mail e senha
- Opção de mostrar/ocultar senha
- Validação básica (campos não vazios)
- Após validação, navega para a Home

> Observação: o projeto contém uma camada de autenticação (FirebaseAuthService) — dependendo da configuração do `GoogleService-Info.plist`, a autenticação pode ser habilitada; por padrão aqui está preparada apenas como referência.

---

## 🏠 Tela Home / Inicial

O fluxo inicial do aplicativo varia conforme o tipo de usuário:

### 👨‍🎓 Aluno

Após o login, o aluno é direcionado automaticamente para a **Agenda de Treinos** (`StudentAgendaView`):
- Visualização de todas as semanas de treino programadas
- Acesso rápido aos treinos do dia
- Cards com informações de progresso e status
- Navegação para detalhes de cada semana

### 👨‍🏫 Professor

Após o login, o professor é direcionado automaticamente para a **Área do Professor** (`TeacherDashboardView`) com menu de opções:

- **Biblioteca de Treinos** — Acesso a templates e treinos criados
- **Meus Alunos** — Lista e gerenciamento de alunos vinculados
- **Importar Treino** — Importação de treinos via planilhas Excel
- **Importar Vídeos** — Importação de vídeos do YouTube
- **Mapa da Academia** — Visualização da localização da academia
- **Visualizar no Ambiente** — Demonstração de exercícios em Realidade Aumentada

> **Nota:** O arquivo `HomeView.swift` contém uma interface legacy com três opções de treino (Crossfit, Academia, Treinos em Casa) que foi usada em versões anteriores, mas atualmente o roteamento inteligente (`AppRouter`) garante que cada tipo de usuário veja sua interface apropriada desde o início.

---

## 🏋️ Tipos de Treino

Os tipos de treino são controlados por um enum central (`TreinoTipo`), responsável por categorizar e personalizar a experiência em diferentes áreas do app:

### Categorias Disponíveis
- **Crossfit** — treinos de alta intensidade com foco em funcionalidade
- **Academia** — musculação e exercícios de academia tradicional
- **Treinos em Casa** — exercícios que podem ser realizados sem equipamentos especiais

### Personalização por Tipo
Cada categoria possui:
- Título específico da tela
- Texto sobreposto personalizado em imagens
- Imagem principal característica
- Ícone personalizado no rodapé
- Seções específicas de biblioteca (para professores)

### Nota sobre HomeView
O arquivo `HomeView.swift` ainda existe no projeto com as três opções visuais de treino (Crossfit, Academia, Casa), mas atualmente funciona como:
- **Interface legacy** preservada para compatibilidade
- **Não é a tela inicial** de nenhum fluxo (alunos vão para Agenda, professores para Dashboard)
- **Pode ser acessada** em casos específicos de navegação alternativa
- Os tiles quando clicados redirecionam o aluno para sua Agenda

Esta abordagem mantém a flexibilidade do sistema enquanto oferece experiências otimizadas para cada tipo de usuário.

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

## 🎓 Área do Aluno

Interface dedicada para alunos acompanharem seus treinos e progresso:

### 📅 Agenda de Treinos

- Visualização semanal de treinos programados
- Detalhamento de treinos por dia
- Acesso a treinos por semana
- Interface intuitiva com calendário

### 📈 Acompanhamento

- Visualização de feedbacks enviados ao professor
- Recebimento de mensagens do professor
- Histórico de treinos realizados
- Progresso visual através do sistema de gamificação

### 🎮 Recursos Interativos

- Sistema de badges e conquistas
- Análise de exercícios com Realidade Aumentada (AR)
- Correção de postura em tempo real
- Visualização de vídeos instrutivos

---

## 👨‍🏫 Área do Professor

### 📹 Importação de Vídeos (YouTube)

Sistema completo para professores gerenciarem vídeos do YouTube:

- Importação de vídeos através de URLs do YouTube
- Player bloqueado para controle total do conteúdo
- Suporte para AirPlay (espelhamento de tela)
- Envio de vídeos específicos para alunos
- Repository local para armazenamento de vídeos importados
- Interface WebView customizada com UIKit

### 📊 Importação de Treinos (Excel)

Sistema de importação de treinos a partir de planilhas Excel:

- Importação via Document Picker
- Template pré-definido em português para CrossFit (`rdv_import_treinos_template_pt_crossfit.xlsx`)
- Parser de planilhas Excel para estrutura de treinos
- Repository local para armazenamento de treinos importados
- Visualização detalhada de treinos importados
- Envio de treinos para alunos específicos

### 🎯 Outras Funcionalidades do Professor

- Dashboard com visão geral de alunos e treinos
- Gerenciamento de alunos vinculados
- Criação de semanas de treino personalizadas
- Biblioteca de exercícios de CrossFit
- Templates de treinos reutilizáveis
- Sistema de mensagens para alunos
- Visualização de feedbacks dos alunos
- Mapa com localização da academia

---

## 🧩 Componentes Reutilizáveis

Alguns componentes compartilhados:

### UI Components
- `UnderlineTextField` — campo customizado com linha inferior e suporte a senha (mostrar/ocultar)
- `HeaderBar`, `FooterBar` — cabeçalho e rodapé usados em várias telas
- `MiniProfileHeader`, `HeaderAvatarView` — cabeçalhos específicos de perfis
- `BlockDraft` — componente para rascunhos de blocos de treino

### Extensions
- `Array+Chunked` — extensão para dividir arrays em grupos

### Services
- `LocalProfileStore` — armazenamento local de perfil do usuário
- `FirestoreRepository` — repositório base para operações no Firestore
- `FirestoreBaseRepository` — classe base para repositórios Firestore
- `UserRepository` — gerenciamento de usuários no Firestore
- `TrainingRepository` — gerenciamento de treinos no Firestore
- `ProgressRepository` — gerenciamento de progresso no Firestore
- `FeedbackRepository` — gerenciamento de feedbacks no Firestore
- `MessageRepository` — gerenciamento de mensagens no Firestore
- `WorkoutTemplateRepository` — gerenciamento de templates de treino

### UI Utilities
- `Theme` — definições visuais centrais
- `NavigationBarNoHairline` — customização da barra de navegação

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
   │  │     ├─ StudentAvatarView.swift
   │  │     ├─ StudentDayDetailView.swift
   │  │     ├─ StudentFeedbacksView.swift
   │  │     ├─ StudentMessagesView.swift
   │  │     └─ StudentWeekDetailView.swift
   │  ├─ Teacher/
   │  │  ├─ ImportVideos/
   │  │  │  ├─ Models/
   │  │  │  │  └─ TeacherImportVideosModels.swift
   │  │  │  ├─ Services/
   │  │  │  │  ├─ TeacherYoutubeVideosRepository.swift
   │  │  │  │  └─ YouTubeVideoImporter.swift
   │  │  │  ├─ UIKit/
   │  │  │  │  ├─ AirPlayRoutePicker.swift
   │  │  │  │  └─ LockedYoutubeWebView.swift
   │  │  │  └─ Views/
   │  │  │     ├─ TeacherAddYoutubeVideoSheet.swift
   │  │  │     ├─ TeacherImportVideosView.swift
   │  │  │     ├─ TeacherSendYoutubeVideoToStudentSheet.swift
   │  │  │     └─ TeacherYoutubeLockedPlayerSheet.swift
   │  │  ├─ ImportWorkouts/
   │  │  │  ├─ Models/
   │  │  │  │  └─ TeacherImportWorkoutsModels.swift
   │  │  │  ├─ Services/
   │  │  │  │  ├─ ExcelWorkoutImporter.swift
   │  │  │  │  └─ TeacherImportedWorkoutsRepository.swift
   │  │  │  ├─ UIKit/
   │  │  │  │  ├─ ActivityView.swift
   │  │  │  │  └─ DocumentPicker.swift
   │  │  │  └─ Views/
   │  │  │     ├─ TeacherAddWorkoutSheet.swift
   │  │  │     ├─ TeacherImportWorkoutsView.swift
   │  │  │     └─ TeacherImportedWorkoutDetailsSheet.swift
   │  │  ├─ ViewModels/
   │  │  │  ├─ CreateTrainingWeekViewModel.swift
   │  │  │  └─ TeacherStudentsListViewModel.swift
   │  │  └─ Views/
   │  │     ├─ CreateTrainingWeekView.swift
   │  │     ├─ TeacherCrossfitLibraryView.swift
   │  │     ├─ TeacherDashboardView.swift
   │  │     ├─ TeacherFeedbacksView.swift
   │  │     ├─ TeacherLinkStudentView.swift
   │  │     ├─ TeacherMapView.swift
   │  │     ├─ TeacherMyWorkoutsView.swift
   │  │     ├─ TeacherSendMessageView.swift
   │  │     ├─ TeacherSendWorkoutToStudentSheet.swift
   │  │     ├─ TeacherStudentDetailView.swift
   │  │     ├─ TeacherStudentsListView.swift
   │  │     ├─ TeacherWorkoutTemplateDetailSheet.swift
   │  │     ├─ TeacherWorkoutTemplatesComponents.swift
   │  │     ├─ TeacherWorkoutTemplatesListView.swift
   │  │     └─ TeacherWorkoutTemplatesView.swift
   │  └─ Treinos/
   │     ├─ Models/
   │     │  ├─ FirestoreModels.swift
   │     │  ├─ StudentFeedbackFS.swift
   │     │  ├─ TeacherMessageFS.swift
   │     │  ├─ TreinoTipo.swift
   │     │  └─ WorkoutTemplateFS.swift
   │     └─ Views/
   │        ├─ CreateCrossfitWODView.swift
   │        ├─ CreateTrainingDayView.swift
   │        ├─ CreateTreinoAcademiaView.swift
   │        ├─ CreateTreinoCasaView.swift
   │        ├─ CrossfitMenuView.swift
   │        └─ TreinosView.swift
   ├─ Shared/
   │  ├─ Components/
   │  │  ├─ BlockDraft.swift
   │  │  ├─ FooterBar.swift
   │  │  ├─ HeaderAvatarView.swift
   │  │  ├─ HeaderBar.swift
   │  │  ├─ MiniProfileHeader.swift
   │  │  └─ UnderlineTextField.swift
   │  ├─ Extensions/
   │  │  └─ Array+Chunked.swift
   │  ├─ Services/
   │  │  ├─ Firestore/
   │  │  │  ├─ Base/
   │  │  │  │  ├─ FirestoreBaseRepository.swift
   │  │  │  │  └─ FirestoreRepositoryError.swift
   │  │  │  ├─ Communication/
   │  │  │  │  ├─ FeedbackRepository.swift
   │  │  │  │  └─ MessageRepository.swift
   │  │  │  ├─ Templates/
   │  │  │  │  └─ WorkoutTemplateRepository.swift
   │  │  │  ├─ Training/
   │  │  │  │  ├─ ProgressRepository.swift
   │  │  │  │  └─ TrainingRepository.swift
   │  │  │  ├─ Users/
   │  │  │  │  └─ UserRepository.swift
   │  │  │  └─ FirestoreRepository.swift
   │  │  └─ LocalProfileStore.swift
   │  └─ UI/
   │     ├─ NavigationBarNoHairline.swift
   │     └─ Theme.swift
   ├─ Resources/
   │  ├─ Assets.xcassets/
   │  │  ├─ AccentColor.colorset/
   │  │  ├─ AppIcon.appiconset/
   │  │  ├─ Default.colorset/
   │  │  ├─ rdv_crossfit_benchmark_horizontal.imageset/
   │  │  ├─ rdv_crossfit_meusrecordes_horizontal.imageset/
   │  │  ├─ rdv_crossfit_monteseutreino_horizontal.imageset/
   │  │  ├─ rdv_crossfit_progressos_horizontal.imageset/
   │  │  ├─ rdv_crossfit_wod_horizontal.imageset/
   │  │  ├─ rdv_fundo.imageset/
   │  │  ├─ rdv_logo.imageset/
   │  │  ├─ rdv_programa_academia_horizontal.imageset/
   │  │  ├─ rdv_programa_crossfit_horizontal.imageset/
   │  │  ├─ rdv_programa_treinos_em_casa_horizontal.imageset/
   │  │  ├─ rdv_treino1_vertical.imageset/
   │  │  ├─ rdv_treino2_vertical.imageset/
   │  │  ├─ rdv_treino3_vertical.imageset/
   │  │  └─ rdv_user_default.imageset/
   │  └─ Templates/
   │     └─ rdv_import_treinos_template_pt_crossfit.xlsx
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
- **Importação de Vídeos do YouTube** com player bloqueado e suporte AirPlay
- **Importação de Treinos via Excel** com template pré-definido
- **Sistema completo para Professores** (dashboard, gerenciamento de alunos, mensagens, feedbacks)
- **Sistema completo para Alunos** (agenda, treinos, mensagens, feedbacks, progresso)
- **Organização por features** (AR, Auth, CoreData, Gamification, Home, Map, Settings, Sprites, Student, Teacher, Treinos)
- **Arquitetura MVVM** com separação clara de responsabilidades
- **Repository Pattern** para acesso a dados Firestore
- **UIKit Integration** para funcionalidades avançadas (WebView, DocumentPicker, AirPlay)

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
- Expandir lista de exercícios pré-definidos para montagem rápida de treinos
- Melhorar overlay de debug do AR para facilitar desenvolvimento
- Adicionar mais modos de jogo no sistema de gamificação
- Implementar suporte para AirPlay na reprodução de vídeos
- Adicionar mais templates de importação para diferentes modalidades

---

## 👨‍💻 Projeto focado em boas práticas

Este app foi desenvolvido com foco em clareza, organização e escalabilidade, servindo como base para evolução futura ou portfólio profissional.
