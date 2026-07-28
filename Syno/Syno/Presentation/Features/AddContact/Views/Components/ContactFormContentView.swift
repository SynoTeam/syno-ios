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
  @Binding var url: String
  @Binding var address: String
  @Binding var birthday: Date?
  @Binding var anniversary: Date?
  @Binding var socialLinks: [ContactSocialLink]
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
      additionalInfoSection
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
          focusedField.wrappedValue = .url
        }
        Divider()
          .background(.gray50)
        AddContactTextField(
          "URL",
          text: $url,
          field: .url,
          submitLabel: .done,
          focusedField: focusedField
        ) {
          focusedField.wrappedValue = .address
        }
        .keyboardType(.URL)
        .textInputAutocapitalization(.never)
      }
    }
  }

  private var additionalInfoSection: some View {
    AddContactFormSection(title: "추가 정보") {
      VStack(spacing: 0) {
        AddContactTextField(
          "주소",
          text: $address,
          field: .address,
          submitLabel: .done,
          focusedField: focusedField
        ) {
          focusedField.wrappedValue = nil
        }

        Divider().background(.gray50)

        dateRow(title: "생일", date: $birthday)

        Divider().background(.gray50)

        dateRow(title: "기념일", date: $anniversary)

        Divider().background(.gray50)

        socialLinksContent
      }
      .padding(.horizontal, 22)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 22))
    }
  }

  private func dateRow(title: String, date: Binding<Date?>) -> some View {
    HStack(spacing: 12) {
      Text(title)
        .typeStyle(.body)
        .foregroundStyle(.gray950)

      Spacer()

      DatePicker(
        title,
        selection: Binding(
          get: { date.wrappedValue ?? Date() },
          set: { date.wrappedValue = $0 }
        ),
        displayedComponents: .date
      )
      .labelsHidden()
      .datePickerStyle(.compact)
      .tint(.violet500)

      if date.wrappedValue != nil {
        Button {
          date.wrappedValue = nil
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.gray400)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) 지우기")
      }
    }
    .frame(height: 54)
  }

  private var socialLinksContent: some View {
    VStack(spacing: 0) {
      ForEach(socialLinks.indices, id: \.self) { index in
        socialLinkRow(at: index)

        if index < socialLinks.count - 1 {
          Divider().background(.gray50)
        }
      }

      Button {
        socialLinks.append(ContactSocialLink(platform: "Instagram", handle: ""))
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "plus")
            .font(.system(size: 14, weight: .semibold))
          Text("항목 추가하기")
            .typeStyle(.subheadline)
        }
        .foregroundStyle(.violet500)
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  private func socialLinkRow(at index: Int) -> some View {
    HStack(spacing: 10) {
      Picker("플랫폼", selection: socialLinkPlatformBinding(at: index)) {
        ForEach(socialPlatforms, id: \.self) { platform in
          Text(platform).tag(platform)
        }
      }
      .pickerStyle(.menu)
      .tint(.gray700)
      .frame(width: 112, alignment: .leading)

      TextField("계정 또는 URL", text: socialLinkHandleBinding(at: index))
        .typeStyle(.body)
        .foregroundStyle(.gray950)
        .lineLimit(1)
        .textInputAutocapitalization(.never)

      Button {
        socialLinks.remove(at: index)
      } label: {
        Image(systemName: "minus.circle.fill")
          .foregroundStyle(.gray400)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("소셜 링크 삭제")
    }
    .frame(height: 54)
  }

  private func socialLinkPlatformBinding(at index: Int) -> Binding<String> {
    Binding(
      get: { socialLinks[index].platform },
      set: { socialLinks[index].platform = $0 }
    )
  }

  private func socialLinkHandleBinding(at index: Int) -> Binding<String> {
    Binding(
      get: { socialLinks[index].handle },
      set: { socialLinks[index].handle = $0 }
    )
  }

  private var socialPlatforms: [String] {
    ["Instagram", "LinkedIn", "X", "Facebook", "YouTube", "기타"]
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
