// Sources/slang-lsp/LSPServer.swift

import Foundation
import SlangCore

/// The main LSP server
class LSPServer {
    private let transport = JSONRPCTransport()
    private let documentManager = DocumentManager()
    private var isInitialized = false
    private var shouldShutdown = false

    /// Run the server main loop
    func run() {
        initializeLogging()
        log("Slang LSP server started")

        while !shouldShutdown {
            guard let request = transport.readMessage() else {
                // EOF or error - exit the loop
                log("No more messages (EOF or error)")
                break
            }

            log("Received: \(request.method)")
            handleRequest(request)
        }

        log("Slang LSP server shutting down")
    }

    // MARK: - Request Handling

    private func handleRequest(_ request: JSONRPCRequest) {
        switch request.method {
        // Lifecycle
        case "initialize":
            handleInitialize(request)
        case "initialized":
            handleInitialized(request)
        case "shutdown":
            handleShutdown(request)
        case "exit":
            handleExit(request)

        // Document sync
        case "textDocument/didOpen":
            handleDidOpen(request)
        case "textDocument/didClose":
            handleDidClose(request)
        case "textDocument/didChange":
            handleDidChange(request)
        case "textDocument/didSave":
            handleDidSave(request)

        // Language features
        case "textDocument/definition":
            handleDefinition(request)
        case "textDocument/references":
            handleReferences(request)

        default:
            if let id = request.id {
                // Unknown method with id - send error
                let response = JSONRPCResponse(
                    id: id,
                    error: JSONRPCError.methodNotFound
                )
                transport.writeResponse(response)
            }
            // Notifications without id are ignored
        }
    }

    // MARK: - Lifecycle Handlers

    private func handleInitialize(_ request: JSONRPCRequest) {
        guard let id = request.id else { return }

        let result = InitializeResult.default

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(result)
            let json = try JSONSerialization.jsonObject(with: data)
            let response = JSONRPCResponse(id: id, result: AnyCodable(json))
            transport.writeResponse(response)
        } catch {
            log("Failed to encode initialize result: \(error)")
        }

        isInitialized = true
        log("Server initialized")
    }

    private func handleInitialized(_ request: JSONRPCRequest) {
        // Client is now fully initialized
        log("Client initialized")
    }

    private func handleShutdown(_ request: JSONRPCRequest) {
        guard let id = request.id else { return }

        shouldShutdown = true
        let response = JSONRPCResponse(id: id, result: nil)
        transport.writeResponse(response)
        log("Shutdown requested")
    }

    private func handleExit(_ request: JSONRPCRequest) {
        exit(shouldShutdown ? 0 : 1)
    }

    // MARK: - Document Sync Handlers

    private func handleDidOpen(_ request: JSONRPCRequest) {
        guard let params = decodeParams(request, as: DidOpenTextDocumentParams.self) else {
            return
        }

        documentManager.open(
            uri: params.textDocument.uri,
            content: params.textDocument.text
        )
    }

    private func handleDidClose(_ request: JSONRPCRequest) {
        guard let params = decodeParams(request, as: DidCloseTextDocumentParams.self) else {
            return
        }

        documentManager.close(uri: params.textDocument.uri)
    }

    private func handleDidChange(_ request: JSONRPCRequest) {
        guard let params = decodeParams(request, as: DidChangeTextDocumentParams.self) else {
            return
        }

        // We're using full sync, so take the last change
        if let lastChange = params.contentChanges.last {
            documentManager.update(
                uri: params.textDocument.uri,
                content: lastChange.text
            )
        }
    }

    private func handleDidSave(_ request: JSONRPCRequest) {
        guard let params = decodeParams(request, as: DidSaveTextDocumentParams.self) else {
            return
        }

        if let text = params.text {
            documentManager.update(
                uri: params.textDocument.uri,
                content: text
            )
        }
    }

    // MARK: - Language Feature Handlers

    private func handleDefinition(_ request: JSONRPCRequest) {
        guard let id = request.id else { return }
        guard let params = decodeParams(request, as: TextDocumentPositionParams.self) else {
            transport.writeResponse(JSONRPCResponse(id: id, result: nil))
            return
        }

        let uri = params.textDocument.uri
        guard let content = documentManager.getContent(uri: uri),
              let symbols = documentManager.getSymbols(uri: uri) else {
            transport.writeResponse(JSONRPCResponse(id: id, result: nil))
            return
        }

        let converter = PositionConverter(source: content)
        let location = converter.toSourceLocation(params.position)

        log("Looking for definition at line=\(location.line) col=\(location.column)")
        log("Document has \(symbols.definitions.count) definitions, \(symbols.references.count) references")

        // Find symbol at position
        if let definition = findDefinitionAt(location, symbols: symbols, file: uriToPath(uri)) {
            log("Found definition: \(definition.name) at \(definition.nameRange.start.line):\(definition.nameRange.start.column)-\(definition.nameRange.end.line):\(definition.nameRange.end.column)")
            log("Definition file: '\(definition.range.file)'")
            // Use nameRange to jump to the symbol name, not the full declaration
            let range = converter.toRange(definition.nameRange)
            log("Converted range: start=\(range.start.line):\(range.start.character) end=\(range.end.line):\(range.end.character)")
            let defUri = pathToUri(definition.range.file)
            log("Definition URI: '\(defUri)'")
            let resultLocation = Location(uri: defUri, range: range)

            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(resultLocation)
                if let jsonStr = String(data: data, encoding: .utf8) {
                    log("Location JSON: \(jsonStr)")
                }
                let json = try JSONSerialization.jsonObject(with: data)
                log("Sending definition response")
                transport.writeResponse(JSONRPCResponse(id: id, result: AnyCodable(json)))
            } catch {
                log("Failed to encode location: \(error)")
                transport.writeResponse(JSONRPCResponse(id: id, result: nil))
            }
        } else {
            log("No definition found at position")
            transport.writeResponse(JSONRPCResponse(id: id, result: nil))
        }
    }

    private func handleReferences(_ request: JSONRPCRequest) {
        guard let id = request.id else { return }
        guard let params = decodeParams(request, as: ReferenceParams.self) else {
            transport.writeResponse(JSONRPCResponse(id: id, result: AnyCodable([] as [Location])))
            return
        }

        let uri = params.textDocument.uri
        guard let content = documentManager.getContent(uri: uri),
              let symbols = documentManager.getSymbols(uri: uri) else {
            transport.writeResponse(JSONRPCResponse(id: id, result: AnyCodable([] as [Location])))
            return
        }

        let converter = PositionConverter(source: content)
        let location = converter.toSourceLocation(params.position)

        // Find what symbol is at position
        if let definition = findDefinitionAt(location, symbols: symbols, file: uriToPath(uri)) {
            var locations: [Location] = []

            // Include declaration if requested
            if params.context.includeDeclaration {
                // Use nameRange to highlight just the symbol name
                let defRange = converter.toRange(definition.nameRange)
                locations.append(Location(uri: pathToUri(definition.range.file), range: defRange))
            }

            // Find all references across all documents
            for (docUri, state) in documentManager.getAllDocuments() {
                guard let docSymbols = state.symbols else { continue }

                let docConverter = PositionConverter(source: state.content)

                for ref in docSymbols.references {
                    if ref.definition.name == definition.name &&
                       ref.definition.kind == definition.kind &&
                       ref.definition.container == definition.container {
                        let refRange = docConverter.toRange(ref.range)
                        locations.append(Location(uri: docUri, range: refRange))
                    }
                }
            }

            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(locations)
                let json = try JSONSerialization.jsonObject(with: data)
                transport.writeResponse(JSONRPCResponse(id: id, result: AnyCodable(json)))
            } catch {
                transport.writeResponse(JSONRPCResponse(id: id, result: AnyCodable([] as [Location])))
            }
        } else {
            transport.writeResponse(JSONRPCResponse(id: id, result: AnyCodable([] as [Location])))
        }
    }

    // MARK: - Helpers

    private func decodeParams<T: Decodable>(_ request: JSONRPCRequest, as type: T.Type) -> T? {
        guard let params = request.params else {
            return nil
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(params)
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            log("Failed to decode params: \(error)")
            return nil
        }
    }

    /// Find the definition at a given source location
    private func findDefinitionAt(_ location: SourceLocation, symbols: FileSymbols, file: String) -> SymbolDefinition? {
        // First check if cursor is on a reference
        for ref in symbols.references {
            if isLocationInRange(location, ref.range) {
                return ref.definition
            }
        }

        // Then check if cursor is on a definition's NAME (not the full body)
        for def in symbols.definitions {
            if isLocationInRange(location, def.nameRange) {
                return def
            }
        }

        return nil
    }

    private func isLocationInRange(_ location: SourceLocation, _ range: SourceRange) -> Bool {
        if location.line < range.start.line {
            return false
        }
        if location.line == range.start.line && location.column < range.start.column {
            return false
        }
        if location.line > range.end.line {
            return false
        }
        if location.line == range.end.line && location.column > range.end.column {
            return false
        }
        return true
    }
}
