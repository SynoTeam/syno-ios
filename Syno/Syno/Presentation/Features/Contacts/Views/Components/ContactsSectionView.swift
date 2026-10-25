//
//  ContactsSectionView.swift
//  Syno
//
//  Created by 이승진 on 7/16/26.
//

import SwiftUI
import UIKit

struct ContactsSectionView: View {
  let title: String
  let swipeSection: SwipeSection
  let count: Int
  let contacts: [Contact]
  let onSelectContact: (Contact) -> Void
  @Binding var isCollapsed: Bool
  @Binding var openSwipeRow: OpenSwipeRow?
  let onToggleFavorite: (Contact.ID) -> Void
  let onDelete: (Contact) -> Void
  /// 그룹 이름을 구분 제목으로 보여줄지 정합니다. 연락처는 이미 그룹 순으로 정렬되어 있어야 합니다.
  var showsGroupHeaders = false

  private struct ContactGroup: Identifiable {
    let title: String
    var contacts: [Contact]
    var id: String { title }
  }

  /// 정렬된 순서를 유지한 채 같은 그룹이 이어지는 구간끼리 묶습니다.
  /// 제목이 필요 없으면 전체를 하나의 묶음으로 둡니다.
  private var groupedContacts: [ContactGroup] {
    guard showsGroupHeaders else {
      return [ContactGroup(title: "", contacts: contacts)]
    }

    var groups: [ContactGroup] = []
    for contact in contacts {
      let title = contact.group.trimmingCharacters(in: .whitespacesAndNewlines)
      if groups.last?.title == title {
        groups[groups.count - 1].contacts.append(contact)
      } else {
        groups.append(ContactGroup(title: title, contacts: [contact]))
      }
    }
    return groups
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      
      if !isCollapsed {
        // 지연 스택을 중첩하면 연락처가 많을 때 스크롤이 끊기므로 제목과 행을 한 스택에 나란히 둔다.
        let groups = groupedContacts
        let firstGroupID = groups.first?.id

        LazyVStack(alignment: .leading, spacing: 2) {
          ForEach(groups) { group in
            if showsGroupHeaders, !group.title.isEmpty {
              Text(group.title)
                .typeStyle(.footnoteEmphasized)
                .foregroundStyle(.gray400)
                .padding(.horizontal, 8)
                .padding(.top, group.id == firstGroupID ? 0 : 14)
                .padding(.bottom, 6)
            } else if showsGroupHeaders, group.id != firstGroupID {
              // 그룹이 없는 연락처 구간도 앞 그룹과 간격을 둔다.
              Color.clear.frame(height: 14)
            }

            ForEach(group.contacts) { contact in
              contactRow(contact)
            }
          }
        }
        .transition(.opacity)
      }
    }
    .padding(16)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 28))
  }
  
  private func contactRow(_ contact: Contact) -> some View {
    FavoriteSwipeRow(
      id: contact.id,
      section: swipeSection,
      openSwipeRow: $openSwipeRow,
      isFavorite: contact.isFavorite,
      onToggleFavorite: {
        onToggleFavorite(contact.id)
      },
      onDelete: {
        onDelete(contact)
      }
    ) {
      ContactsRowView(
        name: contact.name,
        group: contact.group,
        profileImageData: contact.profileImageData
      )
      .contentShape(Rectangle())
      // Button은 가로로 민 뒤 손을 뗄 때 탭으로 인식되어 열린 행을 닫아버리므로 TapGesture를 쓴다.
      .onTapGesture {
        guard openSwipeRow == nil else {
          withAnimation(swipeSettleAnimation) {
            openSwipeRow = nil
          }
          return
        }
        onSelectContact(contact)
      }
      .accessibilityAddTraits(.isButton)
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
          Label("연락처 삭제", icon: .trash)
        }
      }
    }
  }

  private var header: some View {
    Button {
      guard !contacts.isEmpty else {
        return
      }
      openSwipeRow = nil
      withAnimation(.snappy(duration: 0.2)) {
        isCollapsed.toggle()
      }
    } label: {
      HStack(spacing: 8) {
        Text(title)
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.gray500)
        
        ContactCountChip(count: count)

        Spacer()
        
        if !contacts.isEmpty {
          Image(.chevronUp)
            .resizable()
            .renderingMode(.template)
            .frame(width: 16, height: 16)
            .foregroundStyle(.gray500)
            .rotationEffect(.degrees(isCollapsed ? 180 : 0))
        }
      }
      .frame(minHeight: 22)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

/// 스와이프 행이 열리고 닫힐 때 쓰는 공통 정착 애니메이션입니다.
private let swipeSettleAnimation = Animation.spring(response: 0.3, dampingFraction: 0.88)

/// 스와이프 행이 속한 섹션입니다.
enum SwipeSection: Hashable {
  case favorites
  case all
}

/// 한 시점에 열려 있는 스와이프 행과 열린 방향입니다.
struct OpenSwipeRow: Equatable {
  enum Edge: Equatable {
    /// 행이 오른쪽으로 밀려 왼쪽의 즐겨찾기 버튼이 보이는 상태
    case favorite
    /// 행이 왼쪽으로 밀려 오른쪽의 삭제 버튼이 보이는 상태
    case delete
  }

  /// 즐겨찾기한 연락처는 Favorites와 All에 모두 나오므로 섹션까지 함께 비교한다.
  let section: SwipeSection
  let id: Contact.ID
  let edge: Edge
}

private struct FavoriteSwipeRow<Content: View>: View {
  private let actionWidth: CGFloat = 40
  private let actionSpacing: CGFloat = 8
  /// 행 왼쪽 여백 + 프로필 이미지 폭에 약간의 여유를 더한 값입니다.
  private let avatarClearance: CGFloat = 56

  let id: Contact.ID
  let section: SwipeSection
  @Binding var openSwipeRow: OpenSwipeRow?
  let isFavorite: Bool
  let onToggleFavorite: () -> Void
  let onDelete: () -> Void
  private let label: () -> Content

  @State private var isHorizontalDragging = false
  @State private var dragTranslation: CGFloat = 0

  init(
    id: Contact.ID,
    section: SwipeSection,
    openSwipeRow: Binding<OpenSwipeRow?>,
    isFavorite: Bool,
    onToggleFavorite: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    @ViewBuilder label: @escaping () -> Content
  ) {
    self.id = id
    self.section = section
    _openSwipeRow = openSwipeRow
    self.isFavorite = isFavorite
    self.onToggleFavorite = onToggleFavorite
    self.onDelete = onDelete
    self.label = label
  }

  var body: some View {
    ZStack {
      HStack {
        // 접거나 펼칠 때 행 뒤의 버튼이 비쳐 보이지 않도록 밀린 방향의 버튼만 보여준다.
        favoriteButton
          .opacity(displayedOffset > 0 ? 1 : 0)
          .allowsHitTesting(openEdge == .favorite)
          .accessibilityHidden(openEdge != .favorite)
        Spacer()
        deleteButton
          .opacity(displayedOffset < 0 ? 1 : 0)
          .allowsHitTesting(openEdge == .delete)
          .accessibilityHidden(openEdge != .delete)
      }

      label()
        .contentShape(Rectangle())
        // 왼쪽으로 밀 때 행 왼쪽 가장자리에 걸쳐 남는 프로필 이미지가 깔끔하게 가려지도록 덮는다.
        .overlay(alignment: .leading) {
          Color.white
            .frame(width: leadingCoverWidth)
            .allowsHitTesting(false)
        }
        .offset(x: displayedOffset)
        .gesture(
          HorizontalPanGesture(
            onChanged: handleSwipeChanged,
            onEnded: handleSwipeEnded,
            onCancelled: handleSwipeCancelled,
            onVertical: { openSwipeRow = nil }
          )
        )
    }
    .clipped()
    .animation(swipeSettleAnimation, value: openSwipeRow)
    .onChange(of: isFavorite) { _, _ in
      close()
    }
    .accessibilityAction(named: isFavorite ? "즐겨찾기 해제" : "즐겨찾기 추가") {
      onToggleFavorite()
    }
    .accessibilityAction(named: "연락처 삭제") {
      onDelete()
    }
  }

  private var favoriteButton: some View {
    Button {
      close()
      onToggleFavorite()
    } label: {
      Image(systemName: isFavorite ? "star.slash.fill" : "star.fill")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(isFavorite ? .gray500 : .violet600)
        .frame(width: actionWidth, height: actionWidth)
        .background(isFavorite ? Color.gray500.opacity(0.12) : Color.violet100)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .padding(.trailing, actionSpacing)
  }

  private var deleteButton: some View {
    Button {
      close()
      onDelete()
    } label: {
      Image(.trash)
        .resizable()
        .renderingMode(.template)
        .frame(width: 20, height: 20)
        .foregroundStyle(.errorRed)
        .frame(width: actionWidth, height: actionWidth)
        .background(.errorRed.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .padding(.leading, actionSpacing)
    .accessibilityLabel("연락처 삭제")
  }

  private var revealDistance: CGFloat {
    actionWidth + actionSpacing
  }

  /// 이 행이 열려 있을 때의 열린 방향입니다. 닫혀 있으면 nil입니다.
  private var openEdge: OpenSwipeRow.Edge? {
    guard let openSwipeRow, isThisRow(openSwipeRow) else {
      return nil
    }
    return openSwipeRow.edge
  }

  private var restingOffset: CGFloat {
    guard let openSwipeRow, isThisRow(openSwipeRow) else {
      return 0
    }
    switch openSwipeRow.edge {
    case .favorite: return revealDistance
    case .delete: return -revealDistance
    }
  }

  private var displayedOffset: CGFloat {
    let dragged = isHorizontalDragging ? dragTranslation : 0
    return resistedOffset(restingOffset + dragged)
  }

  /// 액션 너비까지는 손가락을 그대로 따라가고, 그 이상은 고무줄처럼 저항을 준다.
  private func resistedOffset(_ offset: CGFloat) -> CGFloat {
    let distance = abs(offset)
    guard distance > revealDistance else {
      return offset
    }

    let direction: CGFloat = offset < 0 ? -1 : 1
    let overflow = distance - revealDistance
    return direction * (revealDistance + overflow * 0.18)
  }

  /// 완전히 열렸을 때(48pt) 프로필 이미지 오른쪽 끝(8 + 44 = 52pt)까지 가려지도록 밀린 거리에 비례해 키운다.
  private var leadingCoverWidth: CGFloat {
    let swipedLeft = max(0, -displayedOffset)
    return swipedLeft * (avatarClearance / revealDistance)
  }

  private func isThisRow(_ row: OpenSwipeRow) -> Bool {
    row.id == id && row.section == section
  }

  private func close() {
    guard let current = openSwipeRow, isThisRow(current) else {
      return
    }
    openSwipeRow = nil
  }

  private func handleSwipeChanged(_ translation: CGFloat) {
    if !isHorizontalDragging {
      isHorizontalDragging = true

      // 다른 행이 열려 있으면 먼저 닫는다.
      if let openSwipeRow, !isThisRow(openSwipeRow) {
        self.openSwipeRow = nil
      }
    }
    dragTranslation = translation
  }

  private func handleSwipeEnded(translation: CGFloat, velocity: CGFloat) {
    guard isHorizontalDragging else {
      return
    }

    let wasOpenOffset = restingOffset
    // 속도는 짧은 구간만 투영해 가벼운 드래그가 열림 임계값을 넘지 않게 한다.
    let proposedOffset = wasOpenOffset + translation + velocity * 0.05

    withAnimation(swipeSettleAnimation) {
      isHorizontalDragging = false
      dragTranslation = 0

      if proposedOffset > revealDistance / 2 {
        // 반대쪽이 열려 있었다면 한 번에 넘기지 않고 먼저 닫는다.
        if wasOpenOffset < 0 {
          close()
        } else {
          openSwipeRow = OpenSwipeRow(section: section, id: id, edge: .favorite)
        }
      } else if proposedOffset < -revealDistance / 2 {
        if wasOpenOffset > 0 {
          close()
        } else {
          openSwipeRow = OpenSwipeRow(section: section, id: id, edge: .delete)
        }
      } else {
        close()
      }
    }
  }

  private func handleSwipeCancelled() {
    guard isHorizontalDragging else {
      return
    }

    withAnimation(swipeSettleAnimation) {
      isHorizontalDragging = false
      dragTranslation = 0
    }
  }
}

/// 가로 속도에서만 인식되어 세로 드래그를 상위 ScrollView에 넘기는 행 스와이프 제스처입니다.
private struct HorizontalPanGesture: UIGestureRecognizerRepresentable {
  let onChanged: (CGFloat) -> Void
  let onEnded: (CGFloat, CGFloat) -> Void
  let onCancelled: () -> Void
  let onVertical: () -> Void

  func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
    Coordinator(onVertical: onVertical)
  }

  func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
    let recognizer = UIPanGestureRecognizer()
    recognizer.delegate = context.coordinator
    recognizer.cancelsTouchesInView = false
    return recognizer
  }

  func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
    context.coordinator.onVertical = onVertical
  }

  func handleUIGestureRecognizerAction(
    _ recognizer: UIPanGestureRecognizer,
    context: Context
  ) {
    let translation = recognizer.translation(in: recognizer.view).x
    switch recognizer.state {
    case .began, .changed:
      onChanged(translation)
    case .ended:
      let velocity = recognizer.velocity(in: recognizer.view).x
      onEnded(translation, velocity)
    case .cancelled, .failed:
      onCancelled()
    default:
      break
    }
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    var onVertical: () -> Void

    init(onVertical: @escaping () -> Void) {
      self.onVertical = onVertical
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      guard
        let pan = gestureRecognizer as? UIPanGestureRecognizer,
        let view = gestureRecognizer.view
      else {
        return false
      }

      let velocity = pan.velocity(in: view)
      if abs(velocity.x) > abs(velocity.y) * 1.3 {
        return true
      }
      if abs(velocity.y) > abs(velocity.x) * 1.3 {
        // 열린 행을 닫고 인식을 포기해 상위 스크롤 뷰가 세로 이동을 처리하게 한다.
        onVertical()
      }
      return false
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      // 상위 ScrollView pan만 허용해 내비게이션 가장자리 뒤로 가기와의 경합을 막는다.
      otherGestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer.view is UIScrollView
    }
  }
}

#Preview {
  ContactsSectionView(
    title: "All",
    swipeSection: .all,
    count: 2,
    contacts: [
      Contact(name: "Sample User", role: "Product Designer", company: "@syno"),
      Contact(name: "Demo Contact", role: "iOS Developer", company: "@syno")
    ],
    onSelectContact: { _ in },
    isCollapsed: .constant(false),
    openSwipeRow: .constant(nil),
    onToggleFavorite: { _ in },
    onDelete: { _ in }
  )
  .padding()
  .background(Color.gray50)
}
