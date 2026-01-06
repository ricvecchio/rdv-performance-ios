import SwiftUI
import CoreData

struct ActivityListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: UserActivity.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \UserActivity.date, ascending: false)]) private var activities: FetchedResults<UserActivity>

    var body: some View {
        NavigationView {
            List {
                ForEach(activities, id: \.objectID) { activity in
                    VStack(alignment: .leading) {
                        Text(activity.title ?? "(sem título)")
                            .font(.headline)
                        if let d = activity.date {
                            Text(DateFormatter.localizedString(from: d, dateStyle: .short, timeStyle: .short))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Atividades")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: add) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func add() {
        let newItem = UserActivity(context: viewContext)
        newItem.id = UUID()
        newItem.title = "Atividade \(Int.random(in: 1...1000))"
        newItem.date = Date()

        do {
            try viewContext.save()
        } catch {
            print("Erro salvando atividade: \(error)")
        }
    }

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

struct ActivityListView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController(inMemory: true)
        ActivityListView()
            .environment(\.managedObjectContext, controller.container.viewContext)
    }
}
