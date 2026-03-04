import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore

/// Handles push notification permission, FCM token registration, and
/// foreground notification display. Call `setup(userId:)` once per sign-in.
final class NotificationService: NSObject, @unchecked Sendable {

    static let shared = NotificationService()

    private override init() {
        super.init()
        // Become the UNUserNotificationCenter delegate early so foreground
        // notifications are displayed even when the app is open.
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    /// Requests notification permission, registers for remote notifications,
    /// and uploads the current FCM token to Firestore for the signed-in user.
    @MainActor
    func setup(userId: String) async {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        guard granted else { return }

        UIApplication.shared.registerForRemoteNotifications()

        // Fetch current FCM token and persist it
        Messaging.messaging().token { token, _ in
            guard let token else { return }
            Task {
                try? await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .updateData(["fcmToken": token])
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Show banner + play sound for notifications received while the app is foregrounded.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    /// Called whenever the FCM registration token is created or refreshed.
    /// Re-saves the token so it stays current even after app reinstalls.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        // Persist immediately if a user is already signed in
        Task {
            if let userId = await Auth.auth().currentUser?.uid {
                try? await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .updateData(["fcmToken": token])
            }
        }
    }
}
