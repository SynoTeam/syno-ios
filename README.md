# Syno

사람별로 기록하는 채팅형 메모 앱입니다. 연락처마다 독립된 채팅방을 만들어 텍스트, 사진, 음성, 파일, 링크를 시간순으로 남기고, AI 기반 의미 검색으로 흐릿한 기억만으로도 다시 찾아볼 수 있습니다.

<a href="https://apps.apple.com/kr/app/syno-%EC%B1%84%ED%8C%85%ED%98%95-%EB%A9%94%EB%AA%A8-%EA%B8%B0%EC%96%B5-%EA%B4%80%EB%A6%AC-ai-%EA%B2%80%EC%83%89/id6795835895">
  <img src="https://github-production-user-asset-6210df.s3.amazonaws.com/75518683/268173445-322afec8-38fa-46ba-bbe0-3fffd0c93f5b.png" alt="appstore" height="80"/>
</a>

## 주요 기능

현재 버전: **1.2.0**

### 연락처
- 연락처 추가/편집: 이름, 국가번호별 전화번호, 그룹, 생일·기념일, 소셜 링크, 한 줄 기록, 프로필 사진(촬영·앨범 선택 후 크롭)
- 휴대폰 연락처에서 불러오기 (여러 명 일괄 가져오기 지원)
- 즐겨찾기(Favorite) · 그룹별 분류, 그룹 추가/편집/삭제
- 여러 연락처 선택 삭제

### 사람별 채팅형 메모
- 연락처마다 독립된 채팅방에 텍스트/사진/음성/파일/링크를 대화하듯 기록
- **사진**: 카메라 촬영·앨범 선택, 전송 전 미리보기 확인. OCR 텍스트와 사물 라벨을 자동 추출해 검색에 활용
- **음성 메모(STT)**: 녹음한 음성을 텍스트로 자동 변환 (실패 시 재시도)
- **파일**: 문서 첨부, 미리보기, 다운로드(iCloud 파일 확인 포함)
- **링크 미리보기**: URL의 제목/대표 이미지를 가져와 카드로 표시
- 메시지 복사 · iOS 공유 시트로 공유 · 긴 메시지 전체보기 · 여러 메시지 선택 삭제
- 채팅 내 검색: 일치 항목 하이라이트 및 이전/다음 이동

### 노트 탭
- 기록이 있는 연락처별 노트 목록, 노트 고정(Pin)
- 그룹 필터, 최신순/이름순 정렬, 여러 노트 선택 삭제

### 아카이브
- 채팅방의 텍스트/사진/음성 메모/파일/링크를 카테고리별로 모아보기 및 카테고리 내 검색

### 검색
- 전체 메모를 텍스트/사진/링크/음성메모/파일 카테고리로 나눠 검색
- 메모 본문, 연락처 이름, 사진 OCR·라벨, 음성 변환 텍스트, 파일명을 대상으로 검색
- 온디바이스 문장 임베딩 기반 의미 검색 + 짧은 검색어를 위한 문자 n-gram 보조 매칭
- 최근 검색어 저장/삭제

### 공유 확장(Share Extension)
- 다른 앱에서 텍스트 · 링크 · 이미지(1개)를 Syno로 공유하고, 저장할 연락처를 선택

### 설정 · 기타
- 온보딩(기본 정보 입력, 이용약관·개인정보 처리방침 동의), 내 프로필 편집
- 노트 저장공간 관리: 연락처별 미디어(사진·음성·파일) 용량 확인 및 삭제
- 임시 데이터 삭제, 로그아웃(로컬·iCloud 데이터 초기화)
- iCloud 동기화: SwiftData + CloudKit private database로 기기 간 동기화

## 기술 스택

- **UI**: SwiftUI
- **저장소**: SwiftData (+ CloudKit private database 동기화)
- **온디바이스 AI**: Vision(OCR/이미지 라벨링), Speech(음성 인식), NaturalLanguage(`NLContextualEmbedding` 기반 의미 검색)
- **시스템 연동**: Contacts(연락처 가져오기), PhotosUI, QuickLook, Share Extension
- **제품 분석**: Amplitude Unified SDK를 사용하며, 연락처·메모 원문을 제외한 기능 이용 이벤트만 전송

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

Amplitude를 활성화하려면 로컬 설정 파일을 만들고 API Key를 입력합니다.

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

`Config/Secrets.xcconfig`의 `AMPLITUDE_API_KEY` 값을 채우면 Xcode 실행과 Archive에
자동으로 적용됩니다. 이 파일은 Git에서 제외됩니다. 키가 없으면 앱은 분석 기능만
비활성화하고 정상 실행됩니다. CI나 커맨드라인에서는 키를 빌드 설정으로 직접 전달할
수 있습니다.

커맨드라인 빌드:

```bash
xcodebuild \
  -project Syno.xcodeproj \
  -scheme Syno \
  -destination 'generic/platform=iOS Simulator' \
  AMPLITUDE_API_KEY="$AMPLITUDE_API_KEY" \
  build
```

## 라이선스

[MIT License](LICENSE)
