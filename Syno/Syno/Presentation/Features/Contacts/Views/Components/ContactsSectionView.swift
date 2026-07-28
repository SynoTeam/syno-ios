//
//  ContactsSectionView.swift
//  Syno
//
//  Created by 이승진 on 7/16/26.
//

import SwiftUI

struct ContactsSectionView: View {
  let title: String
  let count: Int
  let contacts: [Contact]
  let noteRepository: any NoteRepository
  let noteImageAnalyzer: any NoteImageAnalyzing
  let noteImageAnalysisRepository: any NoteImageAnalysisRepository
  let labelTranslator: any LabelTranslating
  let viewModel: ContactsViewModel
  let existingGroups: [String]
  let onContactUpdated: (Contact) -> Void
  let onContactDeleted: () -> Void
  @Binding var isCollapsed: Bool
  let onToggleFavorite: (Contact.ID) -> Void
  let onDelete: (Contact) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      
      if !isCollapsed {
        LazyVStack(spacing: 16) {
          ForEach(contacts) { contact in
            FavoriteSwipeRow(
              isFavorite: contact.isFavorite,
              onToggleFavorite: {
                onToggleFavorite(contact.id)
              },
              onDelete: {
                onDelete(contact)
              }
            ) {
              NavigationLink {
                ContactDetailView(
                  contact: contact,
                  noteRepository: noteRepository,
                  noteImageAnalyzer: noteImageAnalyzer,
                  noteImageAnalysisRepository: noteImageAnalysisRepository,
                  labelTranslator: labelTranslator,
                  viewModel: viewModel,
                  existingGroups: existingGroups,
                  onUpdated: onContactUpdated,
                  onDeleted: onContactDeleted
                )
              } label: {
                ContactsRowView(
                  name: contact.name,
                  group: contact.group,
                  profileImageData: contact.profileImageData
                )
              }
              .buttonStyle(.plain)
              .contextMenu {
                Button {
                  onToggleFavorite(contact.id)
                } label: {
                  Label(
                    contact.isFavorite ? "즐겨찾기 삭제하기" : "즐겨찾기 추가하기",
                    systemImage: contact.isFavorite ? "star.slash" : "star"
                  )
                }
                
                Button(role: .destructive) {
                  onDelete(contact)
                } label: {
                  Label("연락처 삭제", systemImage: "trash")
                }
              }
            }
          }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .padding(16)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 28))
    .animation(.snappy(duration: 0.2), value: isCollapsed)
  }
  
  private var header: some View {
    Button {
      isCollapsed.toggle()
    } label: {
      HStack(spacing: 8) {
        Text(title)
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.gray500)
        
        Text("\(count)")
          .typeStyle(.footnoteEmphasized)
          .foregroundStyle(.violet500)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.violet100)
          .clipShape(Capsule())
        
        Spacer()
        
        Image(systemName: "chevron.up")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.gray500)
          .rotationEffect(.degrees(isCollapsed ? 180 : 0))
      }
      .frame(minHeight: 22)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

private struct FavoriteSwipeRow<Content: View>: View {
  private let actionWidth: CGFloat = 40
  
  let isFavorite: Bool
  let onToggleFavorite: () -> Void
  let onDelete: () -> Void
  private let label: () -> Content
  
  @State private var restingOffset: CGFloat = 0
  @GestureState private var dragOffset: CGFloat = 0
  
  init(
    isFavorite: Bool,
    onToggleFavorite: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    @ViewBuilder label: @escaping () -> Content
  ) {
    self.isFavorite = isFavorite
    self.onToggleFavorite = onToggleFavorite
    self.onDelete = onDelete
    self.label = label
  }
  
  var body: some View {
    ZStack {
      HStack {
        favoriteButton
        Spacer()
        deleteButton
      }
      
      label()
        .contentShape(Rectangle())
        .offset(x: displayedOffset)
        .highPriorityGesture(swipeGesture)
    }
    .clipped()
    .animation(.snappy(duration: 0.2), value: restingOffset)
    .onChange(of: isFavorite) { _, _ in
      restingOffset = 0
    }
    .accessibilityAction(named: isFavorite ? "즐겨찾기 해제" : "즐겨찾기 추가") {
      onToggleFavorite()
    }
  }
  
  private var favoriteButton: some View {
    Button {
      withAnimation {
        restingOffset = 0
      }
      onToggleFavorite()
    } label: {
      Image(systemName: isFavorite ? "star.slash.fill" : "star.fill")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.violet500)
        .frame(width: actionWidth, height: actionWidth)
        .background(.violet100)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
  }

  private var deleteButton: some View {
    Button {
      withAnimation {
        restingOffset = 0
      }
      onDelete()
    } label: {
      Image(systemName: "trash.fill")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.errorRed)
        .frame(width: actionWidth, height: actionWidth)
        .background(.errorRed.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("연락처 삭제")
  }
  
  private var displayedOffset: CGFloat {
    max(-actionWidth, min(actionWidth, restingOffset + dragOffset))
  }
  
  private var swipeGesture: some Gesture {
    DragGesture(minimumDistance: 12)
      .updating($dragOffset) { value, state, _ in
        guard abs(value.translation.width) > abs(value.translation.height) else {
          return
        }
        state = value.translation.width
      }
      .onEnded { value in
        guard abs(value.translation.width) > abs(value.translation.height) else {
          return
        }
        
        let proposedOffset = restingOffset + value.predictedEndTranslation.width
        withAnimation {
          if proposedOffset > actionWidth / 2 {
            restingOffset = actionWidth
          } else if proposedOffset < -actionWidth / 2 {
            restingOffset = -actionWidth
          } else {
            restingOffset = 0
          }
        }
      }
  }
}

#Preview {
  ContactsSectionView(
    title: "All",
    count: 2,
    contacts: [
      Contact(name: "Sample User", role: "Product Designer", company: "@syno"),
      Contact(name: "Demo Contact", role: "iOS Developer", company: "@syno")
    ],
    noteRepository: PreviewRepositories.note,
    noteImageAnalyzer: PreviewRepositories.noteImageAnalyzer,
    noteImageAnalysisRepository: PreviewRepositories.noteImageAnalysis,
    labelTranslator: PreviewRepositories.labelTranslator,
    viewModel: ContactsViewModel(
      repository: PreviewRepositories.contact,
      myProfileId: UUID()
    ),
    existingGroups: [],
    onContactUpdated: { _ in },
    onContactDeleted: {},
    isCollapsed: .constant(false),
    onToggleFavorite: { _ in },
    onDelete: { _ in }
  )
  .padding()
  .background(Color.gray50)
}
