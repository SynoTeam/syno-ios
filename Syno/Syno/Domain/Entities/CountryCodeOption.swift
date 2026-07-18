//
//  CountryCodeOption.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import Foundation

/// 연락처 폼에서 선택할 수 있는 국가번호 옵션입니다.
struct CountryCodeOption: Identifiable, Hashable {
  /// 실제 전화번호에 붙는 국가번호입니다.
  let code: String

  /// 국가번호 목록에 표시할 국가 이름입니다.
  let countryName: String

  /// 국가번호 옵션의 고유 식별자입니다.
  var id: String {
    code
  }

  /// 국가 이름과 국가번호를 함께 보여주는 표시 문자열입니다.
  var displayTitle: String {
    "\(countryName) \(code)"
  }
}
