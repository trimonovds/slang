// Sources/slang-lsp/DocumentManager.swift

import Foundation
import SlangCore

/// Manages open documents and their parsed state
class DocumentManager {
    /// Open documents: URI -> (content, symbols)
    private var documents: [String: DocumentState] = [:]

    struct DocumentState {
        let content: String
        let symbols: FileSymbols?
        let declarations: [Declaration]?
    }

    /// Open a document
    func open(uri: String, content: String) {
        let state = parseDocument(uri: uri, content: content)
        documents[uri] = state
        log("Opened document: \(uri)")
    }

    /// Close a document
    func close(uri: String) {
        documents.removeValue(forKey: uri)
        log("Closed document: \(uri)")
    }

    /// Update a document
    func update(uri: String, content: String) {
        let state = parseDocument(uri: uri, content: content)
        documents[uri] = state
        log("Updated document: \(uri)")
    }

    /// Get document content
    func getContent(uri: String) -> String? {
        return documents[uri]?.content
    }

    /// Get symbols for a document
    func getSymbols(uri: String) -> FileSymbols? {
        return documents[uri]?.symbols
    }

    /// Get declarations for a document
    func getDeclarations(uri: String) -> [Declaration]? {
        return documents[uri]?.declarations
    }

    /// Get all documents
    func getAllDocuments() -> [String: DocumentState] {
        return documents
    }

    // MARK: - Private

    private func parseDocument(uri: String, content: String) -> DocumentState {
        let filePath = uriToPath(uri)

        do {
            let lexer = Lexer(source: content, filename: filePath)
            let tokens = try lexer.tokenize()

            var parser = Parser(tokens: tokens)
            let declarations = try parser.parse()

            let collector = SymbolCollector()
            let symbols = collector.collect(declarations: declarations, file: filePath)

            return DocumentState(content: content, symbols: symbols, declarations: declarations)
        } catch {
            log("Parse error for \(uri): \(error)")
            return DocumentState(content: content, symbols: nil, declarations: nil)
        }
    }
}

// MARK: - URI Utilities

func uriToPath(_ uri: String) -> String {
    if uri.hasPrefix("file://") {
        var path = String(uri.dropFirst(7))
        // Decode URL encoding
        path = path.removingPercentEncoding ?? path
        return path
    }
    return uri
}

func pathToUri(_ path: String) -> String {
    let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
    return "file://\(encoded)"
}
