//
//  SharedAppGroup.swift
//  SynoShareExtension
//
//  저장 모델과 스키마 목록(`SynoSchema`)은 앱 타깃의 `Data/Local` 파일을 함께 컴파일해서 씁니다.
//

import Foundation

/// 앱과 함께 쓰는 App Group 저장소 위치입니다.
enum SharedAppGroup {
  static let identifier = "group.com.synoteam.Syno"

  static var storeURL: URL {
    guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
      fatalError("App Group container unavailable: \(identifier)")
    }
    return containerURL.appendingPathComponent("Syno.sqlite")
  }
}
