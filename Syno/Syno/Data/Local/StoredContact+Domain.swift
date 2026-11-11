import Foundation

/// 앱의 `Contact`와 저장 모델 사이의 변환입니다.
/// 공유 확장은 Domain 타입을 모르므로 이 파일은 앱 타깃에만 둡니다.
extension StoredContact {
  convenience init(contact: Contact) {
    self.init(
      id: contact.id,
      name: contact.name,
      role: contact.role,
      company: contact.company,
      email: contact.email,
      phone: contact.phone,
      url: contact.url,
      address: contact.address,
      birthday: contact.birthday,
      anniversary: contact.anniversary,
      socialLinks: contact.socialLinks,
      group: contact.group,
      note: contact.note,
      profileImageData: contact.profileImageData,
      isFavorite: contact.isFavorite,
      isPinned: contact.isPinned,
      isMe: contact.isMe
    )
  }

  /// 저장된 연락처를 화면에서 사용하는 `Contact` 엔티티로 변환합니다.
  var contact: Contact {
    Contact(
      id: id,
      name: name,
      role: role,
      company: company,
      email: email,
      phone: phone,
      url: url,
      address: address,
      birthday: birthday,
      anniversary: anniversary,
      socialLinks: socialLinks,
      group: group,
      note: note,
      profileImageData: profileImageData,
      isFavorite: isFavorite,
      isPinned: isPinned,
      isMe: isMe
    )
  }

  /// 화면에서 수정된 `Contact` 값을 저장 모델에 반영합니다.
  func update(with contact: Contact) {
    name = contact.name
    role = contact.role
    company = contact.company
    email = contact.email
    phone = contact.phone
    url = contact.url
    address = contact.address
    birthday = contact.birthday
    anniversary = contact.anniversary
    socialLinks = contact.socialLinks
    group = contact.group
    note = contact.note
    profileImageData = contact.profileImageData
    isFavorite = contact.isFavorite
    isPinned = contact.isPinned
    isMe = contact.isMe
  }
}
