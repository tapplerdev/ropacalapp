import Flutter
import UIKit
import GoogleMaps
import CarPlay
import awesome_notifications
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Shared Flutter engine for both phone and CarPlay scenes
  lazy var flutterEngine = FlutterEngine(name: "ropacal_engine")

  // Captured reference to awesome_notifications' delegate so we can forward
  // local notification events (display decisions, tap actions) to it.
  private var awesomeNotificationsDelegate: UNUserNotificationCenterDelegate?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps
    GMSServices.provideAPIKey("AIzaSyAH7PTzTVJrud5KqsDmWEw67mQkiA0Co4Y")

    // Start the Flutter engine
    flutterEngine.run()

    // Register plugins with the engine
    GeneratedPluginRegistrant.register(with: flutterEngine)

    // awesome_notifications: register all plugins for background isolate
    // so notification actions work when app is terminated
    SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // awesome_notifications registers a didFinishLaunchingNotification observer
    // during plugin instantiation and sets itself as UNUserNotificationCenter
    // delegate when that notification fires. We register our observer AFTER super
    // returns (so after awesome_notifications registered its observer), which means
    // ours fires second — letting us capture its delegate and proxy through it.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(reclaimNotificationDelegate),
      name: UIApplication.didFinishLaunchingNotification,
      object: nil
    )

    return result
  }

  /// Called after awesome_notifications has set itself as the UNUserNotificationCenter
  /// delegate. We capture its delegate reference, then install ourselves as the
  /// delegate so we can selectively suppress FCM notifications in the foreground
  /// while still forwarding awesome_notifications' own notifications to it.
  @objc private func reclaimNotificationDelegate() {
    let currentDelegate = UNUserNotificationCenter.current().delegate
    if !(currentDelegate is AppDelegate) {
      awesomeNotificationsDelegate = currentDelegate
      UNUserNotificationCenter.current().delegate = self
    }
    // One-shot — remove observer after reclaiming
    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.didFinishLaunchingNotification,
      object: nil
    )
  }

  // ─── Notification Delegate Proxy ──────────────────────────────────────

  /// Controls whether iOS shows a native notification banner.
  ///
  /// FCM notifications (identified by gcm.message_id in userInfo):
  ///   - Foreground: suppress — our custom Flutter banner handles display.
  ///   - Background: show the APNS alert normally.
  ///
  /// awesome_notifications (local notifications):
  ///   - Forward to awesome_notifications so its display logic applies
  ///     (displayOnForeground, channels, etc.).
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo

    if userInfo["gcm.message_id"] != nil || userInfo["google.c.a.e"] != nil {
      // FCM push notification
      if UIApplication.shared.applicationState == .active {
        // Foreground — suppress native banner, Flutter custom banner handles it
        completionHandler([])
      } else {
        // Background/inactive — show APNS alert normally
        completionHandler([.alert, .badge, .sound])
      }
    } else if let delegate = awesomeNotificationsDelegate {
      // Local notification from awesome_notifications — forward
      delegate.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
    } else {
      // Fallback
      completionHandler([.alert, .badge, .sound])
    }
  }

  /// Handles notification tap actions.
  ///
  /// FCM taps: forward to super (FlutterAppDelegate routes to firebase_messaging
  ///   plugin, which fires onMessageOpenedApp in Dart).
  /// awesome_notifications taps: forward so action buttons and dismiss actions work.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo

    if userInfo["gcm.message_id"] != nil || userInfo["google.c.a.e"] != nil {
      // FCM notification tap — firebase_messaging handles onMessageOpenedApp
      super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    } else if let delegate = awesomeNotificationsDelegate {
      // awesome_notifications action button / tap
      delegate.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
    } else {
      completionHandler()
    }
  }

  // ─── Scene Configuration ──────────────────────────────────────────────

  // Support for scene-based app lifecycle
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // TODO: Uncomment CarPlay scene when entitlement is approved by Apple
    // Determine which scene to create based on the session role
    // if connectingSceneSession.role == UISceneSession.Role.carTemplateApplication {
    //   // CarPlay scene
    //   let sceneConfiguration = UISceneConfiguration(
    //     name: "CarPlay",
    //     sessionRole: connectingSceneSession.role
    //   )
    //   sceneConfiguration.delegateClass = CarSceneDelegate.self
    //   return sceneConfiguration
    // } else {
      // Phone scene
      let sceneConfiguration = UISceneConfiguration(
        name: "Phone",
        sessionRole: connectingSceneSession.role
      )
      sceneConfiguration.delegateClass = PhoneSceneDelegate.self
      return sceneConfiguration
    // }
  }
}
