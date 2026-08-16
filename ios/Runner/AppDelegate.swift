import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // FlutterAppDelegate does NOT conform to UNUserNotificationCenterDelegate
    // (it is a UIResponder <UIApplicationDelegate, FlutterPluginRegistry,
    // FlutterAppLifeCycleProvider>). The snippet from the
    // flutter_local_notifications README - a bare
    // `delegate = self as? UNUserNotificationCenterDelegate` - therefore
    // assigns *nil*, wiping out the delegate the plugin just installed in
    // GeneratedPluginRegistrant.register above. Foreground notifications and
    // notification taps stop being delivered.
    // Only assign when the cast actually succeeds, so a future delegate
    // implementation here still works.
    if let notificationDelegate = self as? UNUserNotificationCenterDelegate {
      UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
