//
// SwiftGenKit
// Copyright © 2022 SwiftGen
// MIT Licence
//

import Foundation
import PathKit

extension Strings {
  struct File {
    let path: Path
    let name: String
    let document: Document

    init(path: Path, relativeTo parent: Path? = nil) throws {
      let data: Data = try path.read()

      self.path = parent.flatMap { path.relative(to: $0) } ?? path
      self.name = path.lastComponentWithoutExtension

      do {
        self.document = try JSONDecoder().decode(Document.self, from: data)
      } catch let error {
        throw ParserError.invalidFormat(reason: error.localizedDescription)
      }
    }
  }

  struct Document: Decodable {
    let sourceLanguage: String
    let strings: [String: StringCatalogEntry]
  }

  struct StringCatalogEntry: Decodable {
    let comment: String?
    let localizations: [String: Localization]
  }

  struct Localization: Decodable {
    let stringUnit: StringUnit?
    let variations: Variations?
    let substitutions: [String: Substitution]?
  }

  struct Variations: Decodable {
    let plural: PluralVariation?
  }

  struct Substitution: Decodable {
    let formatSpecifier: String
    let variations: Variations?
  }

  struct PluralVariation: Decodable {
    let zero: Variation?
    let one: Variation?
    let two: Variation?
    let few: Variation?
    let many: Variation?
    let other: Variation

    var all: [Variation] {
      [
        zero,
        one,
        two,
        few,
        many,
        other
      ].compactMap { $0 }
    }
  }

  struct Variation: Decodable {
    let stringUnit: StringUnit
  }

  struct StringUnit: Decodable {
    let value: String
  }
}

//extension Strings.Localization {
//  /// Extract the placeholders (`NSStringFormatValueTypeKey`) from the different variable
//  /// definitions into a single flattened list of placeholders
//  var formatKeyWithVariableValueTypes: String {
//    let formatKey = stringUnit?.value ?? ""
//      let variables = self.variations?.plural?.all
//    var result = formatKey
//    var offset = 0
//
//    for (name, var nsrange, positionalArgument) in StringsDict.variableNames(fromFormatKey: formatKey) {
//      guard let variable = variables.first(where: { $0.name == name }) else { continue }
//
//      let variablePlaceholder: String
//      if let positionalArgument = positionalArgument {
//        variablePlaceholder = "%\(positionalArgument)$\(variable.rule.valueTypeKey)"
//      } else {
//        variablePlaceholder = "%\(variable.rule.valueTypeKey)"
//      }
//
//      nsrange.location += offset
//      guard let range = Range(nsrange, in: result) else { continue }
//      result.replaceSubrange(range, with: variablePlaceholder)
//      offset += variablePlaceholder.count - nsrange.length
//    }
//
//    return result
//  }
//}

