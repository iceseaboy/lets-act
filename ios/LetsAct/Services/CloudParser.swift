import Foundation
import Security

enum SecureToken {
    static func read() -> String {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "LetsAct.Parser", kSecAttrAccount as String: "access-token", kSecReturnData as String: true]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    static func save(_ token: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "LetsAct.Parser", kSecAttrAccount as String: "access-token"]
        SecItemDelete(query as CFDictionary)
        guard !token.isEmpty else { return }
        var item = query
        item[kSecValueData as String] = Data(token.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw ScriptError.serviceUnavailable }
    }
}

enum CloudParser {
    static func parse(text: String, endpoint: String, token: String) async throws -> ParsedScript {
        guard let url = URL(string: endpoint), url.scheme == "https", url.host != nil, url.user == nil, url.password == nil else { throw ScriptError.invalidEndpoint }
        var request = URLRequest(url: url.appendingPathComponent("v1/parse"))
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["text": text, "consent": true])
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        let session = URLSession(configuration: config, delegate: NoRedirect(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200, data.count < 2_000_000 else { throw ScriptError.serviceUnavailable }
        return try JSONDecoder().decode(ParsedScript.self, from: data)
    }
    private final class NoRedirect: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
    }
}
