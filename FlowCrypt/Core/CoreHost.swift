//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import JavaScriptCore // for export to js
import Security // for rng
import SwiftyRSA // for rsa
import IDZSwiftCommonCrypto // for aes
import CommonCrypto // for hashing

@objc protocol CoreHostExports: JSExport {

    // crypto
    func getSecureRandomByteNumberArray(_ byteCount: Int) -> [UInt8]?
    func decryptAesCfbNoPadding(_ ct: [UInt8], _ key: [UInt8], _ iv: [UInt8]) -> [UInt8]
    func decryptRsaNoPadding(_ rsaPrvDerBase64: String, _ encryptedBase64: String) -> String
    func verifyRsaModPow(_ base: String, _ exponent: String, _ modulo: String) -> String
    func produceHashedIteratedS2k(_ algo: String, _ prefix: [UInt8], _ salt: [UInt8], _ passphrase: [UInt8], _ count: Int) -> [UInt8]

    // other
    func log(_ text: String) -> Void
    func setTimeout(_ callback : JSValue,_ ms : Double) -> String
    func clearTimeout(_ identifier: String)

}

var timers = [String: Timer]()

class CoreHost: NSObject, CoreHostExports {

    // todo - things to look at for optimisation:
    //  -> a) reading rsa4096 prv key (just openpgp.key.readArmored(...)) takes 70ms. It should take about 10 ms. Could dearmor it in swift, return bytes
    //  -> b) produceHashedIteratedS2k below takes 300ms for two keys, could be 100ms or so

    func log(_ message: String) -> Void {
        print(message.split(separator: "\n").map { "Js: \($0)" }.joined(separator: "\n"))
    }

    // brings total decryption time from 200->30ms (rsa2048), 3900->420ms (rsa4096)
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

    // aes256 msglen:1300, original 11ms, now 7ms
    // performance untested for larger messages
    func decryptAesCfbNoPadding(_ ct: [UInt8], _ key: [UInt8],  _ iv: [UInt8]) -> [UInt8] {
        return Cryptor(operation: .decrypt, algorithm: .aes, mode: .CFB, padding: .NoPadding, key: key, iv: iv).update(byteArray: ct)!.final()!
    }

    // rsa verify is used by OpenPGP.js during decryption as well to figure out our own key preferences
    // this slows down decryption the first time a private key is used in a session because bn.js is slow
    // Using GMP C library modular exponentiation reduces rsa4096 verify time from 800ms to 40ms
    func verifyRsaModPow(_ base: String, _ exponent: String, _ modulo: String) -> String {
        // only supported on arm64 because was not able to build it for other platforms yet
        // in fact, I'm no longer able to build any working library other than the one I've built before
        // when not supported, the function returns empty string, and JS falls back on bn.js
        return String(cString: c_gmp_mod_pow(base, exponent, modulo))
    }

    // todo - check openpgp s2k spec for supported algos
    func hashDigest(algo: String, data: Data) throws -> [UInt8] {
        if algo == "sha256" {
            return self.sha256digest(data)
        }
        throw Errors.valueError("Unsupported iterated s2k hash algo: \(algo). Please contact us to add support.")
    }

    // this could be further optimised. Takes about 150ms per key
    // there tend to be two keys to decrypt in an armored key, so that makes is 300 ms
    // I suspect it could be optimised to 50ms per pass, or 100ms total
    // but still better than 20 SECONDS per pass in JS
    func produceHashedIteratedS2k(_ algo: String, _ prefix: [UInt8], _ salt: [UInt8], _ passphrase: [UInt8], _ count: Int) -> [UInt8] {
        let dataGroupSize = 750; // performance optimisation
        let data = salt + passphrase
        let dataRepeatCount = Int((Float(count - prefix.count) / Float(max(data.count, 1))).rounded(.up))
        var dataGroup = Data()
        for _ in 0..<dataGroupSize { // takes 11 ms
            dataGroup += data
        }
        var isp = prefix + dataGroup
        for _ in 0...dataRepeatCount / dataGroupSize { // takes 75 ms, just adding data (16mb)
            isp += dataGroup
        }
        let subArr = isp[0..<prefix.count + count]; // free
        let hashable = Data(subArr) // takes 18 ms just recreating data, could be shaved off by passing ArraySlice to hash
        let digested = try! self.hashDigest(algo: algo, data: hashable); // takes 30 ms for sha256 16mb
        return digested
    }

    func sha256digest(_ bytes: Data) -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        bytes.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(bytes.count), &hash)
        }
        return hash
    }

    // JavaScriptCore does not come with a RNG, use one from Swift
    func getSecureRandomByteNumberArray(_ byteCount: Int) -> [UInt8]? { // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return bytes;
        }
        return nil; // is checked for in JavaScript
    }

    func clearTimeout(_ id: String) {
        let timer = timers.removeValue(forKey: id)
        timer?.invalidate()
    }

    func setTimeout(_ cb: JSValue, _ ms: Double) -> String {
        let interval = ms/1000.0
        let uuid = NSUUID().uuidString
        DispatchQueue.main.async { // queue all in the same executable queue, JS calls are getting lost if the queue is not specified
            let timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.callJsCb), userInfo: cb, repeats: false)
            timers[uuid] = timer
        }
        return uuid
    }

    @objc func callJsCb(_ timer: Timer) {
        let callback = (timer.userInfo as! JSValue)
        callback.call(withArguments: nil)
        // todo - remove from timers by uuid, could cause possible memory leak
    }

}
