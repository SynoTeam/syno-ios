//
//  ContactsDeleteRow.swift
//  Syno
//

import SwiftUI

struct ContactsDeleteRow: View {
  let contact: Contact
  let isSelected: Bool
  let onToggle: () -> Void

  var body: some View {
    Button(action: onToggle) {
      HStack(spacing: 12) {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 28, weight: .medium))
          .foregroundStyle(isSelected ? .gray900 : .gray300)
          .frame(width: 28, height: 28)

        avatar

        VStack(alignment: .leading, spacing: 0) {
          Text(contact.name)
            .typeStyle(.callout)
            .foregroundStyle(.gray950)
            .lineLimit(1)
            .truncationMode(.tail)

          if !contact.group.isEmpty {
            Text(contact.group)
              .typeStyle(.footnote)
              .foregroundStyle(.gray400)
              .lineLimit(1)
              .truncationMode(.tail)
          }
        }

        Spacer()
      }
      .padding(.horizontal, 8)
      .frame(maxWidth: .infinity, minHeight: 60)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(contact.name), \(isSelected ? "선택됨" : "선택 안 됨")")
  }

  @ViewBuilder
  private var avatar: some View {
    if
      let data = contact.profileImageData,
      let uiImage = UIImage(data: data)
    {
      Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    } else {
      InitialAvatar(name: contact.name, size: 44, cornerRadius: 12)
    }
  }
}

#Preview {
  VStack {
    ContactsDeleteRow(
      contact: Contact(name: "Sample User", role: "", company: "", group: "Design"),
      isSelected: true,
      onToggle: {}
    )
    ContactsDeleteRow(
      contact: Contact(name: "Demo Contact", role: "", company: "", group: "Design"),
      isSelected: false,
      onToggle: {}
    )
  }
  .padding()
  .background(Color.gray50)
}
