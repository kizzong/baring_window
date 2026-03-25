import Flutter
import UIKit
import UserNotifications
import AVFoundation
import EventKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().delegate = self

    // MethodChannel 설정
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.baring/settings", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "openAppSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          DispatchQueue.main.async {
            UIApplication.shared.open(url, completionHandler: { success in
              result(success)
            })
          }
        } else {
          result(false)
        }

      case "checkPermissions":
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let camera = (cameraStatus == .authorized)

        let ekStatus = EKEventStore.authorizationStatus(for: .event)
        let calendar = (ekStatus == .authorized) || {
          if #available(iOS 17.0, *) {
            return ekStatus == .fullAccess
          }
          return false
        }()

        UNUserNotificationCenter.current().getNotificationSettings { settings in
          let notification = (settings.authorizationStatus == .authorized)
          DispatchQueue.main.async {
            result([
              "camera": camera,
              "notification": notification,
              "calendar": calendar
            ])
          }
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }
}
