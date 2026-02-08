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
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UICloudSharingController {
        share[CKShare.SystemFieldKey.title] = listTitle as CKRecordValue
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowPublic, .allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            print("Failed to save share: \(error.localizedDescription)")
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            dismiss()
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            dismiss()
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            return csc.share?[CKShare.SystemFieldKey.title] as? String
        }
    }
}
#elseif os(macOS)
/// macOS: uses NSSharingServicePicker with CloudKit sharing support.
struct CloudSharingView: NSViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let listTitle: String

    func makeNSViewController(context: Context) -> NSSharingServicePickerViewController {
        let itemProvider = NSItemProvider()
        itemProvider.registerCloudKitShare(share, container: container)
        let picker = NSSharingServicePickerViewController(items: [itemProvider])
        return picker
    }

    func updateNSViewController(_ nsViewController: NSSharingServicePickerViewController, context: Context) {}
}
#endif
