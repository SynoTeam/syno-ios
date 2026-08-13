//
//  AccountResetService.swift
//  Syno
//
//  Created by Codex on 7/28/26.
//

import CoreData
import Foundation
import SwiftData

/// 계정의 파생 데이터 삭제와 전체 데이터 초기화를 담당합니다.
@MainActor
final class AccountResetService {
  private let modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  /// 임베딩과 이미지 분석 결과처럼 다시 생성할 수 있는 파생 데이터만 삭제합니다.
  func clearTemporaryData() throws {
    do {
      try modelContext.delete(model: StoredContactEmbedding.self)
      try modelContext.delete(model: StoredNoteEmbedding.self)
      try modelContext.delete(model: StoredNoteImageAnalysis.self)
      try modelContext.delete(model: StoredNoteLinkPreview.self)
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  /// 로그아웃과 계정 탈퇴에 공통으로 사용하는 전체 데이터 초기화입니다.
  func resetAllData() throws {
    do {
      try modelContext.delete(model: StoredContactEmbedding.self)
      try modelContext.delete(model: StoredNoteEmbedding.self)
      try modelContext.delete(model: StoredNoteImageAnalysis.self)
      try modelContext.delete(model: StoredNoteLinkPreview.self)
      try modelContext.delete(model: StoredNoteVoiceTranscript.self)
      try modelContext.delete(model: StoredGroup.self)
      try modelContext.delete(model: StoredContact.self)
      try modelContext.delete(model: StoredNote.self)
      try modelContext.delete(model: UserProfile.self)
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  /// 로그아웃/탈퇴 직전에 호출해서, 방금 저장한 변경사항이 CloudKit으로 다 올라갈 때까지 잠깐 기다립니다.
  /// 이게 없으면: 공유 익스텐션 등으로 뒤늦게 들어와 아직 서버로 안 올라간 데이터가 있을 때,
  /// 그 업로드(export)와 방금 한 로컬 삭제가 겹쳐서 순서가 꼬이면 서버엔 삭제가 반영이 안 될 수
  /// 있고, "로그아웃 후 다시 들어왔을 때" 그 데이터가 iCloud에서 다시 내려와 되살아나는 문제가
  /// 생깁니다. 오프라인 등으로 동기화가 끝나지 않는 경우까지 무기한 기다리면 안 되므로 timeout 이후엔
  /// 그냥 진행합니다.
  func waitForPendingCloudKitExport(timeout: TimeInterval = 8) async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      let lock = NSLock()
      var didResume = false
      var observer: NSObjectProtocol?

      func finish() {
        lock.lock()
        defer { lock.unlock() }
        guard !didResume else { return }
        didResume = true
        if let observer {
          NotificationCenter.default.removeObserver(observer)
        }
        continuation.resume()
      }

      observer = NotificationCenter.default.addObserver(
        forName: NSPersistentCloudKitContainer.eventChangedNotification,
        object: nil,
        queue: .main
      ) { notification in
        guard
          let event = notification.userInfo?[
            NSPersistentCloudKitContainer.eventNotificationUserInfoKey
          ] as? NSPersistentCloudKitContainer.Event,
          event.type == .export,
          event.endDate != nil
        else { return }
        finish()
      }

      Task {
        try? await Task.sleep(for: .seconds(timeout))
        finish()
      }
    }
  }

  /// 노트 원본 미디어(사진/음성/파일)가 차지하는 총 저장공간을 바이트 단위로 반환합니다.
  func noteStorageUsage() throws -> Int64 {
    let notes = try modelContext.fetch(FetchDescriptor<StoredNote>())
    return notes.reduce(into: Int64(0)) { total, note in
      total += mediaByteCount(for: note)
    }
  }

  /// 바이트 수를 사용자에게 보여줄 저장공간 문자열로 변환합니다.
  func formattedStorageUsage() throws -> String {
    formattedStorageUsage(for: try noteStorageUsage())
  }

  /// 연락처별로 연결된 노트의 원본 이미지 용량을 계산합니다.
  /// 연락처가 없는 노트는 연락처별 목록에서 제외하며 전체 삭제 대상에는 포함됩니다.
  func mediaUsageByContact() throws -> [(contact: Contact, bytes: Int64)] {
    let notes = try modelContext.fetch(FetchDescriptor<StoredNote>())
    let contacts = try modelContext.fetch(FetchDescriptor<StoredContact>())
    let contactsByID = Dictionary(uniqueKeysWithValues: contacts.map { ($0.id, $0.contact) })
    var bytesByContactID: [UUID: Int64] = [:]

    for note in notes {
      guard let contactID = note.contactId else {
        continue
      }
      let bytes = mediaByteCount(for: note)
      guard bytes > 0 else {
        continue
      }
      bytesByContactID[contactID, default: 0] += bytes
    }

    return bytesByContactID.compactMap { contactID, bytes in
      contactsByID[contactID].map { (contact: $0, bytes: bytes) }
    }
    .sorted {
      $0.contact.name.localizedStandardCompare($1.contact.name) == .orderedAscending
    }
  }

  /// 모든 노트의 원본 이미지 데이터를 삭제하고 텍스트는 유지합니다.
  func deleteAllNoteMedia() throws {
    let notes = try modelContext.fetch(FetchDescriptor<StoredNote>())
    try deleteMedia(from: notes)
  }

  /// 특정 연락처와 연결된 노트의 원본 이미지 데이터만 삭제합니다.
  func deleteNoteMedia(forContactId contactId: UUID) throws {
    let descriptor = FetchDescriptor<StoredNote>(
      predicate: #Predicate { $0.contactId == contactId }
    )
    try deleteMedia(from: try modelContext.fetch(descriptor))
  }

  /// 바이트 수를 사용자에게 보여줄 저장공간 문자열로 변환합니다.
  func formattedStorageUsage(for bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    formatter.includesUnit = true
    return formatter.string(fromByteCount: bytes)
  }

  private func deleteMedia(from notes: [StoredNote]) throws {
    do {
      for note in notes {
        note.imageData = nil
        note.voiceMemoData = nil
        // 파일은 fileData만 지우면 fileName은 남아서 "아직 iCloud에서 안 받아온 파일"처럼
        // 보여 다운로드를 계속 재시도하게 되므로, 첨부 자체를 지운다는 의미로 같이 비웁니다.
        note.fileData = nil
        note.fileName = nil
        note.fileSize = nil
      }
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  private func mediaByteCount(for note: StoredNote) -> Int64 {
    Int64(note.imageData?.count ?? 0)
      + Int64(note.voiceMemoData?.count ?? 0)
      + Int64(note.fileData?.count ?? 0)
  }
}
