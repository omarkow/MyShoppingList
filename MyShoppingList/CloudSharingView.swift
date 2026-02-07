//
//  CloudSharingView.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import SwiftUI
import CloudKit

#if os(iOS)
/// Wraps UICloudSharingController for presenting CloudKit sharing UI on iOS.
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let listTitle: String

    func makeUIViewController(context: Context) -> UICloudSharingController {
        share[CKShare.SystemFieldKey.title] = listTitle as CKRecordValue
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowPublic, .allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            print("Failed to save share: \(error.localizedDescription)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            return csc.share?[CKShare.SystemFieldKey.title] as? String
        }
    }
}
#elseif os(macOS)
/// macOS fallback: uses NSSharingServicePicker for CloudKit sharing.
struct CloudSharingView: NSViewRepresentable {
    let share: CKShare
    let container: CKContainer
    let listTitle: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            let sharingService = NSSharingService(named: .cloudSharing)
            if let service = sharingService {
                let items: [Any] = [
                    CKShareMetadata() // Placeholder — macOS sharing requires full CloudKit setup in Xcode
                ]
                let picker = NSSharingServicePicker(items: items)
                picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
