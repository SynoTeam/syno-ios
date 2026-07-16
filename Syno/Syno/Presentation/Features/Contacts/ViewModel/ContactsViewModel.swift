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
  
  init(contacts: [Contact]? = nil) {
    self.contacts = contacts ?? Self.mockContacts
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
  static let mockContacts = [
    Contact(
      name: "Ian",
      role: "Marketing",
      company: "@apple",
      isMe: true
    ),
    Contact(
      name: "Hana Moon",
      role: "Marketing Manager",
      company: "@apple",
      isFavorite: true
    ),
    Contact(name: "Ian", role: "Product Designer", company: "@syno"),
    Contact(name: "Mina Kim", role: "iOS Developer", company: "@openai"),
    Contact(name: "Alex Lee", role: "Founder", company: "@studio"),
    Contact(name: "Jin Park", role: "Researcher", company: "@kaist"),
    Contact(name: "Sora Choi", role: "Brand Lead", company: "@naver")
  ]
}
