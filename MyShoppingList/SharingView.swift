//
//  CloudSharingView.swift
//  MyShoppingList
//
//  UICloudSharingController wrapper pour Core Data + CloudKit
//

import SwiftUI
import UIKit
import CloudKit

struct CloudSharingViewController: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let persistenceController: PersistenceController
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        // ✅ Utiliser le nouvel initialisateur iOS 17+ (non-déprécié)
        let controller = UICloudSharingController(share: share, container: container)
        
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        
        print("✅ UICloudSharingController créé")
        print("   Share URL: \(share.url?.absoluteString ?? "aucune URL")")
        print("   Container: \(container.containerIdentifier ?? "pas d'ID")")
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // Pas de mise à jour nécessaire
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(persistenceController: persistenceController, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let persistenceController: PersistenceController
        let dismiss: DismissAction
        
        init(persistenceController: PersistenceController, dismiss: DismissAction) {
            self.persistenceController = persistenceController
            self.dismiss = dismiss
        }
        
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("❌ Échec sauvegarde partage: \(error.localizedDescription)")
            print("   Détails complets: \(error)")
            
            // Vérifier le type d'erreur
            if let ckError = error as? CKError {
                print("   Code CKError: \(ckError.code.rawValue)")
                print("   Description: \(ckError.localizedDescription)")
                
                // Cas spécifiques
                switch ckError.code {
                case .networkUnavailable:
                    print("   💡 Pas de connexion Internet")
                case .notAuthenticated:
                    print("   💡 Pas connecté à iCloud")
                case .badContainer:
                    print("   💡 Conteneur CloudKit invalide")
                case .serverRejectedRequest:
                    print("   💡 Serveur CloudKit a rejeté la requête")
                default:
                    break
                }
            }
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "Ma Liste de Courses"
        }
        
        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // Créer une icône simple pour la liste
            if let image = UIImage(systemName: "list.bullet.rectangle.fill") {
                let config = UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)
                let configuredImage = image.withConfiguration(config)
                return configuredImage.pngData()
            }
            return nil
        }
        
        func itemType(for csc: UICloudSharingController) -> String? {
            return "com.myshoppinglist.list"
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("✅ Partage sauvegardé avec succès!")
            print("   Les participants peuvent maintenant rejoindre")
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("🛑 Utilisateur a arrêté le partage")
            
            // Utiliser la nouvelle méthode stopSharing()
            Task {
                do {
                    try await persistenceController.stopSharing()
                    print("✅ Partage complètement arrêté")
                } catch {
                    print("❌ Erreur lors de l'arrêt du partage: \(error.localizedDescription)")
                }
            }
        }
    }
}
