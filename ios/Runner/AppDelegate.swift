import AuthenticationServices
import Flutter
import UIKit

final class NativeWebAuthHandler: NSObject, ASWebAuthenticationPresentationContextProviding {
  static let shared = NativeWebAuthHandler()
  private var currentSession: ASWebAuthenticationSession?

  func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "NativeWebAuthHandler") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.sotayyte/web_auth",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "authenticate":
        guard
          let args = call.arguments as? [String: Any],
          let urlString = args["url"] as? String,
          let callbackScheme = args["callbackScheme"] as? String,
          let authURL = URL(string: urlString)
        else {
          result(
            FlutterError(
              code: "INVALID_ARGS",
              message: "Thiếu URL hoặc callbackScheme xác thực.",
              details: nil
            )
          )
          return
        }
        self.startSession(url: authURL, callbackScheme: callbackScheme, result: result)
      case "cancel":
        self.currentSession?.cancel()
        self.currentSession = nil
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startSession(
    url: URL,
    callbackScheme: String,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.main.async {
      self.currentSession?.cancel()
      self.currentSession = nil

      // Đóng mọi SFSafariViewController cũ nếu còn treo trên màn hình
      if let rootVC = self.activeWindow()?.rootViewController,
        let presented = rootVC.presentedViewController
      {
        let className = String(describing: type(of: presented))
        if className.contains("Safari") {
          presented.dismiss(animated: false, completion: nil)
        }
      }

      let session = ASWebAuthenticationSession(
        url: url,
        callbackURLScheme: callbackScheme
      ) { [weak self] callbackURL, error in
        DispatchQueue.main.async {
          self?.currentSession = nil
          if let error = error {
            let nsError = error as NSError
            if nsError.domain == ASWebAuthenticationSessionErrorDomain
              && nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue
            {
              result(
                FlutterError(
                  code: "CANCELED",
                  message: "Người dùng đã hủy đăng nhập.",
                  details: nil
                )
              )
              return
            }
            result(
              FlutterError(
                code: "WEB_AUTH_ERROR",
                message: error.localizedDescription,
                details: nil
              )
            )
            return
          }

          guard let callbackURL = callbackURL else {
            result(
              FlutterError(
                code: "NO_CALLBACK",
                message: "Không nhận được URL phản hồi xác thực.",
                details: nil
              )
            )
            return
          }
          result(callbackURL.absoluteString)
        }
      }

      session.presentationContextProvider = self
      session.prefersEphemeralWebBrowserSession = false

      if session.start() {
        self.currentSession = session
      } else {
        result(
          FlutterError(
            code: "START_FAILED",
            message: "Không thể khởi chạy phiên xác thực trình duyệt.",
            details: nil
          )
        )
      }
    }
  }

  private func activeWindow() -> UIWindow? {
    let windowScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    for scene in windowScenes where scene.activationState == .foregroundActive {
      if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
        return keyWindow
      }
      if let firstWindow = scene.windows.first {
        return firstWindow
      }
    }
    for scene in windowScenes {
      if let firstWindow = scene.windows.first {
        return firstWindow
      }
    }
    return nil
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return activeWindow() ?? ASPresentationAnchor()
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    NativeWebAuthHandler.shared.register(with: engineBridge.pluginRegistry)
  }
}
