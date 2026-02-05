import CarPlay
import GoogleNavigation
import UIKit
import google_navigation_flutter

/// CarPlay scene delegate for Ropacal App
/// Maximizes map view by keeping header and footer hidden
class CarSceneDelegate: BaseCarSceneDelegate {

    /// Customize the CarPlay template with custom re-center button
    override func getTemplate() -> CPMapTemplate {
        let template = CPMapTemplate()

        // Enable panning interface for the map
        template.showPanningInterface(animated: true)

        // Custom re-center button with CarPlay-optimized zoom level
        let recenterButton = CPBarButton(title: "Re-center") { [weak self] _ in
            // Use zoom level 13 for CarPlay (balanced overview)
            // Provides good balance between detail and overview
            self?.getNavView()?.followMyLocation(
                perspective: GMSNavigationCameraPerspective.tilted,
                zoomLevel: 13
            )
        }

        // Place button in leading navigation bar (top-left corner)
        template.leadingNavigationBarButtons = [recenterButton]

        return template
    }

    /// Customize CarPlay navigation view settings
    /// Disable compass and set CarPlay-optimized zoom level
    override func sceneDidBecomeActive(_ scene: UIScene) {
        super.sceneDidBecomeActive(scene)

        // Disable compass on CarPlay (matches phone setting)
        try? getNavView()?.setCompassEnabled(false)

        // Set CarPlay-optimized zoom level (more zoomed out for better overview)
        // Zoom 13 = Balanced overview (vs zoom 15 on phone)
        try? getNavView()?.followMyLocation(perspective: .tilted, zoomLevel: 13)

        // Note: Using custom CPMapButton for re-center instead of native button
        // Native button would be: try? getNavView()?.setRecenterButtonEnabled(true)
    }
}
