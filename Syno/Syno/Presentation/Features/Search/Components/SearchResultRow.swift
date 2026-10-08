//
//  SearchResultRow.swift
//  Syno
//

import SwiftUI

struct SearchResultRow: View {
  let result: SearchResult
  /// 일치하는 텍스트를 강조할 검색어입니다.
  var highlightQuery: String?

  var body: some View {
    switch result {
    case let .text(note, _):
      NoteRowView(note: note, highlightQuery: highlightQuery, trailingPadding: 16, textSpacing: 4)
    case let .photo(note, _):
      if let data = note.imageData, let image = UIImage(data: data) {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 100, height: 100)
          .clipped()
          .clipShape(RoundedRectangle(cornerRadius: 8))
          // 셀 사이 간격은 0이고, 셀 높이 132는 사진 100 + 위아래 16으로 만든다.
          .padding(.vertical, 16)
      }
    case let .link(_, _, preview):
      SearchLinkTile(preview: preview, highlightQuery: highlightQuery)
        // 셀 높이 156은 링크 타일 124 + 위아래 16으로 만든다.
        .padding(.vertical, 16)
    case let .voice(note, _, _):
      VoiceMemoSearchRow(note: note, highlightQuery: highlightQuery)
    case let .file(note, _):
      FileSearchRow(note: note, highlightQuery: highlightQuery)
    }
  }
}

private struct FileSearchRow: View {
  let note: Note
  var highlightQuery: String?

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "folder.fill")
        .foregroundStyle(.violet500)
        .frame(width: 40, height: 40)
        .background(Color.violet500.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))

      VStack(alignment: .leading, spacing: 4) {
        Text(highlighting: note.fileName ?? note.content, query: highlightQuery)
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.gray950)
          .lineLimit(1)
          .truncationMode(.middle)
        Text("Size \(ByteCountFormatter.string(fromByteCount: Int64(note.fileSize ?? 0), countStyle: .file))")
          .typeStyle(.footnote)
          .foregroundStyle(.gray500)
      }
      Spacer(minLength: 0)
    }
    .searchTextCellContainer()
  }
}

private struct VoiceMemoSearchRow: View {
  let note: Note
  var highlightQuery: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(highlighting: note.content, query: highlightQuery)
        .typeStyle(.calloutEmphasized)
        .foregroundStyle(.gray950)
        .lineLimit(1)
        .truncationMode(.tail)

      HStack {
        Text(dateText)
          .typeStyle(.footnote)
          .foregroundStyle(.gray400)

        Spacer()

        Text(durationText)
          .typeStyle(.footnote)
          .foregroundStyle(.gray400)
      }
    }
    .searchTextCellContainer()
  }

  private var durationText: String {
    let duration = Int(note.voiceMemoDuration ?? 0)
    return String(format: "%d:%02d", duration / 60, duration % 60)
  }

  private var dateText: String {
    let isCurrentYear = Calendar.current.isDate(note.createdAt, equalTo: Date(), toGranularity: .year)
    let formatter = isCurrentYear ? Self.monthDayFormatter : Self.yearMonthDayFormatter
    return formatter.string(from: note.createdAt)
  }

  private static let monthDayFormatter = makeFormatter("M월 d일 (E)")
  private static let yearMonthDayFormatter = makeFormatter("yyyy년 M월 d일 (E)")

  private static func makeFormatter(_ dateFormat: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = dateFormat
    return formatter
  }
}

/// 검색 결과의 링크 타일(144 x 124)입니다. 전체 타일이 채팅 이동 대상이라 안쪽에 별도 링크를 두지 않습니다.
private struct SearchLinkTile: View {
  let preview: NoteLinkPreviewResult
  var highlightQuery: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let imageURL = preview.imageURL {
        AsyncImage(url: imageURL) { image in
          image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
          Color.gray100
        }
        .frame(width: 144, height: 72)
        .clipped()
      } else {
        Color.gray100
          .frame(width: 144, height: 72)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(highlighting: preview.title, query: highlightQuery)
          .typeStyle(.footnoteEmphasized)
          .foregroundStyle(.gray900)
          .lineLimit(1)
          .truncationMode(.tail)

        Text(preview.siteURL.host ?? preview.siteURL.absoluteString)
          .typeStyle(.caption1)
          .foregroundStyle(.violet500)
          .lineLimit(1)
          .truncationMode(.tail)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 8)
      .padding(.top, 6)

      Spacer(minLength: 0)
    }
    .frame(width: 144, height: 124, alignment: .topLeading)
    .background(.gray50)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

extension View {
  /// 텍스트, 음성메모, 파일 검색 결과가 함께 쓰는 셀 컨테이너입니다. 안쪽 내용만 서로 다릅니다.
  fileprivate func searchTextCellContainer() -> some View {
    self
      .padding(.leading, 13)
      .padding(.trailing, 16)
      .padding(.vertical, 13)
      .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 20))
  }
}
