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

    private lazy var webView: WKWebView = {
        let userController = WKUserContentController()
        userController.add(webMessageHandler, name: "coreHost")
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userController
        return WKWebView(frame: .zero, configuration: configuration)
    }()

    private lazy var logger = Logger.nested(in: Self.self, with: "Js")
    private let webMessageHandler = WebMessageHandler()

    private struct RawRes {
        let json: Data
        let data: Data
    }

    private struct GmailBackupSearchResponse: Decodable {
        let query: String
    }

    init() {
        setupWebView()
    }

    // MARK: - Setup
    func setupWebView() {
        guard let jsFileSrc = getCoreJsFile() else { return }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        webView.evaluateJavaScript("const APP_VERSION = 'iOS \(appVersion)';\(jsFileSrc)") { data, error in
            // TODO: handler errros
            print("web view setup")
        }
    }

    private func getCoreJsFile() -> String? {
        guard let jsFile = Bundle(for: Self.self).path(
            forResource: "flowcrypt-ios-prod.js.txt",
            ofType: nil
        ) else { return nil }
        return try? String(contentsOfFile: jsFile)
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
        let params: [String: Any] = [
            "passphrase": passphrase,
            "variant": String(variant.rawValue),
            "userIds": try userIds.map { try $0.toJsonEncodedDict() }
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

    func gmailBackupSearch(for email: String) async throws -> String {
        let response = try await call("gmailBackupSearch", params: ["acctEmail": email])
        let result = try response.json.decodeJson(as: GmailBackupSearchResponse.self)
        return result.query
    }

    // MARK: Private calls
    @discardableResult
    private func call(_ endpoint: String, params: [String: Any?] = [:], data: Data = Data()) async throws -> RawRes {
        let paramsData = try JSONSerialization.data(withJSONObject: params).toStr()
        let uInt8Data = [UInt8](data)

        let response = try await webView.callAsyncJavaScript(
            "return handleRequestFromHost(\"\(endpoint)\", \(paramsData), \(uInt8Data))",
            arguments: [:],
            contentWorld: .page
        )

        guard let response = response as? [String: Any],
              let uintdata = response["data"] as? [String: UInt8]
        else {
            throw CoreError.value("JavaScript callback response not available")
        }

        var responseJson: Data?
        if let resJson = response["json"] as? [String: Any] {
            responseJson = try JSONSerialization.data(withJSONObject: resJson, options: .prettyPrinted)
        }

        let indices = uintdata.keys.compactMap(Int.init).sorted()
        let array = indices.compactMap { uintdata["\($0)"] }
        let responseData = Data(array)

        return RawRes(json: responseJson ?? Data(), data: responseData)
    }
}

class WebMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("GOT MESSAGE")
        print(message.body)
    }
}
