import UIKit
import Flutter
import GoogleMaps
import Foundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: "google_maps", binaryMessenger: controller.binaryMessenger)
    
    methodChannel.setMethodCallHandler { (call, result) in
        if call.method == "setApiKey", let apiKey = call.arguments as? String {
            GMSServices.provideAPIKey(apiKey)
            print("✅ Google Maps API Key Loaded: \(apiKey)")
        }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
