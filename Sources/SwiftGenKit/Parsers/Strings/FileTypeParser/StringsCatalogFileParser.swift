//
// SwiftGenKit
// Copyright © 2022 SwiftGen
// MIT Licence
//

import Foundation
import PathKit

extension Strings {
  final class StringsCatalogFileParser: StringsFileTypeParser {
    private let options: ParserOptionValues

    init(options: ParserOptionValues) {
      self.options = options
    }

    static let extensions = ["xcstrings"]

    func parseFile(at path: Path) throws -> [Strings.Entry] {
      let file = try File(path: path)
      let entries = try parseFile(file)
      return entries
    }

    func parseFile(_ file: File) throws -> [Strings.Entry] {
      let sourceLanguage = file.document.sourceLanguage

      do {
        return try file.document.strings.compactMap { key, entry -> Strings.Entry? in
          guard let localization = entry.localizations[sourceLanguage] else {
            return nil
          }
          var stringEntry = Strings.Entry(
            key: key,
            translation: translation(from: localization, key: key),
            types: try placeholderFormat(from: localization, key: key),
            keyStructureSeparator: options[Option.separator]
          )
          stringEntry.comment = entry.comment
          return stringEntry
        }
      } catch {
        throw error
      }
    }

    private func translation(
      from localization: Strings.Localization,
      key: String
    ) -> String {
      if localization.variations?.plural != nil {
        return "Plural format key: \(key)"
      }
      return localization.stringUnit?.value ?? "Key: \(key)"
    }

    private func placeholderFormat(
      from localization: Strings.Localization,
      key: String
    ) throws -> [Strings.PlaceholderType] {
      let placeholderTypes = try Strings.PlaceholderType.placeholderTypes(
        fromFormat: localization.allFormatSpecifiers ?? key
      )
      if !placeholderTypes.isEmpty {
        return placeholderTypes
      } else {
        let plurals = localization.variations?.plural?.all.map { $0.stringUnit.value } ?? []
        let types = try plurals.map { format in try Strings.PlaceholderType.placeholderTypes(fromFormat: format) }
        return types.first { types in
          !types.isEmpty
        } ?? []
      }
    }
  }
}

extension Strings.Localization {
    /// Extract the format specifiers from the different variable substitution
    /// definitions into a single flattened list of placeholders
    var allFormatSpecifiers: String? {
      guard let stringUnit else { return nil }
      guard let substitutions else {
        return stringUnit.value
      }
      let formatKey = stringUnit.value
      var result = formatKey
      var offset = 0

      for (name, var nsrange, positionalArgument) in Strings.variableNames(fromFormatKey: formatKey) {
        guard let variable = substitutions.first(where: { $0.key == name }) else { continue }

        let variablePlaceholder: String
        if let positionalArgument = positionalArgument {
          variablePlaceholder = "%\(positionalArgument)$\(variable.value.formatSpecifier)"
        } else {
          variablePlaceholder = "%\(variable.value.formatSpecifier)"
        }

        nsrange.location += offset
        guard let range = Range(nsrange, in: result) else { continue }
        result.replaceSubrange(range, with: variablePlaceholder)
        offset += variablePlaceholder.count - nsrange.length
      }

      return result
    }
}
