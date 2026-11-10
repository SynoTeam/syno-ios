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

단위 테스트는 `Unit` 테스트 플랜으로 실행합니다. CI(`.github/workflows/ci.yml`)도 같은 명령을 씁니다.

```bash
xcodebuild test \
  -project Syno/Syno.xcodeproj \
  -scheme Syno \
  -testPlan Unit \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -derivedDataPath /tmp/SynoDerivedData \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM= \
  PROVISIONING_PROFILE_SPECIFIER=
```

- 테스트 호스트 앱이 App Group을 쓰므로 테스트에서는 `CODE_SIGNING_ALLOWED=NO` 대신 ad-hoc 서명(`CODE_SIGN_IDENTITY=-`)을 씁니다.
- `Unit` 플랜은 Spike 테스트를 제외합니다. Spike 테스트는 `-testPlan Spike`로 따로 실행합니다. 새 Spike 테스트를 추가하면 두 플랜 모두에 반영합니다.
- UI 테스트는 같은 명령에서 `-testPlan UI`로 실행합니다(`SynoUITests` 타깃). 앱은 실행 인자 `-UITestFixtures`로 메모리 저장소와 고정 샘플 데이터(`Data/Local/UITestFixtureSeeder.swift`)로 시작합니다. 운영 저장소와 CloudKit은 쓰지 않습니다.
- UI 테스트는 화면 요소를 `accessibilityIdentifier`나 보이는 문구로 찾고, 내부 구현에 의존하지 않게 씁니다. 화면 구조를 리팩터링해도 같은 테스트가 통과해야 합니다.
- 단위 테스트에서 메모리 `ModelContainer`를 만들 때는 `cloudKitDatabase: .none`을 지정합니다. 지정하지 않으면 앱의 CloudKit 권한 때문에 동기화를 시도합니다.
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
- `Docs`: 제품 배경, 기능 명세(`Docs/specs`), 조사 자료

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
- 모델에 속성을 추가하거나 바꿨다면 출시 전에 CloudKit 운영(Production) 스키마 배포를 확인합니다. 개발 환경에서는 새 필드가 자동으로 만들어지지만 TestFlight와 App Store 빌드(운영 환경)에서는 아니라서, 배포하지 않으면 동기화에 실패할 수 있습니다. 운영 스키마는 필드를 지울 수 없으니 속성 삭제, 이름 변경, 타입 변경은 피하고 필요하면 먼저 사용자와 논의합니다.
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

### 명세와 테스트

- 기준은 이슈의 수용 기준과 `Docs/specs/`의 명세입니다. 명세 양식은 `Docs/specs/_TEMPLATE.md`입니다.
- 코드와 명세가 다르면 코드를 명세에 맞춥니다. 기능이 바뀌면 명세 → 테스트 → 코드 순서로 고칩니다.
- 명세와 테스트의 기대값은 요청 없이 고치지 않습니다. 테스트가 실패하면 코드를 고칩니다.
- 새 동작은 실패하는 테스트를 먼저 확인한 뒤 구현합니다. 경계값을 테스트에 넣습니다.
- 확률적인 결과(Vision, Speech, 임베딩 점수)는 테스트 대역으로 고정하고, 결정적인 규칙은 예시표로 테스트합니다.
- 작업이 끝나면 테스트 결과(통과·실패 수)와 바뀐 파일 목록을 보고합니다. 테스트를 실행하지 못했다면 실행하지 못했다고 말합니다.

### Git

- 사용자가 명시적으로 요청한 경우에만 브랜치를 만들거나 커밋합니다. 푸시와 PR 생성도 요청받았을 때만 합니다.
- 브랜치: `feature/#이슈/설명`. 접두어는 이슈 템플릿 종류를 따릅니다(`feature`, `bugfix`, `refactor`, `docs`, `design`, `setting`, `deploy`, `test`). 통합 브랜치는 `develop`입니다.
- 커밋: `[#이슈번호] type: 한국어 설명` (예: `[#67] fix: 공유 확장의 StoredNote 스키마에 photoGroupId 추가`)
- type은 `feat`, `fix`, `refactor`, `docs`, `chore`, `test`를 씁니다.
- PR은 저장소의 PR 템플릿(관련 이슈, 요약, 스크린샷, 테스트, 공유 사항, 리뷰 가이드)을 따릅니다.

## Review guidelines

PR을 리뷰할 때 다음 기준을 따릅니다.

- 이슈의 수용 기준, `Docs/specs/` 명세와 다르거나 빠진 부분을 먼저 봅니다.
- 테스트의 기대값을 바꾸거나 검증 범위를 줄인 변경이 있는지 확인합니다.
- 버그, 크래시, 데이터 손실, 개인정보 노출(로그의 `privacy: .public`, AI 전송)을 우선합니다.
- Hard constraints와 Gotchas 위반을 확인합니다. 특히 Presentation의 SwiftData 직접 접근과 공유 확장 스키마 누락을 봅니다.
- 스타일과 이름 취향은 지적하지 않습니다. 범위 밖 개선은 "범위 밖"으로 한 줄만 남깁니다.
- 지적마다 심각도(필수 수정 / 권장 / 질문), 위치(파일:줄), 실패하는 시나리오를 적습니다. 추측이면 추측이라고 표시합니다.
