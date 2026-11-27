import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 아카이브 "음성" 탭의 목록입니다 (#144).
/// 행을 누르면 그 자리에서 재생 카드가 펼쳐지고, 길게 누르면 복사·공유·선택·삭제 메뉴가 나옵니다.
/// 선택 모드의 제목·하단 바는 목록 화면(ArchiveCategoryListView)이 그리고, 여기서는 행 선택만 바꿉니다.
struct ArchiveVoiceMemoList: View {
  let viewModel: ChatViewModel
  let notes: [Note]
  @Binding var selection: ChatSelectionState
  /// 파일 앱으로 저장합니다.
  let onExport: ([Note]) -> Void
  let onRequestDelete: (Note) -> Void
  let onToast: (Toast) -> Void

  @State private var expandedNoteID: Note.ID?
  @State private var transcriptNoteID: Note.ID?
  @State private var playback = VoiceMemoPlaybackController()

  private var noteIDs: [Note.ID] { notes.map(\.id) }

  var body: some View {
    LazyVStack(alignment: .leading, spacing: 0) {
      ForEach(notes) { note in
        if expandedNoteID == note.id, !selection.isActive {
          playerCard(note)
            .contextMenu { contextMenu(for: note) }
        } else {
          row(note)
        }
      }
    }
    .padding(.horizontal, 16)
    .animation(.easeInOut(duration: 0.2), value: expandedNoteID)
    .animation(.easeInOut(duration: 0.2), value: selection.isActive)
    .sheet(isPresented: transcriptSheetBinding) {
      if let transcriptNoteID, let note = viewModel.messages.first(where: { $0.id == transcriptNoteID }) {
        VoiceMemoTranscriptSheet(
          title: note.content,
          state: viewModel.voiceMemoStates[note.id],
          onRetry: { retry(note) }
        )
      }
    }
    // 삭제나 검색으로 목록에서 사라진 메모는 접고 재생을 멈춘다.
    .onChange(of: noteIDs) { _, ids in
      playback.stop(unlessVisible: Set(ids))
      if let expandedNoteID, !ids.contains(expandedNoteID) {
        collapse()
      }
    }
    .onChange(of: selection.isActive) { _, isActive in
      if isActive { collapse() }
    }
    .onDisappear {
      playback.stop()
    }
  }

  // MARK: - 행

  @ViewBuilder
  private func row(_ note: Note) -> some View {
    if selection.isActive {
      // 시안: 왼쪽 선택 원, 구분선은 행 내용 아래에만 그린다.
      Button {
        selection.toggle([note.id])
      } label: {
        HStack(alignment: .center, spacing: 16) {
          ChatSelectionIndicator(isSelected: selection.isSelected([note.id]))
          VStack(spacing: 0) {
            VoiceMemoArchiveRow(note: note)
            divider
          }
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(note.content), \(selection.isSelected([note.id]) ? "선택됨" : "선택 안 됨")")
      .accessibilityIdentifier("archive.voice.selectRow")
    } else {
      VStack(spacing: 0) {
        Button { expand(note) } label: { VoiceMemoArchiveRow(note: note) }
          .buttonStyle(.plain)
          .accessibilityIdentifier("archive.voice.row")
          .contextMenu { contextMenu(for: note) }
        divider
      }
    }
  }

  private var divider: some View {
    Rectangle()
      .fill(.gray100)
      .frame(height: 1)
  }

  /// 시안: 복사하기, 공유하기, 선택하기, 삭제하기
  @ViewBuilder
  private func contextMenu(for note: Note) -> some View {
    Button {
      copyAudio(note)
    } label: {
      Label("복사하기", icon: .copy)
    }

    // 음성 공유는 변환 텍스트로 한다.
    ShareLink(item: viewModel.voiceMemoShareItem(for: [note]), preview: SharePreview(note.content)) {
      Label("공유하기", icon: .share)
    }

    Button {
      selection.begin(with: [note.id])
    } label: {
      Label("선택하기", icon: .checkCircleFilled)
    }

    Button(role: .destructive) {
      onRequestDelete(note)
    } label: {
      Label("삭제하기", destructiveIcon: .trash)
    }
  }

  /// 음성 파일을 이름이 붙은 파일로 복사합니다. 메시지·메일·파일 앱처럼 파일을 받는 곳에는 음성 파일이,
  /// 글만 받는 입력창에는 변환 텍스트가 붙여 넣어집니다.
  /// 오디오 데이터만 복사하면 이름·형식 정보가 없어 대부분의 앱이 붙여넣기를 받지 않습니다.
  /// 파일은 붙여 넣는 순간에 임시 파일로 만들어 넘깁니다.
  /// 복사한 내용은 다른 앱처럼 원본 메모를 지운 뒤에도 붙여 넣을 수 있습니다. 대신 노트 폴더가 아닌
  /// 복사 전용 폴더에 만들어, 지운 메모의 임시 파일이 다시 생기지 않고 복사할 때마다 앞의 파일은 지워집니다.
  private func copyAudio(_ note: Note) {
    guard let data = note.voiceMemoData else { return }
    let item = VoiceMemoTransferItem(note: note)
    let type = UTType(filenameExtension: VoiceMemoExport.fileExtension(for: data)) ?? .audio
    let provider = NSItemProvider()
    provider.suggestedName = (item.fileName as NSString).deletingPathExtension
    provider.registerFileRepresentation(forTypeIdentifier: type.identifier, fileOptions: [], visibility: .all) { completion in
      Task {
        let url = await FileTransferURL.prepare(data: item.audioData, name: item.fileName, noteID: FileTransferURL.clipboardFolderID, overwrite: true)
        completion(url, false, url == nil ? CocoaError(.fileWriteUnknown) : nil)
      }
      return nil
    }
    if case let .transcribed(result) = viewModel.voiceMemoStates[note.id], !result.text.isEmpty {
      provider.registerObject(result.text as NSString, visibility: .all)
    }
    UIPasteboard.general.setItemProviders([provider], localOnly: false, expirationDate: nil)
    onToast(Toast(message: "음성 메모를 복사했습니다", style: .success))
  }

  // MARK: - 재생 카드

  private func playerCard(_ note: Note) -> some View {
    VoiceMemoPlayerCard(
      note: note,
      isPlaying: playback.isPlaying(note.id),
      elapsed: { playback.elapsed(for: note.id) },
      onCollapse: collapse,
      onTogglePlayback: { togglePlayback(note) },
      onSeek: { time in
        guard let data = note.voiceMemoData else { return }
        playback.seek(noteID: note.id, audioData: data, to: time)
      },
      isSaved: viewModel.savedVoiceMemoIDs.contains(note.id),
      onShowTranscript: { showTranscript(note) },
      onDownload: { onExport([note]) }
    )
    .padding(.vertical, 8)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("archive.voice.card")
  }

  /// 다른 메모를 펼치면 앞의 메모는 접히고 재생도 멈춘다.
  private func expand(_ note: Note) {
    collapse()
    expandedNoteID = note.id
  }

  private func collapse() {
    playback.stop()
    expandedNoteID = nil
  }

  private func togglePlayback(_ note: Note) {
    guard let data = note.voiceMemoData, playback.toggle(noteID: note.id, audioData: data) else {
      onToast(Toast(message: "음성 메모를 재생하지 못했습니다.", style: .failure))
      return
    }
  }

  /// 변환 텍스트 모달을 엽니다. 아직 변환 결과가 없으면 변환을 시작합니다.
  private func showTranscript(_ note: Note) {
    transcriptNoteID = note.id
    if viewModel.voiceMemoStates[note.id] == nil {
      Task { await viewModel.retryTranscription(for: note) }
    }
  }

  /// 저장부터 실패한 메모는 다시 저장한 뒤 변환하고, 변환만 실패한 메모는 변환만 다시 한다.
  /// 저장 실패 메모를 변환만 다시 하면 실패 표시는 사라지지만 메모는 여전히 저장되지 않는다.
  private func retry(_ note: Note) {
    if viewModel.voiceMemoStates[note.id] == .sendFailed {
      Task { await viewModel.retrySend(for: note) }
    } else {
      Task { await viewModel.retryTranscription(for: note) }
    }
  }

  private var transcriptSheetBinding: Binding<Bool> {
    Binding(
      get: { transcriptNoteID != nil },
      set: { if !$0 { transcriptNoteID = nil } }
    )
  }
}

/// 음성 메모의 변환 텍스트를 보여 주는 모달입니다. 시안: X 버튼, 가운데 제목, 흰 카드 안 본문 (#144).
struct VoiceMemoTranscriptSheet: View {
  @Environment(\.dismiss) private var dismiss
  let title: String
  let state: ChatViewModel.VoiceMemoState?
  let onRetry: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      ZStack {
        Text(title)
          .typeStyle(.headlineRegular)
          .foregroundStyle(.gray950)
          .lineLimit(1)
          .truncationMode(.tail)
          .padding(.horizontal, 56)

        HStack {
          Button { dismiss() } label: {
            Image(.close)
              .resizable()
              .renderingMode(.template)
              .frame(width: 20, height: 20)
              .foregroundStyle(.gray950)
              .frame(width: 32, height: 32)
          }
          .buttonStyle(.glass)
          .buttonBorderShape(.circle)
          .accessibilityLabel("닫기")
          Spacer()
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 16)

      ScrollView {
        content
          .typeStyle(.body)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(20)
          .background(.white, in: RoundedRectangle(cornerRadius: 24))
          .padding(.horizontal, 16)
          .padding(.bottom, 16)
      }
    }
    .background(Color.gray50)
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  @ViewBuilder private var content: some View {
    switch state {
    case let .transcribed(result):
      Text(result.text.isEmpty ? "변환된 텍스트가 없습니다" : result.text)
        .foregroundStyle(result.text.isEmpty ? .gray500 : .gray950)
        .textSelection(.enabled)
    case .transcribing, nil:
      HStack(spacing: 8) {
        ProgressView().controlSize(.small)
        Text("텍스트로 변환하는 중").foregroundStyle(.gray500)
      }
    case .transcriptFailed, .sendFailed:
      VStack(alignment: .leading, spacing: 12) {
        Text(state == .sendFailed ? "음성 메모를 저장하지 못했습니다" : "텍스트로 변환하지 못했습니다")
          .foregroundStyle(.gray500)
        Button("다시 시도", action: onRetry)
          .typeStyle(.calloutEmphasized)
          .foregroundStyle(.violet600)
      }
    }
  }
}
