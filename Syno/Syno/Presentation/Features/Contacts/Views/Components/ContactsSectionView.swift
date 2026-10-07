//
//  ContactsSectionView.swift
//  Syno
//
//  Created by 이승진 on 7/16/26.
//

import SwiftUI

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
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      
      if !isCollapsed {
        LazyVStack(spacing: 2) {
          ForEach(contacts) { contact in
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
                  Label("연락처 삭제", systemImage: "trash")
                }
              }
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
        
        Text("\(count)")
          .typeStyle(.footnoteEmphasized)
          .foregroundStyle(.violet600)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.violet100)
          .clipShape(Capsule())
        
        Spacer()
        
        if !contacts.isEmpty {
          Image(systemName: "chevron.up")
            .font(.system(size: 12, weight: .semibold))
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
  private enum DragAxis {
    case horizontal
    case vertical
  }

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

  @State private var dragAxis: DragAxis?
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
        favoriteButton
          .allowsHitTesting(openEdge == .favorite)
          .accessibilityHidden(openEdge != .favorite)
        Spacer()
        deleteButton
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
        .simultaneousGesture(swipeGesture)
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
        .foregroundStyle(.violet600)
        .frame(width: actionWidth, height: actionWidth)
        .background(.violet100)
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
      Image(systemName: "trash.fill")
        .font(.system(size: 16, weight: .semibold))
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
    let dragged = dragAxis == .horizontal ? dragTranslation : 0
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

  private var swipeGesture: some Gesture {
    DragGesture(minimumDistance: 12)
      .onChanged { value in
        // 방향은 제스처 시작 시 한 번만 정하고 이후에는 바꾸지 않는다.
        if dragAxis == nil {
          dragAxis = abs(value.translation.width) > abs(value.translation.height)
            ? .horizontal
            : .vertical

          if dragAxis == .horizontal {
            // 다른 행이 열려 있으면 먼저 닫는다.
            if let openSwipeRow, !isThisRow(openSwipeRow) {
              self.openSwipeRow = nil
            }
          } else {
            // 세로 스크롤을 시작하면 열린 행을 닫는다.
            openSwipeRow = nil
          }
        }

        if dragAxis == .horizontal {
          dragTranslation = value.translation.width
        }
      }
      .onEnded { value in
        let wasHorizontal = dragAxis == .horizontal
        let wasOpenOffset = restingOffset

        // 예측값은 일부만 반영해서 작은 플릭이 과하게 투영되지 않게 한다.
        let currentOffset = wasOpenOffset + value.translation.width
        let projectedDelta = value.predictedEndTranslation.width - value.translation.width
        let proposedOffset = currentOffset + projectedDelta * 0.2

        // 정리 전체를 애니메이션으로 묶어서 임계값 미달 시에도 부드럽게 돌아가게 한다.
        withAnimation(swipeSettleAnimation) {
          dragAxis = nil
          dragTranslation = 0

          guard wasHorizontal else {
            return
          }

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
