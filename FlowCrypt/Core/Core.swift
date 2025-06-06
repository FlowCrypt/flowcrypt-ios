//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import JavaScriptCore
import WebKit

enum CoreError: LocalizedError, Equatable {
    case exception(String) // core threw exception
    case value(String) // wrong value passed into or returned by a function

    var errorDescription: String? {
        switch self {
        case let .exception(message),
             let .value(message):
            return message
        }
    }
}

protocol KeyDecrypter {
    func decryptKey(armoredPrv: String, passphrase: String) async throws -> CoreRes.DecryptKey
}

protocol KeyParser {
    func parseKeys(armoredOrBinary: Data) async throws -> CoreRes.ParseKeys
}

class Core: KeyDecrypter, KeyParser, CoreComposeMessageType {
    static let shared = Core()

    private typealias CallbackResult = (String, [UInt8])

    private var webView: WKWebView!

    private lazy var logger = Logger.nested(in: Self.self, with: "Js")
    private let coreMessageHandler = CoreMessageHandler()

    private struct RawRes {
        let json: Data
        let data: Data
    }

    private struct AttachmentTreatAsResponse: Decodable {
        let atts: [CoreRes.AttachmentTreatAs]
    }

    private init() {
        Task {
            await setupWebView()
        }
    }

    // MARK: - Setup
    @MainActor
    func setupWebView() {
        let userController = WKUserContentController()
        userController.add(self.coreMessageHandler, name: "coreHost")
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userController
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView.navigationDelegate = self.coreMessageHandler

        // Load a simple HTML file in the web view and run the `flowcrypt-ios-prod.js.txt` code.
        // This mechanism is used because the SubtleCrypto API is only available in secure contexts,
        // and `file://` URLs are considered secure.
        // More info: https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts

        let url = Bundle.main.url(forResource: "simple_webview_file", withExtension: "html")!
        webView.load(URLRequest(url: url))
    }

    // MARK: - Config
    func version() async throws -> CoreRes.Version {
        let r = try await call("version")
        return try r.json.decodeJson(as: CoreRes.Version.self)
    }

    func setClientConfiguration(_ config: ClientConfiguration) async throws {
        try await call(
            "setClientConfiguration",
            params: ["shouldHideArmorMeta": config.shouldHideArmorMeta]
        )
    }

    // MARK: Keys
    func parseKeys(armoredOrBinary: Data) async throws -> CoreRes.ParseKeys {
        let r = try await call("parseKeys", data: armoredOrBinary)
        return try r.json.decodeJson(as: CoreRes.ParseKeys.self)
    }

    func decryptKey(armoredPrv: String, passphrase: String) async throws -> CoreRes.DecryptKey {
        let r = try await call("decryptKey", params: ["armored": armoredPrv, "passphrases": [passphrase]])
        return try r.json.decodeJson(as: CoreRes.DecryptKey.self)
    }

    func encryptKey(armoredPrv: String, passphrase: String) async throws -> CoreRes.EncryptKey {
        let r = try await call("encryptKey", params: ["armored": armoredPrv, "passphrase": passphrase])
        return try r.json.decodeJson(as: CoreRes.EncryptKey.self)
    }

    func generateKey(passphrase: String, variant: KeyVariant, userIds: [UserId]) async throws -> CoreRes.GenerateKey {
        let params: [String: Any] = try [
            "passphrase": passphrase,
            "variant": String(variant.rawValue),
            "userIds": userIds.map { try $0.toJsonEncodedDict() }
        ]
        let r = try await call("generateKey", params: params)
        return try r.json.decodeJson(as: CoreRes.GenerateKey.self)
    }

    func verifyKey(armoredPrv: String) async throws {
        try await call(
            "verifyKey",
            params: ["armored": armoredPrv]
        )
    }

    // MARK: Files
    func parseAttachmentType(msgId: Identifier, atts: [MessageAttachment]) async throws -> [CoreRes.AttachmentTreatAs] {
        let parsed = try await call("parseAttachmentType", params: [
            "atts": atts.map { $0.toDict(msgId: msgId) }
        ])
        return try parsed.json.decodeJson(as: AttachmentTreatAsResponse.self).atts
    }

    func decryptFile(encrypted: Data, keys: [Keypair], msgPwd: String?) async throws -> CoreRes.DecryptFile {
        struct DecryptFileRaw: Decodable {
            let decryptSuccess: DecryptSuccess?
            let decryptErr: DecryptErr?

            struct DecryptSuccess: Decodable {
                let name: String
            }
        }

        let decrypted = try await call("decryptFile", params: [
            "keys": keys.map(\.prvKeyInfoJsonDictForCore),
            "msgPwd": msgPwd
        ], data: encrypted)

        let decryptFileRes = try decrypted.json.decodeJson(as: DecryptFileRaw.self)

        if let decryptErr = decryptFileRes.decryptErr {
            return CoreRes.DecryptFile(
                decryptSuccess: nil,
                decryptErr: decryptErr
            )
        }

        guard let decryptSuccess = decryptFileRes.decryptSuccess else {
            throw AppErr.unexpected("decryptFile: both decryptErr and decryptSuccess were nil")
        }

        return CoreRes.DecryptFile(
            decryptSuccess: CoreRes.DecryptFile.DecryptSuccess(
                name: decryptSuccess.name,
                data: decrypted.data
            ),
            decryptErr: nil
        )
    }

    func encrypt(file: Data, name: String, pubKeys: [String]?) async throws -> Data {
        try await call(
            "encryptFile",
            params: ["pubKeys": pubKeys, "name": name],
            data: file
        ).data
    }

    // MARK: - Messages
    func encrypt(data: Data, pubKeys: [String]?, password: String?) async throws -> Data {
        try await call(
            "encryptMsg",
            params: ["pubKeys": pubKeys, "msgPwd": password],
            data: data
        ).data
    }

    func sanitizeHtml(html: String) async throws -> String {
        struct SanitizeHtmlRaw: Decodable {
            let sanitizedHtml: String
        }
        let params: [String: String] = [
            "html": html
        ]

        let parsed = try await call(
            "sanitizeHtml",
            params: params
        )

        let res = try parsed.json.decodeJson(as: SanitizeHtmlRaw.self)

        return res.sanitizedHtml
    }

    func parseDecryptMsg(
        encrypted: Data,
        keys: [Keypair],
        msgPwd: String?,
        isMime: Bool,
        verificationPubKeys: [String]
    ) async throws -> CoreRes.ParseDecryptMsg {
        struct ParseDecryptMsgRaw: Decodable {
            let replyType: ReplyType
            let text: String
        }
        let params: [String: Any?] = [
            "keys": keys.map(\.prvKeyInfoJsonDictForCore),
            "isMime": isMime,
            "msgPwd": msgPwd,
            "verificationPubkeys": verificationPubKeys
        ]

        let parsed = try await call(
            "parseDecryptMsg",
            params: params,
            data: encrypted
        )

        let meta = try parsed.json.decodeJson(as: ParseDecryptMsgRaw.self)

        let blocks = parsed.data
            .split(separator: 10) // newline separated block jsons, one json per line
            .map(MsgBlock.decode)

        return CoreRes.ParseDecryptMsg(
            replyType: meta.replyType,
            text: meta.text,
            blocks: blocks
        )
    }

    func composeEmail(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail {
        let r = try await call("composeEmail", params: [
            "text": msg.text,
            "html": msg.html,
            "to": msg.to,
            "cc": msg.cc,
            "bcc": msg.bcc,
            "from": msg.from,
            "subject": msg.subject,
            "replyToMsgId": msg.replyToMsgId,
            "inReplyTo": msg.inReplyTo,
            "atts": msg.atts.map { att in ["name": att.name, "type": att.type, "base64": att.base64] },
            "format": fmt.rawValue,
            "pubKeys": fmt == .plain ? nil : msg.pubKeys,
            "signingPrv": msg.signingPrv.ifNotNil(\.prvKeyInfoJsonDictForCore)
        ])
        return CoreRes.ComposeEmail(mimeEncoded: r.data)
    }

    func zxcvbnStrengthBar(passPhrase: String) async throws -> CoreRes.ZxcvbnStrengthBar {
        let r = try await call(
            "zxcvbnStrengthBar",
            params: ["value": passPhrase, "purpose": "passphrase"]
        )
        return try r.json.decodeJson(as: CoreRes.ZxcvbnStrengthBar.self)
    }

    private func waitUntilJavascirptReady(timeout: TimeInterval = 1) async throws {
        let functionName = "handleRequestFromHost"
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await (try? webView.callAsyncJavaScript(
                "return typeof \(functionName) === 'function';",
                arguments: [:],
                contentWorld: .page
            )) as? Bool == true {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        throw CoreError.value("JavaScript function \(functionName) is not available within \(timeout) seconds.")
    }

    // MARK: Private calls
    @discardableResult
    private func call(_ endpoint: String, params: [String: Any?] = [:], data: Data = Data(), retryAttempt: Int = 0) async throws -> RawRes {
        let paramsData = try JSONSerialization.data(withJSONObject: params).toStr()
        let requestData = [UInt8](data)

        do {
            try await waitUntilJavascirptReady()
            let response = try await webView.callAsyncJavaScript(
                "return handleRequestFromHost(\"\(endpoint)\", \(paramsData), \(requestData))",
                arguments: [:],
                contentWorld: .page
            )
            guard let response = response as? [String: Any],
                  let uInt8Data = response["data"] as? [String: UInt8]
            else {
                throw CoreError.value("JavaScript callback response not available")
            }

            var responseJson: Data?
            if let resJson = response["json"] as? [String: Any] {
                responseJson = try JSONSerialization.data(withJSONObject: resJson, options: .prettyPrinted)
                if let error = try? responseJson?.decodeJson(as: CoreRes.Error.self) {
                    let errorStack = error.error.stack ?? "no stack"
                    logger.logError("""
                    ------ js err -------
                    Core \(endpoint): \(error.error.message)
                    \(errorStack)
                    ------- end js err -----
                    """)
                    throw CoreError.exception(error.error.message + "\n" + errorStack)
                }
            }

            let indices = uInt8Data.keys.compactMap(Int.init).sorted()
            let array = indices.compactMap { uInt8Data["\($0)"] }
            let responseData = Data(array)

            return RawRes(json: responseJson ?? Data(), data: responseData)
        } catch {
            // Re-setup the webview only when the retry attempt is less than 3 to avoid entering an infinite loop
            if error._domain == "WKErrorDomain", retryAttempt < 3 {
                // Core js code injected using evaluateJavaScript result is removed when app is in background for long time
                // Need to setup again. https://github.com/FlowCrypt/flowcrypt-ios/issues/2013
                await setupWebView()
                return try await call(endpoint, params: params, data: data, retryAttempt: retryAttempt + 1)
            }
            throw error
        }
    }
}

class CoreMessageHandler: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    private lazy var logger = Logger.nested("Core")

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageDict = message.body as? [String: Any],
              let messageName = messageDict["name"] as? String
        else { return }

        if messageName == "log", let logMessage = messageDict["message"] as? String {
            logger.logDebug(logMessage)
        }
    }

    private func getCoreJsFile() -> String? {
        guard let jsFile = Bundle(for: Self.self).path(
            forResource: "flowcrypt-ios-prod.js.txt",
            ofType: nil
        ) else { return nil }
        return try? String(contentsOfFile: jsFile)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let jsFileSrc = self.getCoreJsFile() else { return }
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "[unknown version]"
        webView.evaluateJavaScript("const APP_VERSION = 'iOS \(appVersion)';\(jsFileSrc)") { _, _ in }
    }
}

private extension Encodable {
    func toJsonEncodedDict() throws -> [String: Any] {
        let data = try self.toJsonData()

        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw AppErr.general("Could not produce JSON encoded dictionary")
        }

        return dictionary
    }
}
