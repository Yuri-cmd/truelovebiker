import Flutter
import UIKit
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Token APNs guardado: iOS lo entrega al arrancar, antes de que Dart
  /// inicialice Firebase, y en ese momento Firebase lo descarta.
  private var apnsTokenGuardado: Data?

  /// Reaplica el token guardado a Firebase (ya inicializado desde Dart).
  private func reaplicarApnsToken() -> String {
    guard let token = apnsTokenGuardado else { return "sin token guardado" }
    Messaging.messaging().apnsToken = token
    return Messaging.messaging().apnsToken != nil ? "OK" : "nil"
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    apnsTokenGuardado = deviceToken
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // [DIAG] confirma que iOS entregó el push a la app (visible en consola de Xcode).
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    NSLog("📩 [DIAG][NATIVO] push recibido: \(userInfo)")
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "AppChannelApns")?.messenger() {
      let channel = FlutterMethodChannel(name: "app.channel.apns", binaryMessenger: messenger)
      channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "reaplicarApnsToken" {
          result(self?.reaplicarApnsToken() ?? "sin AppDelegate")
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }
  }

  // Permite que la notificación se muestre mientras la app está abierta
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .badge, .sound])
  }
}
