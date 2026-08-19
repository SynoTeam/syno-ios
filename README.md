# Syno

사람별로 기록하는 채팅형 메모 앱입니다. 연락처마다 독립된 채팅방을 만들어 텍스트, 사진, 음성, 파일, 링크를 시간순으로 남기고, AI 기반 의미 검색으로 흐릿한 기억만으로도 다시 찾아볼 수 있습니다.

## 주요 기능

- **사람별 채팅형 메모**: 연락처마다 채팅방에서 텍스트/사진/음성/파일/링크를 대화하듯 기록
- **사진 인식**: 촬영·첨부한 사진의 텍스트(OCR)와 사물 라벨을 자동 추출해 검색 가능한 정보로 변환
- **음성 메모(STT)**: 음성으로 남긴 기록을 텍스트로 자동 변환
- **파일 첨부/다운로드**: 문서 등 파일을 채팅에 첨부하고 미리보기·다운로드
- **링크 미리보기**: 공유한 URL의 제목/대표 이미지를 자동으로 가져와 카드로 표시
- **아카이브**: 텍스트/사진/음성메모/파일/링크를 카테고리별로 모아보기
- **AI 검색**: 키워드가 정확히 기억나지 않아도 의미 기반 검색으로 연락처와 메모를 탐색
- **공유 확장(Share Extension)**: 다른 앱에서 텍스트/링크/이미지를 Syno로 바로 공유
- **iCloud 동기화**: CloudKit 기반으로 기기 간 데이터 동기화
- **온보딩 & 프로필 관리**: 최초 실행 온보딩, 내 프로필/연락처 프로필 편집

## 기술 스택

- **UI**: SwiftUI
- **저장소**: SwiftData (+ CloudKit private database 동기화)
- **온디바이스 AI**: Vision(OCR/이미지 라벨링), Speech(음성 인식), NaturalLanguage(의미 기반 임베딩 검색)
- **외부 의존성 없음**: 서드파티 라이브러리 없이 Apple 네이티브 프레임워크로만 구성

## 아키텍처

MVVM + Clean Architecture를 따릅니다.

```
Syno/Syno
├── App             앱 진입점, 의존성 조립, 앱 레벨 설정
├── Presentation    SwiftUI 뷰 · 뷰모델 (Features 단위로 구성)
├── Domain          엔티티, 리포지토리 프로토콜, 핵심 비즈니스 규칙
├── Data            DTO, 데이터소스, 리포지토리 구현, 로컬/서비스 어댑터
├── DesignSystem    색상 · 타이포그래피 · 재사용 UI 컴포넌트
└── Resources       에셋, 폰트 등 리소스
```

의존성 방향: `Presentation`/`Data` → `Domain`. `Domain`은 다른 레이어에 의존하지 않습니다.

### 타겟 구성

- **Syno**: 메인 앱
- **SynoShareExtension**: 다른 앱에서 콘텐츠를 공유받는 iOS 공유 확장 (App Group `group.com.synoteam.Syno`로 메인 앱과 저장소 공유)
- **SynoTests**: 유닛 테스트

## 요구 사항

- Xcode 26 이상
- iOS 26.0+ (Share Extension), iOS 26.2+ (메인 앱)
- Swift 5

## 시작하기

```bash
git clone https://github.com/SynoTeam/syno-ios.git
cd syno-ios/Syno
open Syno.xcodeproj
```

Xcode에서 `Syno` 스킴을 선택하고 시뮬레이터 또는 실기기에서 빌드/실행합니다.

커맨드라인 빌드:

```bash
xcodebuild -project Syno.xcodeproj -scheme Syno -destination 'generic/platform=iOS Simulator' build
```

## 라이선스

[MIT License](LICENSE)
