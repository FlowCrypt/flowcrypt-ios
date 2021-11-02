//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import JavaScriptCore

enum CoreError: LocalizedError, Equatable {
    case exception(String)
    case notReady(String)
    case format(String)
    case keyMismatch(String)
    case noMDC(String)
    case badMDC(String)
    case needPassphrase(String)
    case wrongPassphrase(String)
    // wrong value passed into a function
    case value(String)
    
    init(coreError: CoreRes.Error) {
        switch coreError.error.type {
        case "format": self = .format(coreError.error.message)
        case "key_mismatch": self = .keyMismatch(coreError.error.message)
        case "no_mdc": self = .noMDC(coreError.error.message)
        case "bad_mdc": self = .badMDC(coreError.error.message)
        case "need_passphrase": self = .needPassphrase(coreError.error.message)
        case "wrong_passphrase": self = .wrongPassphrase(coreError.error.message)
        default: self = .exception(coreError.error.message + "\n" + (coreError.error.stack ?? "no stack"))
        }
    }

    var errorDescription: String? {
        switch self {
        case .exception(let message),
                .notReady(let message),
                .format(let message),
                .keyMismatch(let message),
                .noMDC(let message),
                .badMDC(let message),
                .needPassphrase(let message),
                .wrongPassphrase(let message),
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

final class Core: KeyDecrypter, KeyParser, CoreComposeMessageType {
    static let shared = Core()

    private var jsEndpointListener: JSValue?
    private var cb_catcher: JSValue?
    private var cb_last_value: (String, [UInt8])?
    private var vm = JSVirtualMachine()!
    private var context: JSContext?
    private dynamic var started = false
    private dynamic var ready = false
    
    private let queue = DispatchQueue(label: "com.flowcrypt.core", qos: .default) // todo - try also with .userInitiated

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
    
    // MARK: Files
    public func decryptFile(encrypted: Data, keys: [PrvKeyInfo], msgPwd: String?) async throws -> CoreRes.DecryptFile {
        let json: [String : Any?]? = [
            "keys": try keys.map { try $0.toJsonEncodedDict() },
            "msgPwd": msgPwd
        ]
        let decrypted = try await call("decryptFile", jsonDict: json, data: encrypted)
        let meta = try decrypted.json.decodeJson(as: CoreRes.DecryptFileMeta.self)

        return CoreRes.DecryptFile(name: meta.name, content: decrypted.data)
    }
    
    public func encryptFile(pubKeys: [String]?, fileData: Data, name: String)  async throws -> CoreRes.EncryptFile {
        let json: [String: Any?]? = [
            "pubKeys": pubKeys,
            "name": name
        ]
        
        let encrypted = try await call(
            "encryptFile",
            jsonDict: json,
            data: fileData
        )
        return CoreRes.EncryptFile(encryptedFile: encrypted.data)
    }

    func parseDecryptMsg(encrypted: Data, keys: [PrvKeyInfo], msgPwd: String?, isEmail: Bool) async throws -> CoreRes.ParseDecryptMsg {
        let json: [String : Any?]? = [
            "keys": try keys.map { try $0.toJsonEncodedDict() },
            "isEmail": isEmail,
            "msgPwd": msgPwd
        ]
        let parsed = try await call(
            "parseDecryptMsg",
            jsonDict: json,
            data: encrypted
        )
        let meta = try parsed.json
            .decodeJson(as: CoreRes.ParseDecryptMsgWithoutBlocks.self)

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
        let signingPrv = msg.signingPrv.map { value in
            [
                "private": value.`private`,
                "longid": value.longid,
                "passphrase": value.passphrase
            ]
        }

        let r = try await call("composeEmail", jsonDict: [
            "text": msg.text,
            "to": msg.to,
            "cc": msg.cc,
            "bcc": msg.bcc,
            "from": msg.from,
            "subject": msg.subject,
            "replyToMimeMsg": msg.replyToMimeMsg,
            "atts": msg.atts.map { att in ["name": att.name, "type": att.type, "base64": att.base64] },
            "format": fmt.rawValue,
            "pubKeys": msg.pubKeys,
            "signingPrv": signingPrv
        ], data: nil)
        return CoreRes.ComposeEmail(mimeEncoded: r.data)
    }

    func zxcvbnStrengthBar(passPhrase: String) async throws -> CoreRes.ZxcvbnStrengthBar {
        let r = try await call("zxcvbnStrengthBar", jsonDict: ["value": passPhrase, "purpose": "passphrase"], data: nil)
        return try r.json.decodeJson(as: CoreRes.ZxcvbnStrengthBar.self)
    }

    func startInBackgroundIfNotAlreadyRunning(_ completion: @escaping (() -> Void)) {
        if self.ready {
            completion()
        }
        if !started {
            started = true
            DispatchQueue.global(qos: .default).async { [weak self] in
                guard let self = self else { return }
                let trace = Trace(id: "Start in background")
                let jsFile = Bundle(for: Core.self).path(forResource: "flowcrypt-ios-prod.js.txt", ofType: nil)!
                let jsFileSrc = try? String(contentsOfFile: jsFile)
                self.context = JSContext(virtualMachine: self.vm)!
                self.context?.setObject(CoreHost(), forKeyedSubscript: "coreHost" as (NSCopying & NSObjectProtocol))
                self.context!.exceptionHandler = { [weak self] _, exception in
                    guard let exception = exception else { return }
                    self?.logger.logWarning("\(exception)")
                }
                self.context!.evaluateScript("const APP_VERSION = 'iOS 0.2';")
                self.context!.evaluateScript(jsFileSrc)
                self.jsEndpointListener = self.context!.objectForKeyedSubscript("handleRequestFromHost")
                self.cb_catcher = self.context!.objectForKeyedSubscript("engine_host_cb_value_formatter")
                self.ready = true
                self.logger.logInfo("JsContext took \(trace.finish()) to start")
                completion()
            }
        }
    }

    func gmailBackupSearch(for email: String) async throws -> String {
        let response = try await call("gmailBackupSearch", jsonDict: ["acctEmail": email], data: nil)
        let result = try response.json.decodeJson(as: GmailBackupSearchResponse.self)
        return result.query
    }

    func handleCallbackResult(json: String, data: [UInt8]) {
        cb_last_value = (json, data)
    }

    // MARK: Private calls
    private func call(_ endpoint: String, jsonDict: [String: Any?]?, data: Data?) async throws -> RawRes {
        return try await call(endpoint, jsonData: try JSONSerialization.data(withJSONObject: jsonDict ?? [String: String]()), data: data ?? Data())
    }

    private func call(_ endpoint: String, jsonEncodable: Encodable, data: Data) async throws -> RawRes {
        return try await call(endpoint, jsonData: try jsonEncodable.toJsonData(), data: data)
    }

    private func call(_ endpoint: String, jsonData: Data, data: Data) async throws -> RawRes {
        try await sleepUntilReadyOrThrow()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<RawRes, Error>) in
            // tom - todo - currently there is only one callback storage variable "cb_last_value"
            //   for all JavaScript calls, and so we have to synchronize
            //   all calls into JavaScript to happen serially, else
            //   the return values would be undefined when used concurrently
            //   see https://github.com/FlowCrypt/flowcrypt-ios/issues/852
            // A possible solution would be to only synchronize returning o fthe callbac values into some dict. But I'm unsure if JavaScript is otherwise safe to call concurrently, so for now we'll do the safer thing.
            queue.async {
                self.cb_last_value = nil
                self.jsEndpointListener!.call(withArguments: [endpoint, String(data: jsonData, encoding: .utf8)!, Array<UInt8>(data), self.cb_catcher!])
                guard
                    let resJsonData = self.cb_last_value?.0.data(using: .utf8),
                    let rawResponse = self.cb_last_value?.1
                else {
                    self.logger.logError("could not see callback response, got cb_last_value: \(String(describing: self.cb_last_value))")
                    continuation.resume(throwing: CoreError.format("JavaScript callback response not available"))
                    return
                }
                let error = try? resJsonData.decodeJson(as: CoreRes.Error.self)
                if let error = error {
                    let errMsg = "------ js err -------\nCore \(endpoint):\n\(error.error.message)\n\(error.error.stack ?? "no stack")\n------- end js err -----"
                    self.logger.logError(errMsg)
                    continuation.resume(throwing: CoreError(coreError: error))
                    return
                }
                continuation.resume(returning: RawRes(json: resJsonData, data: Data(rawResponse)))
            }
        }
    }
    
    private func sleepUntilReadyOrThrow() async throws {
        // This will block the task for up to 1000ms if the app was just started and Core method was called before JSContext is ready
        // It should only affect the user if Core method was called within 500-800ms of starting the app
        let start = DispatchTime.now()
        while !ready {
            if start.millisecondsSince > 1000 { // already waited for 1000 ms, give up
                throw CoreError.notReady("App Core not ready yet")
            }
            await Task.sleep(50 * 1_000_000) // 50ms
        }
    }

    private struct RawRes {
        let json: Data
        let data: Data
    }
}

private struct GmailBackupSearchResponse: Decodable {
    let query: String
}
