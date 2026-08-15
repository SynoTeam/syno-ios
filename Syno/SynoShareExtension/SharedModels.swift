//
//  SharedModels.swift
//  SynoShareExtension
//
//  메인 앱의 StoredContact/StoredNote와 동일한 스키마입니다.
//  App Group으로 공유되는 SwiftData 저장소를 함께 사용하기 위해
//  메인 앱 타겟과 별도로 유지합니다. 메인 앱의 스키마가 바뀌면 이 파일도 함께 수정해야 합니다.
//

import Foundation
import SwiftData

struct ContactSocialLink: Codable, Hashable {
  var platform: String
  var handle: String
}

@Model
final class StoredContact {
  var id: UUID = UUID()
  var name: String = ""
  var role: String = ""
  var company: String = ""
  var email: String = ""
  var phone: String = ""
  var url: String = ""
  var address: String = ""
  var birthday: Date?
  var anniversary: Date?
  var socialLinks: [ContactSocialLink] = []
  var group: String = ""
  var note: String = ""
  var profileImageData: Data?
  var isFavorite: Bool = false
  var isPinned: Bool = false
  var isMe: Bool = false
  var createdAt: Date = Date()

  init(
    id: UUID,
    name: String,
    role: String,
    company: String,
    email: String,
    phone: String,
    url: String,
    address: String,
    birthday: Date?,
    anniversary: Date?,
    socialLinks: [ContactSocialLink],
    group: String,
    note: String,
    profileImageData: Data?,
    isFavorite: Bool,
    isPinned: Bool = false,
    isMe: Bool,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.role = role
    self.company = company
    self.email = email
    self.phone = phone
    self.url = url
    self.address = address
    self.birthday = birthday
    self.anniversary = anniversary
    self.socialLinks = socialLinks
    self.group = group
    self.note = note
    self.profileImageData = profileImageData
    self.isFavorite = isFavorite
    self.isPinned = isPinned
    self.isMe = isMe
    self.createdAt = createdAt
  }
}

@Model
final class StoredNote {
  var id: UUID = UUID()
  var contactId: UUID?
  var contactName: String = ""
  var content: String = ""
  var imageData: Data?
  var voiceMemoData: Data?
  var voiceMemoDuration: TimeInterval?
  var voiceMemoWaveform: [Float]?
  var fileData: Data?
  var fileName: String?
  var fileSize: Int?
  var profileImageData: Data?
  var isFavorite: Bool = false
  var isPinned: Bool = false
  var createdAt: Date = Date()

  init(
    id: UUID,
    contactId: UUID?,
    contactName: String,
    content: String,
    imageData: Data?,
    voiceMemoData: Data? = nil,
    voiceMemoDuration: TimeInterval? = nil,
    voiceMemoWaveform: [Float]? = nil,
    fileData: Data? = nil,
    fileName: String? = nil,
    fileSize: Int? = nil,
    profileImageData: Data?,
    isFavorite: Bool,
    isPinned: Bool = false,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.contactId = contactId
    self.contactName = contactName
    self.content = content
    self.imageData = imageData
    self.voiceMemoData = voiceMemoData
    self.voiceMemoDuration = voiceMemoDuration
    self.voiceMemoWaveform = voiceMemoWaveform
    self.fileData = fileData
    self.fileName = fileName
    self.fileSize = fileSize
    self.profileImageData = profileImageData
    self.isFavorite = isFavorite
    self.isPinned = isPinned
    self.createdAt = createdAt
  }
}

enum SharedAppGroup {
  static let identifier = "group.com.synoteam.Syno"

  static var storeURL: URL {
    guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
      fatalError("App Group container unavailable: \(identifier)")
    }
    return containerURL.appendingPathComponent("Syno.sqlite")
  }
}
