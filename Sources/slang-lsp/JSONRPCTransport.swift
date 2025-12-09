// Sources/slang-lsp/JSONRPCTransport.swift

import Foundation

/// Handles JSON-RPC communication over stdin/stdout
class JSONRPCTransport {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let stdin = FileHandle.standardInput

    init() {
        encoder.outputFormatting = []  // Compact JSON
    }

    /// Read a single JSON-RPC message from stdin
    func readMessage() -> JSONRPCRequest? {
        // Read headers until empty line (\r\n\r\n)
        var headerData = Data()
        var contentLength: Int?

        // Read header byte by byte until we find \r\n\r\n
        while true {
            let byte = stdin.readData(ofLength: 1)
            if byte.isEmpty {
                return nil  // EOF
            }
            headerData.append(byte)

            // Check for \r\n\r\n at the end
            if headerData.count >= 4 {
                let suffix = headerData.suffix(4)
                if suffix == Data([0x0D, 0x0A, 0x0D, 0x0A]) {  // \r\n\r\n
                    break
                }
            }
        }

        // Parse headers
        if let headerString = String(data: headerData, encoding: .utf8) {
            let lines = headerString.components(separatedBy: "\r\n")
            for line in lines {
                let parts = line.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let header = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
                    let value = parts[1].trimmingCharacters(in: .whitespaces)

                    if header == "content-length" {
                        contentLength = Int(value)
                    }
                }
            }
        }

        guard let length = contentLength, length > 0 else {
            log("No content-length found in headers")
            return nil
        }

        // Read content body
        let contentData = stdin.readData(ofLength: length)
        guard contentData.count == length else {
            log("Failed to read full content: expected \(length), got \(contentData.count)")
            return nil
        }

        do {
            let request = try decoder.decode(JSONRPCRequest.self, from: contentData)
            return request
        } catch {
            log("Failed to decode request: \(error)")
            if let str = String(data: contentData, encoding: .utf8) {
                log("Content was: \(str)")
            }
            return nil
        }
    }

    /// Write a JSON-RPC response to stdout
    func writeResponse(_ response: JSONRPCResponse) {
        do {
            let data = try encoder.encode(response)
            if let str = String(data: data, encoding: .utf8) {
                log("Sending response: \(str)")
            } else {
                return
            }

            let header = "Content-Length: \(data.count)\r\n\r\n"
            FileHandle.standardOutput.write(Data(header.utf8))
            FileHandle.standardOutput.write(data)
        } catch {
            log("Failed to encode response: \(error)")
        }
    }

    /// Write a notification (no id) to stdout
    func writeNotification(method: String, params: AnyCodable?) {
        let notification = JSONRPCRequest(id: nil, method: method, params: params)
        do {
            let data = try encoder.encode(notification)
            let header = "Content-Length: \(data.count)\r\n\r\n"
            FileHandle.standardOutput.write(Data(header.utf8))
            FileHandle.standardOutput.write(data)
        } catch {
            log("Failed to encode notification: \(error)")
        }
    }
}

// MARK: - Logging

private nonisolated(unsafe) var logFile: FileHandle?

func initializeLogging() {
    let logPath = "/tmp/slang-lsp.log"
    FileManager.default.createFile(atPath: logPath, contents: nil)
    logFile = FileHandle(forWritingAtPath: logPath)
}

func log(_ message: String) {
    guard let logFile = logFile else { return }
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    logFile.write(Data(line.utf8))
    try? logFile.synchronize()
}
