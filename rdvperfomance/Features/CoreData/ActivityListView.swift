import SwiftUI
import CoreData

/// View que exibe lista de atividades do usuário com opções de adicionar e deletar
struct ActivityListView: View {
    /// Contexto do Core Data injetado pelo ambiente
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.locale) private var locale
    /// Request de busca que retorna atividades ordenadas por data decrescente
    @FetchRequest(entity: UserActivity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \UserActivity.date, ascending: false)]) private var activities: FetchedResults<UserActivity>

    var body: some View {
        NavigationView {
            List {
                ForEach(activities, id: \.objectID) { activity in
                    VStack(alignment: .leading) {
                        if let title = activity.title {
                            Text(title)
                                .font(.headline)
                        } else {
                            Text("core_data.activity.untitled")
                                .font(.headline)
                        }
                        if let d = activity.date {
                            Text(d.formatted(.dateTime.year().month().day().hour().minute().locale(locale)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("core_data.activities.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: add) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    /// Adiciona uma nova atividade com título aleatório e data atual
    private func add() {
        let newItem = UserActivity(context: viewContext)
        newItem.id = UUID()
        let format = String(localized: "core_data.activity.generated_title", locale: locale)
        newItem.title = String(format: format, locale: locale, arguments: [Int64.random(in: 1...1000)])
        newItem.date = Date()

        do {
            try viewContext.save()
        } catch {
            print("Erro salvando atividade: \(error)")
        }
    }

    /// Remove atividades selecionadas pelos índices fornecidos
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let item = activities[index]
            viewContext.delete(item)
        }
        do {
            try viewContext.save()
        } catch {
            print("Erro ao deletar atividade: \(error)")
        }
    }
}

/// Provider para preview da ActivityListView com contexto em memória
struct ActivityListView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController(inMemory: true)
        ActivityListView()
            .environment(\.managedObjectContext, controller.container.viewContext)
    }
}
