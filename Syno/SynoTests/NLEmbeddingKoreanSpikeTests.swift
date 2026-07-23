import NaturalLanguage
import XCTest

final class NLEmbeddingKoreanSpikeTests: XCTestCase {
  func testKoreanEmbeddingAvailabilityAndBasicQuality() throws {
    let language = NLLanguage.korean
    let sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: language)
    let wordEmbedding = NLEmbedding.wordEmbedding(for: language)
    let relatedSentence = "민수와 내일 오후에 회의가 있어요"
    let relatedParaphrase = "내일 오후 민수와 미팅하기"
    let unrelatedSentence = "주말에 토마토 파스타를 요리했어요"

    var report = [
      "runtime=\(ProcessInfo.processInfo.operatingSystemVersionString)",
      "sentenceRevisions=\(NLEmbedding.supportedSentenceEmbeddingRevisions(for: language))",
      "wordRevisions=\(NLEmbedding.supportedRevisions(for: language))",
      "sentenceEmbeddingAvailable=\(sentenceEmbedding != nil)",
      "wordEmbeddingAvailable=\(wordEmbedding != nil)"
    ]

    if let sentenceEmbedding {
      let relatedDistance = sentenceEmbedding.distance(
        between: relatedSentence,
        and: relatedParaphrase,
        distanceType: .cosine
      )
      let unrelatedDistance = sentenceEmbedding.distance(
        between: relatedSentence,
        and: unrelatedSentence,
        distanceType: .cosine
      )
      report.append("sentenceDimension=\(sentenceEmbedding.dimension)")
      report.append("sentenceRelatedDistance=\(relatedDistance)")
      report.append("sentenceUnrelatedDistance=\(unrelatedDistance)")
      XCTAssertLessThan(
        relatedDistance,
        unrelatedDistance,
        "관련 한국어 문장이 무관한 문장보다 가깝게 측정돼야 합니다."
      )
    }

    if let wordEmbedding {
      let words = ["회의", "미팅", "바나나"]
      report.append("wordDimension=\(wordEmbedding.dimension)")
      report.append(
        "wordVocabulary=\(words.map { "\($0):\(wordEmbedding.contains($0))" }.joined(separator: ","))"
      )

      if words.allSatisfy(wordEmbedding.contains) {
        report.append(
          "wordRelatedDistance=\(wordEmbedding.distance(between: "회의", and: "미팅", distanceType: .cosine))"
        )
        report.append(
          "wordUnrelatedDistance=\(wordEmbedding.distance(between: "회의", and: "바나나", distanceType: .cosine))"
        )
      }
    }

    if let contextualEmbedding = NLContextualEmbedding(language: language) {
      report.append("contextualEmbeddingAvailable=true")
      report.append("contextualModel=\(contextualEmbedding.modelIdentifier)")
      report.append("contextualDimension=\(contextualEmbedding.dimension)")
      report.append("contextualAssetsOnDevice=\(contextualEmbedding.hasAvailableAssets)")

      if contextualEmbedding.hasAvailableAssets {
        do {
          try contextualEmbedding.load()
          defer { contextualEmbedding.unload() }

          let relatedDistance = try contextualDistance(
            between: relatedSentence,
            and: relatedParaphrase,
            using: contextualEmbedding
          )
          let unrelatedDistance = try contextualDistance(
            between: relatedSentence,
            and: unrelatedSentence,
            using: contextualEmbedding
          )
          let semanticDistance = try contextualDistance(
            between: "회의 일정 확인",
            and: "미팅 시간 체크",
            using: contextualEmbedding
          )
          report.append("contextualRelatedDistance=\(relatedDistance)")
          report.append("contextualUnrelatedDistance=\(unrelatedDistance)")
          report.append("contextualSemanticParaphraseDistance=\(semanticDistance)")
        } catch {
          report.append("contextualQualityError=\(error)")
        }
      }
    } else {
      report.append("contextualEmbeddingAvailable=false")
    }

    report.append(
      "characterNGramRelatedSimilarity=\(characterNGramSimilarity(relatedSentence, relatedParaphrase))"
    )
    report.append(
      "characterNGramUnrelatedSimilarity=\(characterNGramSimilarity(relatedSentence, unrelatedSentence))"
    )
    report.append(
      "characterNGramSemanticParaphraseSimilarity=\(characterNGramSimilarity("회의 일정 확인", "미팅 시간 체크"))"
    )

    let output = report.joined(separator: "\n")
    print("NLEmbedding Korean spike\n\(output)")
    let attachment = XCTAttachment(string: output)
    attachment.name = "NLEmbedding Korean spike"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func contextualDistance(
    between lhs: String,
    and rhs: String,
    using embedding: NLContextualEmbedding
  ) throws -> Double {
    let lhsVector = try pooledVector(for: lhs, using: embedding)
    let rhsVector = try pooledVector(for: rhs, using: embedding)
    let dotProduct = zip(lhsVector, rhsVector).reduce(0) { $0 + ($1.0 * $1.1) }
    let lhsMagnitude = sqrt(lhsVector.reduce(0) { $0 + ($1 * $1) })
    let rhsMagnitude = sqrt(rhsVector.reduce(0) { $0 + ($1 * $1) })
    guard lhsMagnitude > 0, rhsMagnitude > 0 else {
      return 1
    }
    return 1 - (dotProduct / (lhsMagnitude * rhsMagnitude))
  }

  private func pooledVector(
    for text: String,
    using embedding: NLContextualEmbedding
  ) throws -> [Double] {
    let result = try embedding.embeddingResult(for: text, language: .korean)
    var sum = Array(repeating: 0.0, count: embedding.dimension)
    var count = 0
    result.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { vector, _ in
      for index in vector.indices {
        sum[index] += vector[index]
      }
      count += 1
      return true
    }
    guard count > 0 else {
      return sum
    }
    return sum.map { $0 / Double(count) }
  }

  private func characterNGramSimilarity(
    _ lhs: String,
    _ rhs: String,
    size: Int = 2
  ) -> Double {
    let lhsNGrams = characterNGrams(lhs, size: size)
    let rhsNGrams = characterNGrams(rhs, size: size)
    guard !lhsNGrams.isEmpty || !rhsNGrams.isEmpty else {
      return 1
    }
    return Double(lhsNGrams.intersection(rhsNGrams).count)
      / Double(lhsNGrams.union(rhsNGrams).count)
  }

  private func characterNGrams(_ text: String, size: Int) -> Set<String> {
    let characters = Array(
      text.filter { !$0.isWhitespace }
    )
    guard characters.count >= size else {
      return characters.isEmpty ? [] : [String(characters)]
    }

    return Set(
      (0...(characters.count - size)).map {
        String(characters[$0..<($0 + size)])
      }
    )
  }
}
