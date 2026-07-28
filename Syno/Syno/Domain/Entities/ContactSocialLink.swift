//
//  ContactSocialLink.swift
//  Syno
//
//  Created by Codex on 7/28/26.
//

import Foundation

/// 연락처에 연결된 소셜 플랫폼과 사용자 식별자입니다.
struct ContactSocialLink: Codable, Hashable {
  var platform: String
  var handle: String
}
