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
  
  func deleteContact(id: Contact.ID) {
    do {
      try repository.delete(id: id)
      contacts.removeAll { $0.id == id && !$0.isMe }
      persistenceError = nil
    } catch {
      handle(error)
    }
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
