# AGENTS.md

Syno는 iOS 우선의 개인 AI 메모리 앱입니다. 사람·회사·프로젝트 중심으로 텍스트, 링크, 파일, 사진, 음성 메모를 저장하고 검색합니다.
SwiftUI + SwiftData, 로컬 우선입니다. 응답은 한국어로 합니다.
제품 우선순위, MVP 범위, 내비게이션 흐름은 [Docs/product.md](Docs/product.md)를 참고합니다.

## Commands

저장소 루트(`syno-ios/`)에서 실행합니다.

```bash
xcodebuild \
  -project Syno/Syno.xcodeproj \
  -scheme Syno \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath /tmp/SynoDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

- 타깃: `Syno`, `SynoTests`, `SynoShareExtension`
- 에러와 경고는 구분해서 보고합니다.
- 샌드박스 때문에 빌드가 막히면 막혔다고 알리고, 빌드한 것처럼 말하지 않습니다.

## Directory map

- `Syno/Syno/App`: 앱 시작, 의존성 조립, 루트 라우팅
- `Syno/Syno/Presentation`: View, ViewModel, 기능별 UI
- `Syno/Syno/Domain`: 앱 모델과 저장소·서비스 경계
- `Syno/Syno/Data`: SwiftData 구현과 시스템 서비스
- `Syno/Syno/DesignSystem`: 도메인에 독립적인 UI 구성요소
- `Syno/SynoShareExtension`: 공유 확장
- `Docs`: 제품 배경과 조사 자료

## Hard constraints

데이터 흐름은 하나입니다.

```
View → ViewModel → Repository/Service → SwiftData 또는 시스템 API
```

- View는 상태 표시와 사용자 동작 전달만 합니다. 저장, DB, AI, OCR/STT, 비즈니스 로직을 넣지 않습니다.
- Presentation(View, ViewModel)에서 `@Query`와 `ModelContext`를 쓰지 않습니다. SwiftData 접근은 Data 계층의 Repository 안에서만 합니다.
- `PhotosPicker`, `ContactsUI`, `UIDocumentPicker`처럼 화면 표시와 사용자 선택을 위한 UI 어댑터는 Presentation에서 사용할 수 있습니다. 파일 저장, 오디오 처리, OCR/STT, 권한 판단 같은 작업 로직은 Repository나 Service로 분리합니다.
- 서비스, 저장소, AI 클라이언트는 View 안에서 만들지 않고 생성자로 주입합니다.
  - 교체 가능성이나 테스트 경계가 필요한 의존성만 프로토콜로 만듭니다.
  - 단순한 값 변환이나 한 곳에서만 쓰는 동작을 위해 프로토콜, 매니저, 헬퍼 계층을 만들지 않습니다.
- `AppContainer`는 `SynoApp`, `RootView`, `MainTabView`에서만 사용합니다. 기능 화면과 하위 컴포넌트에는 필요한 의존성만 개별 인자로 전달하고, 컨테이너 자체를 넘기지 않습니다.
- UseCase는 여러 저장소를 묶는 반복 작업이 생길 때만 만듭니다.
- `DesignSystem`은 기능별 도메인 개념에 의존하지 않습니다.
- 기능 이름은 `Chat`입니다. 대화 화면과 관련된 코드는 `Presentation/Features/Chat`에 둡니다.

> 알려진 예외: `NotesView`, `GroupManagementSheet`, `GroupSelectionSheet`가 아직 SwiftData를 직접 사용합니다. `RootView`는 초기 라우팅을 위해 `UserProfile`을 `@Query`로 조회하는 App 계층의 기존 예외입니다.
> 새 코드에서는 이 방식을 확산하지 않습니다. 예외 제거는 사용자가 요청했거나, 요청한 변경에 반드시 필요한 경우에만 진행합니다.

## Gotchas

- `StoredNote`, `StoredContact` 등 SwiftData 모델을 바꾸면 `SynoShareExtension/SharedModels.swift`의 사본도 같은 스키마로 함께 수정합니다. 빠지면 다른 앱에서 공유할 때 오류가 납니다.
- 새 속성은 옵셔널이거나 기본값을 둬서 경량 마이그레이션이 되게 합니다.
- 메모 본문, 검색어, OCR 텍스트는 로그에 `privacy: .public`으로 남기지 않습니다.
- `.pbxproj`는 꼭 필요할 때만 수정합니다.

## Privacy

- 원본은 로컬(또는 iCloud)에 둡니다. 모든 원본 파일을 서버로 자동 업로드하는 흐름을 만들지 않습니다.
- 원본 데이터와 파생 색인 데이터(OCR 텍스트, 요약 등)를 분리합니다.
- 민감한 정보를 AI 서비스로 보내기 전에는 마스킹하거나 사용자 확인을 받습니다.
- 요청이 없으면 구현하지 않습니다: 상시 화면 녹화, 전체 앱 자동 수집, 카카오톡 DB 파싱, iMessage 자동 수집.

## Workflow

- 수정 전에 관련 파일을 먼저 읽습니다.
- 조언, 설계 논의, 비교를 물으면 파일을 수정하지 않습니다. 수정, 추가, 이동, 리팩터링을 직접 요청하면 진행합니다.
- 요청 범위 밖의 변경을 섞지 않습니다. 기능 변경과 리팩터링은 따로 커밋합니다.
- 서드파티 의존성은 먼저 묻고 추가합니다.
- 코드, 타입, 파일, 함수 이름은 영어로 씁니다. 주석은 한국어입니다.

### Git

- 사용자가 명시적으로 요청한 경우에만 브랜치를 만들거나 커밋합니다. 푸시와 PR 생성도 요청받았을 때만 합니다.
- 브랜치: `feature/#이슈/설명`. `fix`, `refactor`, `docs`도 같은 형식입니다. 통합 브랜치는 `develop`입니다.
- 커밋: `[#이슈번호] type: 한국어 설명` (예: `[#67] fix: 공유 확장의 StoredNote 스키마에 photoGroupId 추가`)
- type은 `feat`, `fix`, `refactor`, `docs`, `chore`, `test`를 씁니다.
- PR은 저장소의 PR 템플릿(관련 이슈, 요약, 스크린샷, 테스트, 공유 사항, 리뷰 가이드)을 따릅니다.
