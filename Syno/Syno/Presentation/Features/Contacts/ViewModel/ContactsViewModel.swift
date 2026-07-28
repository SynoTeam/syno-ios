//
//  ContactsViewModel.swift
//  Syno
//
//  Created by 이승진 on 7/16/26.
//

import Foundation
import Observation

@Observable
final class ContactsViewModel {
  private(set) var contacts: [Contact]
  private(set) var persistenceError: String?

  private let repository: any ContactRepository
  private let myProfileId: UUID
  
  init(
    repository: any ContactRepository,
    contacts: [Contact]? = nil,
    myProfileId: UUID,
    myProfileName: String? = nil
  ) {
    self.repository = repository
    self.myProfileId = myProfileId
    self.contacts = contacts ?? Self.mockContacts(myProfileId: myProfileId, myProfileName: myProfileName)
  }
  
  var myContact: Contact? {
    contacts.first { $0.isMe }
  }
  
  var favoriteContacts: [Contact] {
    contacts.filter { $0.isFavorite && !$0.isMe }
  }
  
  var regularContacts: [Contact] {
    contacts.filter { !$0.isMe }
  }
  
  var regularContactCount: Int {
    regularContacts.count
  }

  /// 저장된 연락처에 사용된 중복 없는 그룹 목록입니다.
  var existingGroups: [String] {
    GroupOptions.merged(
      existingGroups: contacts.map(\.group),
      draftGroup: ""
    )
  }
  
  func loadContacts() {
    do {
      let storedContacts = try repository.fetchAll()
      let regularContacts = storedContacts.filter { $0.id != myProfileId }
      contacts = contacts.filter(\.isMe) + regularContacts

      if var myContact = storedContacts.first(where: { $0.id == myProfileId }) {
        myContact.isMe = true
        updateLocalContact(myContact)
      }
      persistenceError = nil
    } catch {
      handle(error)
    }
  }

  func saveMyContact(_ contact: Contact) {
    persist(contact) {
      updateLocalContact(contact)
    }
  }

  func addContact(_ contact: Contact) {
    persist(contact) {
      contacts.append(contact)
    }
  }
  
  @discardableResult
  func deleteContact(id: Contact.ID) -> Bool {
    deleteContacts(ids: [id]) != nil
  }

  /// 선택한 연락처를 순서대로 삭제합니다. 일부 삭제 후 저장소 오류가 발생하면
  /// 이미 삭제된 연락처만 목록에서 제거하고 실패를 호출자에게 알립니다.
  @discardableResult
  func deleteContacts(ids: Set<Contact.ID>) -> Int? {
    let targetIDs = contacts
      .filter { ids.contains($0.id) && !$0.isMe }
      .map(\.id)

    guard !targetIDs.isEmpty else {
      return nil
    }

    var deletedIDs = Set<Contact.ID>()

    for id in targetIDs {
      do {
        try repository.delete(id: id)
        deletedIDs.insert(id)
      } catch {
        contacts.removeAll { deletedIDs.contains($0.id) }
        handleDelete(error)
        return nil
      }
    }

    contacts.removeAll { deletedIDs.contains($0.id) }
    persistenceError = nil
    return deletedIDs.count
  }
  
  @discardableResult
  func toggleFavorite(id: Contact.ID) -> Bool? {
    guard let index = contacts.firstIndex(where: { $0.id == id && !$0.isMe }) else {
      return nil
    }

    let isFavorite = !contacts[index].isFavorite
    return setFavorite(id: id, isFavorite: isFavorite) ? isFavorite : nil
  }

  @discardableResult
  func setFavorite(id: Contact.ID, isFavorite: Bool) -> Bool {
    guard let index = contacts.firstIndex(where: { $0.id == id && !$0.isMe }) else {
      return false
    }

    guard contacts[index].isFavorite != isFavorite else {
      persistenceError = nil
      return true
    }

    var updatedContact = contacts[index]
    updatedContact.isFavorite = isFavorite
    return persist(updatedContact) {
      contacts[index] = updatedContact
    }
  }

  func clearPersistenceError() {
    persistenceError = nil
  }

  @discardableResult
  private func persist(_ contact: Contact, updateLocalState: () -> Void) -> Bool {
    do {
      try repository.save(contact)
      updateLocalState()
      persistenceError = nil
      return true
    } catch {
      handle(error)
      return false
    }
  }

  private func updateLocalContact(_ contact: Contact) {
    guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else {
      contacts.append(contact)
      return
    }
    contacts[index] = contact
  }

  private func handle(_ error: Error) {
    persistenceError = "연락처를 저장하지 못했습니다. 다시 시도해주세요."
  }

  private func handleDelete(_ error: Error) {
    persistenceError = "연락처를 삭제하지 못했습니다. 다시 시도해주세요."
  }
}

private extension ContactsViewModel {
  static func mockContacts(myProfileId: UUID, myProfileName: String?) -> [Contact] {
    [
      Contact(
        id: myProfileId,
        name: myProfileName ?? "내 프로필",
        role: "",
        company: "",
        isMe: true
      )
    ]
  }
}
