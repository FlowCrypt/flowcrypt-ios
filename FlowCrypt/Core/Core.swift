//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import JavaScriptCore

enum CoreError: Error {
    case exception(String)
    case notReady(String)
}

final class Core {
    // TODO: - Warning. Refactor not to use static func
    private static var jsEndpointListener: JSValue?
    private static var cb_catcher: JSValue?
    private static var cb_last_value: [Any]?
    private static var vm = JSVirtualMachine()!
    private static var context: JSContext?
    private dynamic static var started = false
    private dynamic static var ready = false

    public static func version() throws -> CoreRes.Version {
        let r = try call("version", jsonDict: nil, data: nil)
        return try r.json.decodeJson(as: CoreRes.Version.self)
    }

    public static func parseKeys(armoredOrBinary: Data) throws -> CoreRes.ParseKeys {
        let r = try call("parseKeys", jsonDict: [String: String](), data: armoredOrBinary)
        return try r.json.decodeJson(as: CoreRes.ParseKeys.self)
    }

    public static func decryptKey(armoredPrv: String, passphrase: String) throws -> CoreRes.DecryptKey {
        let r = try call("decryptKey", jsonDict: ["armored": armoredPrv, "passphrases": [passphrase]], data: nil)
        return try r.json.decodeJson(as: CoreRes.DecryptKey.self)
    }

    public static func parseDecryptMsg(encrypted: Data, keys: [PrvKeyInfo], msgPwd: String?, isEmail: Bool) throws -> CoreRes.ParseDecryptMsg {
        let parsed = try call("parseDecryptMsg", jsonDict: ["keys": try keys.map { try $0.toDict() }, "isEmail": isEmail, "msgPwd": msgPwd], data: encrypted)
        let meta = try parsed.json.decodeJson(as: CoreRes.ParseDecryptMsgWithoutBlocks.self)
        let blockLines = parsed.data.split(separator: 10) // newline separated block jsons, one json per line
        var blocks: [MsgBlock] = []
        for blockLine in blockLines {
            var block = try? blockLine.decodeJson(as: MsgBlock.self)
            if block == nil {
                let parseErr = "Err parsing block:\n\n\(String(data: blockLine, encoding: .utf8) ?? "(utf err)")"
                block = MsgBlock(type: MsgBlock.BlockType.blockParseErr, content: parseErr, decryptErr: nil, keyDetails: nil)
            }
            blocks.append(block!)
        }
        return CoreRes.ParseDecryptMsg(replyType: meta.replyType, text: meta.text, blocks: blocks)
    }

    public static func composeEmail(msg: SendableMsg, fmt: MsgFmt, pubKeys: [String]?) throws -> CoreRes.ComposeEmail {
        let r = try call("composeEmail", jsonDict: [
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
        return CoreRes.ComposeEmail(mimeEncoded: r.data)
    }

    public static func generateKey(passphrase: String, variant: KeyVariant, userIds: [UserId]) throws -> CoreRes.GenerateKey {
        let request: [String: Any] = ["passphrase": passphrase, "variant": String(variant.rawValue), "userIds": try userIds.map { try $0.toDict() }]
        let r = try call("generateKey", jsonDict: request, data: nil)
        return try r.json.decodeJson(as: CoreRes.GenerateKey.self)
    }

    public static func zxcvbnStrengthBar(passPhrase: String) throws -> CoreRes.ZxcvbnStrengthBar {
        let r = try call("zxcvbnStrengthBar", jsonDict: ["value": passPhrase, "purpose": "passphrase"], data: nil)
        return try r.json.decodeJson(as: CoreRes.ZxcvbnStrengthBar.self)
    }

//    public func parseDateStr() throws -> CoreVersionRes {
//    }
//    public func encryptKey() throws -> CoreVersionRes {
//    }
//    public func encryptFile() throws -> CoreVersionRes {
//    }
//    public func decryptFile() throws -> CoreVersionRes {
//    }
//    public func isEmailValid() throws -> CoreVersionRes {
//    }

    public static func startInBackgroundIfNotAlreadyRunning() {
        if !started {
            started = true
            DispatchQueue.global(qos: .default).async {
                let start = DispatchTime.now()
                let jsFile = Bundle(for: Core.self).path(forResource: "flowcrypt-ios-prod.js.txt", ofType: nil)!
                let jsFileSrc = try? String(contentsOfFile: jsFile)
                context = JSContext(virtualMachine: vm)!
                context?.setObject(CoreHost(), forKeyedSubscript: "coreHost" as (NSCopying & NSObjectProtocol))
                context!.exceptionHandler = { _, exception in print("Js.exception: \(String(describing: exception))") }
                context!.evaluateScript("const APP_VERSION = 'iOS 0.2';")
                context!.evaluateScript(jsFileSrc)
                jsEndpointListener = context!.objectForKeyedSubscript("handleRequestFromHost")
                cb_catcher = context!.objectForKeyedSubscript("engine_host_cb_value_formatter")
                let cb_last_value_filler: @convention(block) ([NSObject]) -> Void = { values in self.cb_last_value = values }
                context!.setObject(unsafeBitCast(cb_last_value_filler, to: AnyObject.self), forKeyedSubscript: "engine_host_cb_catcher" as (NSCopying & NSObjectProtocol)?)
                ready = true
                print("JsContext took \(start.millisecondsSince)ms to start")
            }
        }
    }

    public static func blockUntilReadyOrThrow() throws {
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

    // private

    private static func call(_ endpoint: String, jsonDict: [String: Any?]?, data: Data?) throws -> RawRes {
        return try call(endpoint, jsonData: try JSONSerialization.data(withJSONObject: jsonDict ?? [String: String]()), data: data ?? Data())
    }

    private static func call(_ endpoint: String, jsonEncodable: Encodable, data: Data) throws -> RawRes {
        return try call(endpoint, jsonData: try jsonEncodable.toJsonData(), data: data)
    }

    private static func call(_ endpoint: String, jsonData: Data, data: Data) throws -> RawRes {
        try blockUntilReadyOrThrow()
        cb_last_value = nil
        jsEndpointListener!.call(withArguments: [endpoint, String(data: jsonData, encoding: .utf8)!, data.base64EncodedString(), cb_catcher!])
        let b64response = cb_last_value![0] as! String
        let rawResponse = Data(base64Encoded: b64response)!
        let separatorIndex = rawResponse.firstIndex(of: 10)!
        let resJsonData = Data(rawResponse[...(separatorIndex - 1)])
        let error = try? resJsonData.decodeJson(as: CoreRes.Error.self)
        if error != nil {
            let errMsg = "------ js err -------\nCore \(endpoint):\n\(error!.error.message)\n\(error!.error.stack ?? "no stack")\n------- end js err -----"
            print(errMsg)
            throw CoreError.exception(errMsg)
        }
        return RawRes(json: resJsonData, data: Data(rawResponse[(separatorIndex + 1)...]))
    }

    private struct RawRes {
        let json: Data
        let data: Data
    }
}
