//
//  AddContactField.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

/// 연락처 추가 폼에서 키보드 포커스를 이동할 입력 필드입니다.
enum AddContactField: Hashable {
  case familyName
  case givenName
  case email
  case phone
  case linkedInURL
  case note
}
