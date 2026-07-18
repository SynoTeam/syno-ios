//
//  ContactFormContentView.swift
//  Syno
//
//  Created by 이승진 on 7/18/26.
//

import SwiftUI

/// 연락처 추가와 내 프로필 편집에서 공통으로 사용하는 연락처 입력 폼입니다.
struct ContactFormContentView: View {
  @Binding var familyName: String
  @Binding var givenName: String
  @Binding var email: String
  @Binding var countryCode: String
  @Binding var phone: String
  @Binding var linkedInURL: String
  @Binding var group: String
  @Binding var note: String

  let noteLimit: Int
  let focusedField: FocusState<AddContactField?>.Binding
  let onCountryCodeTap: () -> Void
  let onGroupTap: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 28) {
      nameSection
      contactSection
      groupSection
      noteSection
    }
  }

  private var nameSection: some View {
    AddContactFormSection(title: "이름") {
      AddContactStackedFields {
        AddContactTextField(
          "성",
          text: $familyName,
          field: .familyName,
          focusedField: focusedField
        ) {
          focusedField.wrappedValue = .givenName
        }
        Divider()
          .background(.gray50)
        AddContactTextField(
          "이름",
          text: $givenName,
          field: .givenName,
          focusedField: focusedField
        ) {
          focusedField.wrappedValue = .email
        }
      }
    }
  }

  private var contactSection: some View {
    AddContactFormSection(title: "연락처") {
      AddContactStackedFields {
        AddContactTextField(
          "이메일",
          text: $email,
          field: .email,
          focusedField: focusedField
        ) {
          focusedField.wrappedValue = .phone
        }
        .keyboardType(.emailAddress)
        .textInputAutocapitalization(.never)
        Divider()
          .background(.gray50)
        AddContactPhoneNumberField(
          countryCode: countryCode,
          phone: $phone,
          focusedField: focusedField,
          onCountryCodeTap: onCountryCodeTap
        ) {
          focusedField.wrappedValue = .linkedInURL
        }
        Divider()
          .background(.gray50)
        AddContactTextField(
          "링크드인 URL",
          text: $linkedInURL,
          field: .linkedInURL,
          submitLabel: .done,
          focusedField: focusedField
        ) {
          focusedField.wrappedValue = nil
        }
        .keyboardType(.URL)
        .textInputAutocapitalization(.never)
      }
    }
  }

  private var groupSection: some View {
    AddContactFormSection(title: "그룹 정보") {
      AddContactSelectionRow(
        title: group.isEmpty ? "그룹 선택하기" : group
      ) {
        focusedField.wrappedValue = nil
        onGroupTap()
      }
    }
  }

  private var noteSection: some View {
    AddContactFormSection(title: "한 줄 기록") {
      AddContactNoteField(
        note: $note,
        noteLimit: noteLimit,
        focusedField: focusedField
      )
    }
  }
}
