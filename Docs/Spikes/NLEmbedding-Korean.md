# 한국어 온디바이스 임베딩 기술 검증

검증일: 2026-07-24

## 결론

`NLEmbedding.sentenceEmbedding(for: .korean)`과
`NLEmbedding.wordEmbedding(for: .korean)`은 한국어 검색에 사용할 수 없다.
Simulator와 실기기 모두 지원 revision이 없고 API가 `nil`을 반환했다.

한국어 의미 검색은 iOS 17 이상에서 제공하는 `NLContextualEmbedding`을
우선 후보로 사용한다. 검색 기능에는 토큰 벡터를 mean pooling한 문장 벡터와
cosine distance를 적용할 수 있다.

## 검증 환경

- Simulator: iOS 26.2
- 실기기: iOS 26.5.2
- 언어: `NLLanguage.korean`

## 결과

### 기존 NLEmbedding

- sentence embedding revisions: 0개
- word embedding revisions: 0개
- sentence embedding: `nil`
- word embedding: `nil`
- 실기기 런타임 로그: `Unsupported locale ko.`

### NLContextualEmbedding

- 한국어 모델 생성: 성공
- 차원: 512
- 실기기 asset: 사용 가능
- 관련 문장 cosine distance: 0.172
- 무관 문장 cosine distance: 0.387
- 어휘가 다른 유사 표현 cosine distance: 0.188

거리 값은 작을수록 유사하다. 소규모 표본에서는 관련 문장과 무관 문장이
구분됐고, `회의 일정 확인`과 `미팅 시간 체크`처럼 표면 단어가 다른 표현도
가깝게 측정됐다.

### 문자 bi-gram

- 관련 문장 Jaccard similarity: 0.278
- 무관 문장 Jaccard similarity: 0.038

문자 n-gram은 모델 asset이 없어도 동작하고 오탈자나 부분 문자열에 강하지만,
공통 문자가 없는 동의어와 의미적 재표현을 찾기 어렵다.

## 권장 설계

1. 정확한 키워드 부분 일치를 가장 높은 우선순위로 유지한다.
2. asset이 준비된 기기에서는 `NLContextualEmbedding` 기반 의미 점수를 합산한다.
3. asset이 없거나 모델 로드가 실패하면 문자 bi-gram 점수로 폴백한다.
4. 영어 전용 `NLEmbedding`을 한국어 검색의 기본 경로로 사용하지 않는다.
5. 실제 연락처·메모 문장으로 평가 세트를 만든 뒤 threshold를 결정한다.

`NLContextualEmbedding` 모델 asset은 기기에 없을 수 있으므로
`hasAvailableAssets`를 확인하고, 사용자 동의가 필요한 시점에
`requestAssets()`를 호출하는 흐름이 필요하다.
