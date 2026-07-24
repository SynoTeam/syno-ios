import Foundation
import NaturalLanguage

enum TextEmbeddingError: Error {
  case unsupportedLanguage
  case assetsUnavailable
  case emptyResult
}

actor NLContextualTextEmbeddingProvider: TextEmbeddingProviding {
  private lazy var model = NLContextualEmbedding(language: .korean)
  private var isLoaded = false

  func embedding(for text: String) async throws -> [Double] {
    guard let model else {
      throw TextEmbeddingError.unsupportedLanguage
    }
    guard model.hasAvailableAssets else {
      throw TextEmbeddingError.assetsUnavailable
    }
    if !isLoaded {
      try model.load()
      isLoaded = true
    }

    let result = try model.embeddingResult(for: text, language: .korean)
    var sum = Array(repeating: 0.0, count: model.dimension)
    var count = 0
    result.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { vector, _ in
      for index in vector.indices {
        sum[index] += vector[index]
      }
      count += 1
      return true
    }
    guard count > 0 else {
      throw TextEmbeddingError.emptyResult
    }
    return sum.map { $0 / Double(count) }
  }
}
