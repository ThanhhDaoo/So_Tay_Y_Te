import AuthenticationServices
import Flutter
import ImageIO
import UIKit
import UserNotifications
import Vision

final class NativeVisionOcrHandler: NSObject {
  static let shared = NativeVisionOcrHandler()

  func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "NativeVisionOcrHandler") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.sotayyte/native_ocr",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "recognizeText":
        guard
          let args = call.arguments as? [String: Any],
          let imagePath = args["imagePath"] as? String,
          !imagePath.isEmpty
        else {
          result(
            FlutterError(
              code: "INVALID_ARGS",
              message: "Đường dẫn ảnh quét OCR không hợp lệ.",
              details: nil
            )
          )
          return
        }
        self.recognizeText(at: imagePath, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func recognizeText(at imagePath: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      autoreleasepool {
        let fileURL = URL(fileURLWithPath: imagePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "FILE_NOT_FOUND",
                message: "Không tìm thấy tệp ảnh đơn thuốc tại đường dẫn đã chọn.",
                details: nil
              )
            )
          }
          return
        }

        // Tạo CGImage đã xoay chuẩn chiều EXIF và giới hạn tối đa 2200px để tránh tràn RAM trên iPhone
        var cgImage: CGImage?
        if let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) {
          let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 2200,
          ]
          cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbOptions as CFDictionary)
        }

        if cgImage == nil, let fallbackUiImage = UIImage(contentsOfFile: imagePath) {
          cgImage = fallbackUiImage.cgImage
        }

        guard let targetImage = cgImage else {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "IMAGE_DECODE_FAILED",
                message: "Không thể giải mã hình ảnh đã chọn.",
                details: nil
              )
            )
          }
          return
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        if #available(iOS 16.0, *) {
          request.revision = VNRecognizeTextRequestRevision3
          request.automaticallyDetectsLanguage = true
        }

        if let supported = try? request.supportedRecognitionLanguages() {
          var preferred: [String] = []
          for lang in ["vi-VN", "vi", "en-US", "fr-FR"] where supported.contains(lang) {
            preferred.append(lang)
          }
          if !preferred.isEmpty {
            request.recognitionLanguages = preferred
          }
        }

        let handler = VNImageRequestHandler(cgImage: targetImage, options: [:])
        do {
          try handler.perform([request])
          let observations = request.results ?? []
          let formattedText = Self.assembleVisualRows(from: observations)
          DispatchQueue.main.async {
            result(formattedText)
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "VISION_OCR_ERROR",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }
    }
  }

  /// Ghép các vùng chữ trên cùng 1 dòng ngang của bảng đơn thuốc (VD: Tên thuốc bên trái + Số lượng bên phải)
  private static func assembleVisualRows(from observations: [VNRecognizedTextObservation]) -> String {
    struct BoxItem {
      let text: String
      let minX: CGFloat
      let midY: CGFloat
      let height: CGFloat
    }

    var items: [BoxItem] = []
    items.reserveCapacity(observations.count)
    for obs in observations {
      guard let topCandidate = obs.topCandidates(1).first else { continue }
      let trimmed = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty { continue }
      let box = obs.boundingBox
      items.append(
        BoxItem(
          text: trimmed,
          minX: box.minX,
          midY: box.midY,
          height: box.height
        )
      )
    }

    guard !items.isEmpty else { return "" }

    // Hệ tọa độ Vision có gốc (0,0) ở góc dưới bên trái -> midY lớn hơn nằm ở phía trên
    items.sort { a, b in
      if abs(a.midY - b.midY) > 0.012 {
        return a.midY > b.midY
      }
      return a.minX < b.minX
    }

    var rows: [[BoxItem]] = []
    for item in items {
      if var lastRow = rows.last {
        let avgY = lastRow.reduce(CGFloat(0)) { $0 + $1.midY } / CGFloat(lastRow.count)
        let avgH = lastRow.reduce(CGFloat(0)) { $0 + $1.height } / CGFloat(lastRow.count)
        let threshold = max(CGFloat(0.012), min(avgH, item.height) * 0.55)
        if abs(item.midY - avgY) <= threshold {
          lastRow.append(item)
          rows[rows.count - 1] = lastRow
          continue
        }
      }
      rows.append([item])
    }

    let lines: [String] = rows.map { row in
      let sortedRow = row.sorted { $0.minX < $1.minX }
      return sortedRow.map { $0.text }.joined(separator: "   ")
    }

    return lines.joined(separator: "\n")
  }
}

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
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    NativeWebAuthHandler.shared.register(with: engineBridge.pluginRegistry)
    NativeVisionOcrHandler.shared.register(with: engineBridge.pluginRegistry)
  }
}
