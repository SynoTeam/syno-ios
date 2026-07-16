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
  var isFavorite: Bool
  var isMe: Bool
  
  init(
    id: UUID = UUID(),
    name: String,
    role: String,
    company: String,
    isFavorite: Bool = false,
    isMe: Bool = false
  ) {
    self.id = id
    self.name = name
    self.role = role
    self.company = company
    self.isFavorite = isFavorite
    self.isMe = isMe
  }
}
