//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import SwiftyRSA
import JavaScriptCore
import Security

@objc protocol CoreHostExports: JSExport {
    func decryptRsaNoPadding(_ rsaPrvDerBase64: String, _ encryptedBase64: String) -> String
    func getSecureRandomByteNumberArray(_ byteCount: Int) -> [UInt8]?
    func log(_ text: String) -> Void
    static func getInstance() -> CoreHost
}

class CoreHost: NSObject, CoreHostExports {

    func log(_ message: String) -> Void {
        print(message.split(separator: "\n").map { "Js: \($0)" }.joined(separator: "\n"))
    }

    // brings total decryption time from 200ms to 30ms (rsa2048)
    func decryptRsaNoPadding(_ rsaPrvDerBase64: String, _ encryptedBase64: String) -> String {
        do {
            let rsaPrv = try PrivateKey(base64Encoded: rsaPrvDerBase64)
            let rsaEncrypted = try EncryptedMessage(base64Encoded: encryptedBase64)
            let decrypted = try rsaEncrypted.decrypted(with: rsaPrv, padding: .NONE)
            return decrypted.base64String
        } catch {
            print("decryptRsaNoPadding error")
            print(error)
            return ""
        }
    }

    func getSecureRandomByteNumberArray(_ byteCount: Int) -> [UInt8]? { // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return bytes;
        }
        return nil; // is checked for in JavaScript
    }

    class func getInstance() -> CoreHost {
        return CoreHost()
    }

}
