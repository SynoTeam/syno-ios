//
//  SearchResultRow.swift
//  Syno
//

import SwiftUI

struct SearchResultRow: View {
  let result: SearchResult

  var body: some View {
    switch result {
    case let .text(note, _):
      NoteRowView(note: note)
    case let .photo(note, _):
      if let data = note.imageData, let image = UIImage(data: data) {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(height: 84)
          .clipped()
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    case let .link(_, _, preview):
      LinkPreviewCard(preview: preview)
    case let .voice(note, _, _):
      VoiceMemoSearchRow(note: note)
    case let .file(note, _):
      FileSearchRow(note: note)
    }
  }
}

private struct FileSearchRow: View {
  let note: Note

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "folder.fill")
        .foregroundStyle(.violet500)
        .frame(width: 40, height: 40)
        .background(Color.violet500.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      VStack(alignment: .leading, spacing: 5) {
        Text(note.fileName ?? note.content)
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.gray950)
          .lineLimit(1)
          .truncationMode(.middle)
        Text("\(dateText) · \(ByteCountFormatter.string(fromByteCount: Int64(note.fileSize ?? 0), countStyle: .file))")
          .typeStyle(.footnote)
          .foregroundStyle(.gray400)
      }
      Spacer(minLength: 0)
    }
    .padding(13)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }

  private var dateText: String {
    let formatter = Calendar.current.isDate(note.createdAt, equalTo: Date(), toGranularity: .year) ? Self.monthDayFormatter : Self.yearMonthDayFormatter
    return formatter.string(from: note.createdAt)
  }

  private static let monthDayFormatter = makeFormatter("M월 d일 (E)")
  private static let yearMonthDayFormatter = makeFormatter("yyyy년 M월 d일 (E)")
  private static func makeFormatter(_ format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = format
    return formatter
  }
}

private struct VoiceMemoSearchRow: View {
  let note: Note

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(note.content)
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
    .padding(13)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 20))
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
