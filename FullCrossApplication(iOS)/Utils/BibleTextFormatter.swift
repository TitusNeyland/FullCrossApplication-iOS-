import Foundation
import SwiftSoup

// MARK: - BibleTextFormatter
enum BibleTextFormatter {
    struct FormattedVerse {
        let text: String
        let verseNumber: String
        let isVerseStart: Bool
    }
    
    static func formatBibleText(_ htmlContent: String) -> [FormattedVerse] {
        var formattedVerses: [FormattedVerse] = []
        
        do {
            let document = try SwiftSoup.parse(htmlContent)
            let verses = try document.select("span.v")
            
            for verse in verses {
                let verseNumber = try verse.text()
                try verse.text(" ") // Clear the verse number
                
                // Get text until next verse marker
                var verseText = ""
                var current = verse.nextSibling()
                
                while let node = current {
                    if let element = node as? Element, try element.hasClass("v") {
                        break
                    }
                    verseText += node.description
                    current = node.nextSibling()
                }
                
                // Clean up verse text
                verseText = cleanVerseText(verseText)
                
                //print("Parsed verse \(verseNumber): \(verseText)") // Debug print
                
                formattedVerses.append(FormattedVerse(
                    text: verseText,
                    verseNumber: verseNumber,
                    isVerseStart: true
                ))
            }
        } catch {
            print("Error parsing HTML: \(error)")
        }
        
        return formattedVerses
    }
    
    // MARK: - Helper Methods
    private static func cleanVerseText(_ text: String) -> String {
        var cleanText = text
        
        // Replace HTML entities with proper Unicode characters
        let htmlEntities = [
            "&nbsp;": " ",
            "&quot;": "\"",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&apos;": "'",
            "&#39;": "'",
            "&ldquo;": "\u{201C}", // Left double quotation mark
            "&rdquo;": "\u{201D}", // Right double quotation mark
            "&rsquo;": "\u{2019}", // Right single quotation mark
            "&lsquo;": "\u{2018}", // Left single quotation mark
            "&mdash;": "\u{2014}", // Em dash
            "&ndash;": "\u{2013}", // En dash
            "&hellip;": "\u{2026}", // Ellipsis
            "&#8217;": "\u{2019}", // Right single quotation mark
            "&#8216;": "\u{2018}", // Left single quotation mark
            "&#8220;": "\u{201C}", // Left double quotation mark
            "&#8221;": "\u{201D}", // Right double quotation mark
            "&#8230;": "\u{2026}"  // Ellipsis
        ]
        
        for (entity, replacement) in htmlEntities {
            cleanText = cleanText.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Remove HTML tags
        cleanText = cleanText.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // Replace multiple spaces with single space
        cleanText = cleanText.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        // Remove leading/trailing whitespace
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanText
    }
}

// MARK: - Usage Example
extension BibleTextFormatter {
    static func example() {
        let htmlContent = """
        <div class="chapter">
            <span class="v">1</span>In the beginning
            <span class="v">2</span>And God said
            <span class="v">3</span>Let there be light
        </div>
        """
        
        let formattedVerses = formatBibleText(htmlContent)
        formattedVerses.forEach { verse in
            print("Verse \(verse.verseNumber): \(verse.text)")
        }
    }
} 
