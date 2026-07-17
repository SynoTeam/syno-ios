//
//  MyProfileView.swift
//  Syno
//
//  Created by 이승진 on 7/16/26.
//

import SwiftUI

struct MyProfileView: View {
  @Environment(\.dismiss) private var dismiss
  
  let contact: Contact
  
  init(
    contact: Contact = Contact(
      name: "내 프로필",
      role: "Product Designer",
      company: "",
      email: "me@syno.app",
      phone: "010-0000-0000",
      linkedInURL: "https://www.linkedin.com/in/syno"
    )
  ) {
    self.contact = contact
  }
  
  var body: some View {
    VStack(spacing: 0) {
      topBar
      
      ScrollView {
        VStack(spacing: 28) {
          profileHeader
          infoCard
        }
        .padding(.horizontal, 22)
        .padding(.top, 28)
        .padding(.bottom, 120)
      }
      
      chatButton
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
    }
    .background(Color(.systemGroupedBackground))
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
  }
  
  private var topBar: some View {
    HStack {
      circleIconButton(systemName: "chevron.left") {
        dismiss()
      }
      
      Spacer()
      
      Text(contact.name)
        .typeStyle(.navigationTitle)
        .foregroundStyle(.gray950)
      
      Spacer()
      
      circleIconButton(systemName: "gearshape") {}
    }
    .padding(.horizontal, 22)
    .padding(.top, 14)
  }
  
  private var profileHeader: some View {
    VStack(spacing: 22) {
      Image(.logo)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 136, height: 136)
        .clipShape(Circle())
      
      VStack(spacing: 8) {
        Text(displayName)
          .typeStyle(.profileName)
          .foregroundStyle(.gray950)
        
        Text(contact.role)
          .typeStyle(.contactName)
          .foregroundStyle(.gray500)
          .multilineTextAlignment(.center)
      }
    }
  }
  
  private var infoCard: some View {
    VStack(alignment: .leading, spacing: 24) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 24) {
          profileInfo(label: "이메일", value: emailText)
          profileInfo(label: "성/ Surname", value: phoneText)
          profileInfo(label: "링크드인 URL", value: linkedInText, lineLimit: 1)
        }
        
        Spacer()
        
        Button {} label: {
          Image(systemName: "pencil")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.gray700)
            .frame(width: 48, height: 48)
            .background(.gray25)
            .clipShape(Circle())
        }
        .accessibilityLabel("Edit Contact")
      }
    }
    .padding(28)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 22))
  }
  
  private func profileInfo(label: String, value: String, lineLimit: Int? = nil) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(label)
        .typeStyle(.formLabel)
        .foregroundStyle(.gray400)
      
      Text(value)
        .typeStyle(.formValue)
        .foregroundStyle(.gray950)
        .lineLimit(lineLimit)
        .truncationMode(.tail)
    }
  }
  
  private var chatButton: some View {
    Button {} label: {
      HStack(spacing: 10) {
        Image(systemName: "plus.circle.fill")
          .font(.system(size: 24, weight: .semibold))
        
        Text("나와의 채팅")
          .typeStyle(.primaryButton)
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, minHeight: 58)
      .background(.brand100)
      .clipShape(Capsule())
    }
  }
  
  private func circleIconButton(systemName: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 22, weight: .medium))
        .foregroundStyle(.gray950)
        .frame(width: 52, height: 52)
        .background(.white)
        .clipShape(Circle())
    }
  }
  
  private var displayName: String {
    contact.name
  }
  
  private var emailText: String {
    contact.email.isEmpty ? "me@syno.app" : contact.email
  }
  
  private var phoneText: String {
    contact.phone.isEmpty ? "010-0000-0000" : contact.phone
  }
  
  private var linkedInText: String {
    contact.linkedInURL.isEmpty ? "https://www.linkedin.com/in/syno" : contact.linkedInURL
  }
}

#Preview {
  MyProfileView()
}
