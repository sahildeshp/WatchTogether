import SwiftUI
import SwiftData
import Firebase
import FirebaseMessaging

@main
struct WatchTogetherApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let modelContainer: ModelContainer

    init() {
        // Configure Firebase — requires GoogleService-Info.plist in the bundle.
        // Download it from your Firebase Console → Project Settings → iOS app.
        FirebaseApp.configure()

        // Initialise NotificationService early so its UNUserNotificationCenterDelegate
        // and MessagingDelegate are registered before any notifications arrive.
        _ = NotificationService.shared

        do {
            modelContainer = try ModelContainer(
                for: LocalWatchlistItem.self, LocalCouple.self
            )
        } catch {
            fatalError("Failed to initialize SwiftData model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - AppDelegate

/// Minimal AppDelegate whose only job is to forward the APNS device token
/// to Firebase Messaging so FCM tokens can be minted correctly.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
