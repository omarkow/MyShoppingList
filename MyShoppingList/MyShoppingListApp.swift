import SwiftUI
import CoreData
import CloudKit

@main
struct MaListeDeCoursesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(persistenceController)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        let container = PersistenceController.shared.container
        
        // Récupérer le store persistant
        guard let store = container.persistentStoreCoordinator.persistentStores.first else {
            print("❌ Impossible de trouver le persistent store")
            return
        }
        
        // Accepter le partage CloudKit
        container.acceptShareInvitations(from: [cloudKitShareMetadata], into: store) { _, error in
            if let error = error {
                print("❌ Erreur acceptation partage: \(error.localizedDescription)")
            } else {
                print("✅ Partage accepté avec succès!")
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configuration additionnelle si nécessaire
        print("✅ App lancée avec Core Data + CloudKit")
        return true
    }
}

