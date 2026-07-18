//
//  ContactsViewModel.swift
//  Syno
//
//  Created by 이승진 on 7/16/26.
//

import Observation

@Observable
final class ContactsViewModel {
  private(set) var contacts: [Contact]
  
  init(
    contacts: [Contact]? = nil,
    myProfileName: String? = nil
  ) {
    self.contacts = contacts ?? Self.mockContacts(myProfileName: myProfileName)
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
  
  func addContact(_ contact: Contact) {
    contacts.append(contact)
  }

  func replaceRegularContacts(_ regularContacts: [Contact]) {
    contacts = contacts.filter(\.isMe) + regularContacts
  }
  
  func updateContact(_ contact: Contact) {
    guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else {
      return
    }
    
    contacts[index] = contact
  }
  
  func deleteContact(id: Contact.ID) {
    contacts.removeAll { $0.id == id && !$0.isMe }
  }
  
  func toggleFavorite(id: Contact.ID) {
    guard let index = contacts.firstIndex(where: { $0.id == id && !$0.isMe }) else {
      return
    }
    
    contacts[index].isFavorite.toggle()
  }
}

private extension ContactsViewModel {
  static func mockContacts(myProfileName: String?) -> [Contact] {
    [
      Contact(
        name: myProfileName ?? "내 프로필",
        role: "",
        company: "",
        isMe: true
      )
    ]
  }
}
