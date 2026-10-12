//
//  View+PermissionAlert.swift
//  Syno
//

import AVFoundation
import Photos
import Speech
import SwiftUI
import UIKit

/// 사용자가 거부하면 시스템 팝업이 다시 뜨지 않는 권한 종류입니다.
enum PermissionKind: Identifiable {
  case microphone
  case camera
  case speechRecognition
  case photoLibrary

  var id: Self { self }

  var title: String {
    switch self {
    case .microphone: "마이크 권한이 필요해요"
    case .camera: "카메라 권한이 필요해요"
    case .speechRecognition: "음성 인식 권한이 필요해요"
    case .photoLibrary: "사진 저장 권한이 필요해요"
    }
  }

  var message: String {
    switch self {
    case .microphone:
      "음성 메모를 녹음하려면 설정에서 Syno의 마이크 접근을 허용해 주세요."
    case .camera:
      "사진을 촬영하려면 설정에서 Syno의 카메라 접근을 허용해 주세요."
    case .speechRecognition:
      "음성 메모를 텍스트로 변환하려면 설정에서 Syno의 음성 인식을 허용해 주세요."
    case .photoLibrary:
      "사진을 저장하려면 설정에서 Syno의 사진 추가 권한을 허용해 주세요."
    }
  }
}

/// 권한 확인 결과입니다. 설정 이동 안내는 `previouslyDenied`일 때만 필요합니다.
enum PermissionResult {
  case granted
  /// 이번에 뜬 시스템 팝업에서 방금 거절한 경우입니다. 사용자가 직접 선택한 직후라 추가 안내를 하지 않습니다.
  case declinedInPrompt
  /// 이전에 이미 거절해서 시스템 팝업이 다시 뜨지 않는 경우입니다.
  case previouslyDenied
}

enum PermissionChecker {
  /// 카메라 권한을 확인하고, 아직 정하지 않았다면 시스템 팝업으로 요청합니다.
  static func requestCameraAccess() async -> PermissionResult {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      return .granted
    case .notDetermined:
      return await AVCaptureDevice.requestAccess(for: .video) ? .granted : .declinedInPrompt
    default:
      return .previouslyDenied
    }
  }

  /// 사진 보관함에 저장(추가)하는 권한을 확인하고, 아직 정하지 않았다면 시스템 팝업으로 요청합니다.
  static func requestPhotoSaveAccess() async -> PermissionResult {
    switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
    case .authorized, .limited:
      return .granted
    case .notDetermined:
      let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
      return (status == .authorized || status == .limited) ? .granted : .declinedInPrompt
    default:
      return .previouslyDenied
    }
  }

  /// 음성 인식 권한을 확인하고, 아직 정하지 않았다면 시스템 팝업으로 요청합니다.
  static func requestSpeechRecognitionAccess() async -> PermissionResult {
    switch SFSpeechRecognizer.authorizationStatus() {
    case .authorized:
      return .granted
    case .notDetermined:
      let isAuthorized = await withCheckedContinuation { continuation in
        SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
      }
      return isAuthorized ? .granted : .declinedInPrompt
    default:
      return .previouslyDenied
    }
  }
}

extension View {
  /// 권한이 거부된 경우 설정 앱으로 이동할 수 있는 안내 알럿을 띄웁니다.
  func permissionDeniedAlert(_ kind: Binding<PermissionKind?>) -> some View {
    alert(
      kind.wrappedValue?.title ?? "",
      isPresented: Binding(
        get: { kind.wrappedValue != nil },
        set: { isPresented in
          if !isPresented {
            kind.wrappedValue = nil
          }
        }
      )
    ) {
      Button("설정으로 이동") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
      Button("취소", role: .cancel) {}
    } message: {
      Text(kind.wrappedValue?.message ?? "")
    }
  }
}
