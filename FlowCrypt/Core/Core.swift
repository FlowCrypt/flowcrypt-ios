//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import FlowCryptCommon
import JavaScriptCore
import Combine

enum CoreError: Error, Equatable {
    case exception(String)
    case notReady(String)
    case format(String)
    case keyMismatch(String)
    // wrong value passed into a function
    case value(String)
    
    init?(coreError: CoreRes.Error) {
        guard let errorType = coreError.error.type else {
            return nil
        }
        switch errorType {
        case "format": self = .format(coreError.error.message)
        case "key_mismatch": self = .keyMismatch(coreError.error.message)
        default: return nil
        }
    }
}

protocol KeyDecrypter {
    func decryptKey(armoredPrv: String, passphrase: String) throws -> CoreRes.DecryptKey
}

final class Core: KeyDecrypter, CoreComposeMessageType {
    static let shared = Core()

    private var jsEndpointListener: JSValue?
    private var cb_catcher: JSValue?
    private var cb_last_value: [Any]?
    private var vm = JSVirtualMachine()!
    private var context: JSContext?
    private dynamic var started = false
    private dynamic var ready = false
    
    private let queue = DispatchQueue(label: "com.flowcrypt.core", qos: .background)

    private lazy var logger = Logger.nested(in: Self.self, with: "Js")

    private init() {}

    func version() throws -> CoreRes.Version {
        let r = try call("version", jsonDict: nil, data: nil)
        return try r.json.decodeJson(as: CoreRes.Version.self)
    }

    // MARK: Keys
    func parseKeys(armoredOrBinary: Data) throws -> CoreRes.ParseKeys {
        let r = try call("parseKeys", jsonDict: [String: String](), data: armoredOrBinary)
        return try r.json.decodeJson(as: CoreRes.ParseKeys.self)
    }

    func decryptKey(armoredPrv: String, passphrase: String) throws -> CoreRes.DecryptKey {
        let r = try call("decryptKey", jsonDict: ["armored": armoredPrv, "passphrases": [passphrase]], data: nil)
        return try r.json.decodeJson(as: CoreRes.DecryptKey.self)
    }

    func encryptKey(armoredPrv: String, passphrase: String) throws -> CoreRes.EncryptKey {
        let r = try call("encryptKey", jsonDict: ["armored": armoredPrv, "passphrase": passphrase], data: nil)
        return try r.json.decodeJson(as: CoreRes.EncryptKey.self)
    }
    
    func generateKey(passphrase: String, variant: KeyVariant, userIds: [UserId]) throws -> CoreRes.GenerateKey {
        let request: [String: Any] = ["passphrase": passphrase, "variant": String(variant.rawValue), "userIds": try userIds.map { try $0.toJsonEncodedDict() }]
        let r = try call("generateKey", jsonDict: request, data: nil)
        return try r.json.decodeJson(as: CoreRes.GenerateKey.self)
    }
    
    // MARK: Files
    public func decryptFile(encrypted: Data, keys: [PrvKeyInfo], msgPwd: String?) throws -> CoreRes.DecryptFile {
        let json: [String : Any?]? = [
            "keys": try keys.map { try $0.toJsonEncodedDict() },
            "msgPwd": msgPwd
        ]
        let decrypted = try call("decryptFile", jsonDict: json, data: encrypted)
        let meta = try decrypted.json.decodeJson(as: CoreRes.DecryptFileMeta.self)
        
        return CoreRes.DecryptFile(name: meta.name, content: decrypted.data)
    }
    
    public func encryptFile(pubKeys: [String]?, fileData: Data, name: String) throws -> CoreRes.EncryptFile {
        let json: [String: Any?]? = [
            "pubKeys": pubKeys,
            "name": name
        ]
        
        let encrypted = try call(
            "encryptFile",
            jsonDict: json,
            data: fileData
        )
        return CoreRes.EncryptFile(encryptedFile: encrypted.data)
    }

    func parseDecryptMsg(encrypted: Data, keys: [PrvKeyInfo], msgPwd: String?, isEmail: Bool) throws -> CoreRes.ParseDecryptMsg {
        let json: [String : Any?]? = [
            "keys": try keys.map { try $0.toJsonEncodedDict() },
            "isEmail": isEmail,
            "msgPwd": msgPwd
        ]
        let parsed = try call(
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

    func composeEmail(msg: SendableMsg, fmt: MsgFmt, pubKeys: [String]?) -> Future<CoreRes.ComposeEmail, Error> {
        Future<CoreRes.ComposeEmail, Error> { [weak self] promise in
            guard let self = self else { return }
            self.queue.async {
                do {
                    let r = try self.call("composeEmail", jsonDict: [
                        "text": msg.text,
                        "to": msg.to,
                        "cc": msg.cc,
                        "bcc": msg.bcc,
                        "from": msg.from,
                        "subject": msg.subject,
                        "replyToMimeMsg": msg.replyToMimeMsg,
                        "atts": msg.atts.map { att in ["name": att.name, "type": att.type, "base64": att.base64] },
                        "format": fmt.rawValue,
                        "pubKeys": pubKeys,
                    ], data: nil)
                    // this call returned no useful json data, only bytes
                    promise(.success(CoreRes.ComposeEmail(mimeEncoded: r.data)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }

    func zxcvbnStrengthBar(passPhrase: String) throws -> CoreRes.ZxcvbnStrengthBar {
        let r = try call("zxcvbnStrengthBar", jsonDict: ["value": passPhrase, "purpose": "passphrase"], data: nil)
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
                let cb_last_value_filler: @convention(block) ([NSObject]) -> Void = { values in self.cb_last_value = values }
                self.context!.setObject(unsafeBitCast(cb_last_value_filler, to: AnyObject.self), forKeyedSubscript: "engine_host_cb_catcher" as (NSCopying & NSObjectProtocol)?)
                self.ready = true
                self.logger.logInfo("JsContext took \(trace.finish()) to start")
                completion()
            }
        }
    }

    func gmailBackupSearch(for email: String) throws -> String {
        let response = try call("gmailBackupSearch", jsonDict: ["acctEmail": email], data: nil)
        let result = try response.json.decodeJson(as: GmailBackupSearchResponse.self)
        return result.query
    }

    // MARK: Private calls
    private func call(_ endpoint: String, jsonDict: [String: Any?]?, data: Data?) throws -> RawRes {
        try call(endpoint, jsonData: try JSONSerialization.data(withJSONObject: jsonDict ?? [String: String]()), data: data ?? Data())
    }

    private func call(_ endpoint: String, jsonEncodable: Encodable, data: Data) throws -> RawRes {
        try call(endpoint, jsonData: try jsonEncodable.toJsonData(), data: data)
    }

    private func call(_ endpoint: String, jsonData: Data, data: Data) throws -> RawRes {
        try blockUntilReadyOrThrow()
        cb_last_value = nil
        jsEndpointListener!.call(withArguments: [endpoint, String(data: jsonData, encoding: .utf8)!, data.base64EncodedString(), cb_catcher!])
        let b64response = cb_last_value![0] as! String
        let rawResponse = Data(base64Encoded: b64response)!
        let separatorIndex = rawResponse.firstIndex(of: 10)!
        let resJsonData = Data(rawResponse[...(separatorIndex - 1)])
        let error = try? resJsonData.decodeJson(as: CoreRes.Error.self)
        if let error = error {
            let errMsg = "------ js err -------\nCore \(endpoint):\n\(error.error.message)\n\(error.error.stack ?? "no stack")\n------- end js err -----"
            logger.logError(errMsg)
            
            throw CoreError.init(coreError: error) ?? CoreError.exception(errMsg)
        }
        return RawRes(json: resJsonData, data: Data(rawResponse[(separatorIndex + 1)...]))
    }
    
    private func blockUntilReadyOrThrow() throws {
        // This will block the thread for up to 1000ms if the app was just started and Core method was called before JSContext is ready
        // It should only affect the user if Core method was called within 500-800ms of starting the app
        let start = DispatchTime.now()
        while !ready {
            if start.millisecondsSince > 1000 { // already waited for 1000 ms, give up
                throw CoreError.notReady("App Core not ready yet")
            }
            usleep(50000) // 50ms
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
