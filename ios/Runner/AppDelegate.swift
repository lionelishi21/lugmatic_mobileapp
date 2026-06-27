import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let blurChannel = FlutterMethodChannel(name: "com.lugmatic/background_blur",
                                           binaryMessenger: controller.binaryMessenger)
    blurChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "setBlurEnabled" {
          let args = call.arguments as? [String: Any]
          let enabled = args?["enabled"] as? Bool ?? false
          // TODO: Implement native ML Kit background blur processing and LiveKit VideoProcessor bridging here
          print("Lugmatic Background Blur requested. Enabled: \(enabled). (Native implementation pending)")
          result(true)
      } else {
          result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
