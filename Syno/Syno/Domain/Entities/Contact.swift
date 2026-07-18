//
//  Contact.swift
//  Syno
//
//  Created by 이승진 on 7/16/26.
//

import Foundation

struct Contact: Identifiable, Equatable {
  let id: UUID
  var name: String
  var role: String
  var company: String
  var email: String
  var phone: String
  var linkedInURL: String
  var group: String
  var note: String
  var profileImageData: Data?
  var isFavorite: Bool
  var isMe: Bool
  
  init(
    id: UUID = UUID(),
    name: String,
    role: String,
    company: String,
    email: String = "",
    phone: String = "",
    linkedInURL: String = "",
    group: String = "",
    note: String = "",
    profileImageData: Data? = nil,
    isFavorite: Bool = false,
    isMe: Bool = false
  ) {
    self.id = id
    self.name = name
    self.role = role
    self.company = company
    self.email = email
    self.phone = phone
    self.linkedInURL = linkedInURL
    self.group = group
    self.note = note
    self.profileImageData = profileImageData
    self.isFavorite = isFavorite
    self.isMe = isMe
  }
}
