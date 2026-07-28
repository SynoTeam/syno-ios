//
//  AccountResetService.swift
//  Syno
//
//  Created by Codex on 7/28/26.
//

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
      try modelContext.delete(model: StoredContact.self)
      try modelContext.delete(model: StoredNote.self)
      try modelContext.delete(model: UserProfile.self)
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }

  /// 노트 원본 이미지가 차지하는 총 저장공간을 바이트 단위로 반환합니다.
  func noteStorageUsage() throws -> Int64 {
    let notes = try modelContext.fetch(FetchDescriptor<StoredNote>())
    return notes.reduce(into: Int64(0)) { total, note in
      total += Int64(note.imageData?.count ?? 0)
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
      guard let contactID = note.contactId, let imageData = note.imageData else {
        continue
      }
      bytesByContactID[contactID, default: 0] += Int64(imageData.count)
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
      for note in notes where note.imageData != nil {
        note.imageData = nil
      }
      try modelContext.save()
    } catch {
      modelContext.rollback()
      throw error
    }
  }
}
