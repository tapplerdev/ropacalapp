import Flutter
import UIKit
import GoogleMaps
import CarPlay

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Shared Flutter engine for both phone and CarPlay scenes
  lazy var flutterEngine = FlutterEngine(name: "ropacal_engine")

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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

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
