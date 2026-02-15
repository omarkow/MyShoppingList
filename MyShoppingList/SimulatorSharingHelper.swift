//
//  SimulatorSharingHelper.swift
//  MyShoppingList
//
//  Helper pour tester le partage dans le simulateur
//

import SwiftUI
import CloudKit

struct SimulatorSharingView: View {
    @Environment(\.dismiss) var dismiss
    let itemCount: Int
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding()
                
                Text("Partage CloudKit")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Le partage CloudKit ne fonctionne pas dans le simulateur")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Votre liste : \(itemCount) article(s)")
                    }
                    
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Simulateur : Pas de vraie connexion iCloud")
                    }
                    
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.blue)
                        Text("Utilisez un appareil réel pour tester")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Divider()
                    .padding()
                
                Text("Pour tester le partage :")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("Installez l'app sur un iPhone/iPad", systemImage: "1.circle.fill")
                    Label("Connectez-vous avec votre compte iCloud", systemImage: "2.circle.fill")
                    Label("Appuyez sur le bouton de partage 👤+", systemImage: "3.circle.fill")
                    Label("Envoyez l'invitation à un autre appareil", systemImage: "4.circle.fill")
                    Label("L'autre personne accepte et voit la liste!", systemImage: "5.circle.fill")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
                
                Text("En simulateur, cette vue de démo apparaît à la place")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationTitle("Mode Simulateur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper pour détecter le simulateur

extension PersistenceController {
    /// Vérifie si on est sur un simulateur
    static var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Preview

#Preview {
    SimulatorSharingView(itemCount: 5)
}
