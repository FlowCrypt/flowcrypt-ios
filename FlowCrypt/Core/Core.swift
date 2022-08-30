//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import JavaScriptCore

enum CoreError: LocalizedError, Equatable {
    case exception(String) // core threw exception
    case notReady(String) // core not initialized
    case value(String) // wrong value passed into or returned by a function
    var errorDescription: String? {
        switch self {
        case .exception(let message),
                .notReady(let message),
                .value(let message):
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

actor Core: KeyDecrypter, KeyParser, CoreComposeMessageType {
    static let shared = Core()

    private typealias CallbackResult = (String, [UInt8])

    private var jsEndpointListener: JSValue?
    private var cb_catcher: JSValue?
    private var vm = JSVirtualMachine()!
    private var context: JSContext?

    private var callbackResults: [String: CallbackResult] = [:]
    private var ready = false

    private lazy var logger = Logger.nested(in: Self.self, with: "Js")

    private init() {}

    func version() async throws -> CoreRes.Version {
        let r = try await call("version", jsonDict: nil, data: nil)
        return try r.json.decodeJson(as: CoreRes.Version.self)
    }

    // MARK: Keys
    func parseKeys(armoredOrBinary: Data) async throws -> CoreRes.ParseKeys {
        let r = try await call("parseKeys", jsonDict: [String: String](), data: armoredOrBinary)
        return try r.json.decodeJson(as: CoreRes.ParseKeys.self)
    }

    func decryptKey(armoredPrv: String, passphrase: String) async throws -> CoreRes.DecryptKey {
        let r = try await call("decryptKey", jsonDict: ["armored": armoredPrv, "passphrases": [passphrase]], data: nil)
        return try r.json.decodeJson(as: CoreRes.DecryptKey.self)
    }

    func encryptKey(armoredPrv: String, passphrase: String) async throws -> CoreRes.EncryptKey {
        let r = try await call("encryptKey", jsonDict: ["armored": armoredPrv, "passphrase": passphrase], data: nil)
        return try r.json.decodeJson(as: CoreRes.EncryptKey.self)
    }

    func generateKey(passphrase: String, variant: KeyVariant, userIds: [UserId]) async throws -> CoreRes.GenerateKey {
        let request: [String: Any] = [
            "passphrase": passphrase,
            "variant": String(variant.rawValue),
            "userIds": try userIds.map { try $0.toJsonEncodedDict() }
        ]
        let r = try await call("generateKey", jsonDict: request, data: nil)
        return try r.json.decodeJson(as: CoreRes.GenerateKey.self)
    }

    func verifyKey(armoredPrv: String) async throws -> Data {
        let jsonDict: [String: Any?] = [
            "armored": armoredPrv
        ]

        return try await call(
            "verifyKey",
            jsonDict: jsonDict,
            data: nil
        ).data
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

        let decrypted = try await call("decryptFile", jsonDict: [
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
        let json: [String: Any?]? = [
            "pubKeys": pubKeys,
            "name": name
        ]
        
        let encrypted = try await call(
            "encryptFile",
            jsonDict: json,
            data: file
        )
        return encrypted.data
    }

    // MARK: - Messages
    func encrypt(data: Data, pubKeys: [String]?, password: String?) async throws -> Data {
        let jsonDict: [String: Any?] = [
            "pubKeys": pubKeys,
            "msgPwd": password
        ]

        let encryptedMessage = try await call(
            "encryptMsg",
            jsonDict: jsonDict,
            data: data
        )

        return encryptedMessage.data
    }

    func parseDecryptMsg(
        encrypted: Data,
        keys: [Keypair],
        msgPwd: String?,
        isMime: Bool,
        verificationPubKeys: [String],
        signature: String? = nil
    ) async throws -> CoreRes.ParseDecryptMsg {
        struct ParseDecryptMsgRaw: Decodable {
            let replyType: ReplyType
            let text: String
        }
        let json: [String: Any?]? = [
            "keys": keys.map(\.prvKeyInfoJsonDictForCore),
            "isMime": isMime,
            "msgPwd": msgPwd,
            "verificationPubkeys": verificationPubKeys,
            "signature": signature
        ]

        let parsed = try await call(
            "parseDecryptMsg",
            jsonDict: json,
            data: encrypted
        )

        let meta = try parsed.json.decodeJson(as: ParseDecryptMsgRaw.self)

        let blocks = parsed.data
            .split(separator: 10) // newline separated block jsons, one json per line
            .map { data -> MsgBlock in
                guard let block = try? data.decodeJson(as: MsgBlock.self) else {
                    let content = String(data: data, encoding: .utf8) ?? "(utf err)"
                    return MsgBlock.blockParseErr(with: content)
                }
                return block
            }

        return CoreRes.ParseDecryptMsg(
            replyType: meta.replyType,
            text: meta.text,
            blocks: blocks
        )
    }

    func composeEmail(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail {
        let r = try await call("composeEmail", jsonDict: [
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
            "pubKeys": msg.pubKeys,
            "signingPrv": msg.signingPrv.ifNotNil(\.prvKeyInfoJsonDictForCore)
        ], data: nil)
        return CoreRes.ComposeEmail(mimeEncoded: r.data)
    }

    func zxcvbnStrengthBar(passPhrase: String) async throws -> CoreRes.ZxcvbnStrengthBar {
        let r = try await call("zxcvbnStrengthBar", jsonDict: ["value": passPhrase, "purpose": "passphrase"], data: nil)
        return try r.json.decodeJson(as: CoreRes.ZxcvbnStrengthBar.self)
    }

    func startIfNotAlreadyRunning() async {
        guard !ready else { return }

        let trace = Trace(id: "Start in background")
        let jsFile = Bundle(for: Self.self).path(forResource: "flowcrypt-ios-prod.js.txt", ofType: nil)!
        let jsFileSrc = try? String(contentsOfFile: jsFile)
        context = JSContext(virtualMachine: vm)!
        context?.setObject(CoreHost(), forKeyedSubscript: "coreHost" as (NSCopying & NSObjectProtocol))
        context!.exceptionHandler = { _, exception in
            guard let exception = exception else { return }

            let line = exception.objectForKeyedSubscript("line").toString()
            let column = exception.objectForKeyedSubscript("column").toString()
            let location = [line, column].compactMap { $0 }.joined(separator: ":")

            let logger = Logger.nested(in: Self.self, with: "Js")
            logger.logWarning("\(exception), \(location)")
        }
        context!.evaluateScript("const APP_VERSION = 'iOS 0.2';")
        context!.evaluateScript(jsFileSrc)
        jsEndpointListener = context!.objectForKeyedSubscript("handleRequestFromHost")
        cb_catcher = context!.objectForKeyedSubscript("engine_host_cb_value_formatter")
        ready = true
        logger.logInfo("JsContext took \(trace.finish()) to start")
    }

    func gmailBackupSearch(for email: String) async throws -> String {
        let response = try await call("gmailBackupSearch", jsonDict: ["acctEmail": email], data: nil)
        let result = try response.json.decodeJson(as: GmailBackupSearchResponse.self)
        return result.query
    }

    func handleCallbackResult(callbackId: String, json: String, data: [UInt8]) {
        callbackResults[callbackId] = (json, data)
    }

    // MARK: Private calls
    private func call(_ endpoint: String, jsonDict: [String: Any?]?, data: Data?) async throws -> RawRes {
        return try await call(endpoint, jsonData: try JSONSerialization.data(withJSONObject: jsonDict ?? [String: String]()), data: data ?? Data())
    }

    private func call(_ endpoint: String, jsonEncodable: Encodable, data: Data) async throws -> RawRes {
        return try await call(endpoint, jsonData: try jsonEncodable.toJsonData(), data: data)
    }

    private func call(_ endpoint: String, jsonData: Data, data: Data) async throws -> RawRes {
        guard ready else {
            throw CoreError.exception("Core is not ready yet. Most likeyly startIfNotAlreadyRunning wasn't called first")
        }
        let callbackId = NSUUID().uuidString
        jsEndpointListener!.call(withArguments: [
            endpoint,
            callbackId,
            String(data: jsonData, encoding: .utf8)!,
            Array<UInt8>(data), cb_catcher!
        ])

        while callbackResults[callbackId] == nil {
            try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        }

        guard
            let result = callbackResults.removeValue(forKey: callbackId),
            let resJsonData = result.0.data(using: .utf8)
        else {
            throw CoreError.value("JavaScript callback response not available")
        }
        let error = try? resJsonData.decodeJson(as: CoreRes.Error.self)
        if let error = error {
            logger.logError("""
            ------ js err -------
            Core \(endpoint): \(error.error.message)
            \(error.error.stack ?? "no stack")
            ------- end js err -----
            """)
            throw CoreError.exception(error.error.message + "\n" + (error.error.stack ?? "no stack"))
        }
        return RawRes(json: resJsonData, data: Data(result.1))
    }
}

private struct RawRes {
    let json: Data
    let data: Data
}

private struct GmailBackupSearchResponse: Decodable {
    let query: String
}
