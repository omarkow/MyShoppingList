import SwiftUI
import CloudKit
import CoreData
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var persistenceController: PersistenceController
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItemEntity.name, ascending: true)],
        animation: .default)
    private var items: FetchedResults<GroceryItemEntity>

    @State private var isImporting: Bool = false
    @State private var newItemName: String = ""
    @State private var sortOption: SortOption = .name
    @State private var showShareSheet = false
    @State private var shareToPresent: CKShare?
    @State private var isSyncing = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSimulatorInfo = false  // Pour le simulateur
    @State private var isPreparingShare = false  // Pour éviter les appels multiples
    
    enum SortOption {
        case name
        case frequency
    }
    
    // Observer les événements CloudKit
    let syncNotification = NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
    
    var sortedItems: [GroceryItemEntity] {
        return items.sorted { first, second in
            switch sortOption {
            case .name:
                return first.name.lowercased() < second.name.lowercased()
            case .frequency:
                // Tri décroissant : les plus fréquents en premier
                return first.frequencyInt > second.frequencyInt
            }
        }
    }
    
    var cloudContainer: CKContainer {
        // ⚠️ IMPORTANT: Utiliser le MÊME conteneur que dans PersistenceController
        let containerID = "iCloud.com.MyShoppingList"
        
        print("🌐 CloudContainer UI: \(containerID)")
        return CKContainer(identifier: containerID)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Ajouter un article...", text: $newItemName)
                            .onSubmit { addItem() }
                        
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                        .disabled(newItemName.isEmpty)
                    }
                }
                
                Section(header: Text("À acheter")) {
                    ForEach(sortedItems.filter { !$0.isPurchased }) { item in
                        ItemRow(item: item, toggleAction: { toggleItem(item) })
                    }
                    .onDelete { offsets in
                        deleteItems(at: offsets, from: sortedItems.filter { !$0.isPurchased })
                    }
                }
                
                Section(header: Text("Achetés")) {
                    ForEach(sortedItems.filter { $0.isPurchased }) { item in
                        ItemRow(item: item, toggleAction: { toggleItem(item) })
                            .opacity(0.5)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ma Liste")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            sortOption = .name
                        } label: {
                            HStack {
                                Label("Nom (A-Z)", systemImage: "textformat.abc")
                                if sortOption == .name {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        Button {
                            sortOption = .frequency
                        } label: {
                            HStack {
                                Label("Fréquence d'achat", systemImage: "chart.line.uptrend.xyaxis")
                                if sortOption == .frequency {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
                
                // Menu actions de masse
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            persistenceController.markAllAsPurchased()
                        } label: {
                            Label("Tout marquer comme acheté", systemImage: "checkmark.circle.fill")
                        }
                        
                        Button {
                            persistenceController.markAllAsNotPurchased()
                        } label: {
                            Label("Tout marquer comme non acheté", systemImage: "circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            persistenceController.deleteAllPurchased()
                        } label: {
                            Label("Supprimer les articles achetés", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "checklist")
                    }
                    .disabled(items.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: importCSV) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSyncing {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: prepareSharing) {
                        if isPreparingShare {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Image(systemName: "person.badge.plus")
                        }
                    }
                    .disabled(items.isEmpty || isPreparingShare)
                }
            }
            
            .onReceive(syncNotification) { notification in
                if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                    withAnimation {
                        isSyncing = event.endDate == nil
                    }
                }
            }
            
            .sheet(item: Binding(
                get: { shareToPresent.map { ShareWrapper(share: $0) } },
                set: { newValue in
                    // Ajouter un délai pour éviter les réouvertures immédiates
                    if newValue == nil && shareToPresent != nil {
                        print("🔻 Fermeture de la sheet de partage")
                    }
                    shareToPresent = newValue?.share
                }
            )) { wrapper in
                CloudSharingViewController(
                    share: wrapper.share,
                    container: cloudContainer,
                    persistenceController: persistenceController
                )
            }
        
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            
            .alert("Erreur de Partage", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            
            .sheet(isPresented: $showSimulatorInfo) {
                SimulatorSharingView(itemCount: items.count)
            }
        }
    }
    
    // MARK: - Fonctions de logique
    
    func toggleItem(_ item: GroceryItemEntity) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            item.isPurchased.toggle()
            if item.isPurchased {
                item.frequencyInt += 1
            }
            persistenceController.save()
        }
    }
    
    func addItem() {
        let cleanedName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else { return }

        if let existingItem = items.first(where: { $0.name.lowercased() == cleanedName.lowercased() }) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                existingItem.isPurchased = false
                existingItem.frequencyInt += 1
                existingItem.name = cleanedName
                persistenceController.save()
            }
            newItemName = ""
        } else {
            withAnimation {
                _ = GroceryItemEntity.create(in: viewContext, name: cleanedName)
                persistenceController.save()
                newItemName = ""
            }
        }
    }
    
    func deleteItems(at offsets: IndexSet, from array: [GroceryItemEntity]) {
        withAnimation {
            for index in offsets {
                viewContext.delete(array[index])
            }
            persistenceController.save()
        }
    }
    
    func prepareSharing() {
        print("🔘 Bouton de partage cliqué")
        
        // Éviter les appels multiples si un partage est déjà en cours de présentation ou de préparation
        guard shareToPresent == nil, !isPreparingShare else {
            print("   ⚠️ Un partage est déjà en cours - ignoré")
            return
        }
        
        // Vérifier si on est sur simulateur
        #if targetEnvironment(simulator)
        print("   ⚠️ Simulateur détecté - Affichage de la vue de démo")
        showSimulatorInfo = true
        #else
        
        isPreparingShare = true
        
        Task {
            defer {
                Task { @MainActor in
                    isPreparingShare = false
                }
            }
            
            do {
                print("   Tentative de création du partage...")
                // Créer ou récupérer le partage
                let share = try await persistenceController.createShare()
                
                print("   ✅ Partage créé/récupéré avec succès")
                // Utiliser une seule mise à jour atomique
                await MainActor.run {
                    // Double vérification pour éviter les conflits de présentation
                    if shareToPresent == nil {
                        shareToPresent = share
                        print("   📱 Interface de partage prête à s'afficher")
                    } else {
                        print("   ⚠️ Un partage était déjà présent - ignoré")
                    }
                }
            } catch {
                print("   ❌ Erreur création partage: \(error)")
                print("   Détails: \(error.localizedDescription)")
                
                await MainActor.run {
                    errorMessage = """
                    Impossible de partager la liste.
                    
                    Erreur: \(error.localizedDescription)
                    
                    💡 Note: Le partage CloudKit nécessite:
                    - Un appareil réel (pas le simulateur)
                    - Un compte iCloud actif
                    - Une connexion Internet
                    """
                    showErrorAlert = true
                }
            }
        }
        #endif
    }
    
    func importCSV() {
        isImporting = true
    }
    
    func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    parseCSV(content)
                } catch {
                    print("Erreur lecture: \(error)")
                }
            }
        case .failure(let error):
            print("Erreur: \(error)")
        }
    }
    
    func parseCSV(_ data: String) {
        let lines = data.components(separatedBy: .newlines)
        for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            let columns = line.components(separatedBy: ",")
            guard !columns.isEmpty else { continue }
            
            let name = columns[0].trimmingCharacters(in: .whitespaces)
            guard name != "Nom" else { continue } // Skip header
            
            var frequency = 1
            if columns.count > 2 {
                frequency = Int(columns[2].trimmingCharacters(in: .whitespaces)) ?? 1
            }
            
            _ = GroceryItemEntity.create(in: viewContext, name: name, frequency: frequency)
        }
        persistenceController.save()
    }
}

// MARK: - ItemRow avec Core Data

struct ItemRow: View {
    @ObservedObject var item: GroceryItemEntity
    var toggleAction: () -> Void

    var body: some View {
        HStack {
            Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isPurchased ? .green : .gray)
                .onTapGesture { toggleAction() }

            TextField("Nom de l'article", text: Binding(
                get: { item.name },
                set: { item.name = $0 }
            ))
            .strikethrough(item.isPurchased)
            .foregroundColor(item.isPurchased ? .secondary : .primary)
        }
    }
}

// MARK: - Wrapper pour le partage

struct ShareWrapper: Identifiable {
    let id = UUID()
    let share: CKShare
}
