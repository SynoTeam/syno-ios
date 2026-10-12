import Foundation

/// 채팅 목록에서 한 줄로 보여주는 단위입니다. 같이 보낸 사진들은 하나의 묶음으로 취급합니다.
enum ChatMessageItem: Identifiable {
  case single(Note)
  case photoGroup(notes: [Note])

  /// 목록에서 이 줄을 가리키는 식별자입니다. 묶음은 첫 번째 사진의 id를 씁니다.
  var id: Note.ID {
    switch self {
    case let .single(note):
      note.id
    case let .photoGroup(notes):
      notes[0].id
    }
  }
}

extension ChatViewModel.MessageDaySection {
  /// 같은 날 같은 묶음 id를 가진 사진들을 첫 사진 위치에 하나로 모읍니다. 한 장뿐인 묶음은 일반 사진으로 취급합니다.
  var items: [ChatMessageItem] {
    var photosByGroup: [UUID: [Note]] = [:]
    for message in messages {
      if let groupId = message.photoGroupId, message.imageData != nil {
        photosByGroup[groupId, default: []].append(message)
      }
    }

    var emittedGroups: Set<UUID> = []
    var result: [ChatMessageItem] = []
    for message in messages {
      guard let groupId = message.photoGroupId, message.imageData != nil, let group = photosByGroup[groupId], group.count > 1 else {
        result.append(.single(message))
        continue
      }
      guard emittedGroups.insert(groupId).inserted else {
        continue
      }
      result.append(.photoGroup(notes: group))
    }
    return result
  }
}
