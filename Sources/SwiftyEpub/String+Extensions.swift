//
//  File.swift
//  
//
//  Created by Inumaki on 18.11.23.
//

import Foundation

public extension String {
  /// The Unicode character of a soft hyphen.
  ///
  /// - see: [Wikipedia](https://en.wikipedia.org/wiki/Soft_hyphen).
  static let softHyphen = "\u{00AD}"
  
  /// Insert a soft-hyphen character at every possible location in the string.
  ///
  /// - note: Soft-hyphens are only displayed when needed in order to allow
  /// words that are longer than the available space to flow on multiple lines.
  func softHyphenated(withLocale locale: Locale = .autoupdatingCurrent, hyphenCharacter: String = Self.softHyphen) -> Self {
    let localeRef = locale as CFLocale
    guard CFStringIsHyphenationAvailableForLocale(localeRef) else {
      return self
    }
    
    let mutableSelf = NSMutableString(string: self)
    var hyphenationLocations = Array<Bool>(repeating: false, count: count)
    let range = CFRangeMake(0, count)
    
    for i in 0..<count {
      let nextLocation = CFStringGetHyphenationLocationBeforeIndex(
        mutableSelf as CFString,
        i,
        range,
        .zero,
        localeRef,
        nil
      )
      
      if nextLocation >= 0 && nextLocation < count {
        hyphenationLocations[nextLocation] = true
      }
    }
    
    for i in (0..<count).reversed() {
      guard hyphenationLocations[i] else { continue }
      mutableSelf.insert(hyphenCharacter, at: i)
    }
    
    return mutableSelf as String
  }
}
