import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let notificationChannelName = "com.chanomhub.chanolite/download_notifications"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    configureNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureNotifications() {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(name: notificationChannelName, binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "notifyDownloadStarted" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let arguments = call.arguments as? [String: Any],
            let fileName = arguments["fileName"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing fileName", details: nil))
        return
      }

      self?.scheduleNotification(for: fileName)
      result(nil)
    }
  }

  private func scheduleNotification(for fileName: String) {
    if #available(iOS 10.0, *) {
      let content = UNMutableNotificationContent()
      content.title = "Download Started"
      content.body = "Starting download for \(fileName)"

      let request = UNNotificationRequest(
        identifier: "download-started-\(UUID().uuidString)",
        content: content,
        trigger: nil
      )

      UNUserNotificationCenter.current().add(request) { _ in }
    }
  }
}
