//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import CommonCrypto // for hashing
import FlowCryptCommon
import IDZSwiftCommonCrypto // for aes
import JavaScriptCore // for export to js
import Security // for rng
import SwiftyRSA // for rsa

@objc protocol CoreHostExports: JSExport {
    // crypto
    func getSecureRandomByteNumberArray(_ byteCount: Int) -> [UInt8]?
    func decryptAesCfbNoPadding(_ ct: [UInt8], _ key: [UInt8], _ iv: [UInt8]) -> [UInt8]
    func decryptRsaNoPadding(_ rsaPrvDerBase64: String, _ encryptedBase64: String) -> String
    func modPow(_ base: String, _ exponent: String, _ modulo: String) -> String
    func produceHashedIteratedS2k(_ algo: String, _ prefix: [UInt8], _ salt: [UInt8], _ passphrase: [UInt8], _ count: Int) -> [UInt8]

    func setTimeout(_ callback: JSValue, _ ms: Double) -> String
    func clearTimeout(_ identifier: String)

    func handleCallback(_ endpointKey: String, _ string: String, _ data: [UInt8])
    func log(_ message: String)
}

var timers = [String: Timer]()

final class CoreHost: NSObject, CoreHostExports {
    // todo - things to look at for optimisation:
    //  -> a) reading rsa4096 prv key (just openpgp.key.readArmored(...)) takes 70ms. It should take about 10 ms. Could dearmor it in swift, return bytes
    //  -> b) produceHashedIteratedS2k below takes 300ms for two keys, could be 100ms or so

    // brings total decryption time from 200->30ms (rsa2048), 3900->420ms (rsa4096)
    func decryptRsaNoPadding(_ rsaPrvDerBase64: String, _ encryptedBase64: String) -> String {
        do {
            let rsaPrv = try PrivateKey(base64Encoded: rsaPrvDerBase64)
            let rsaEncrypted = try EncryptedMessage(base64Encoded: encryptedBase64)
            let decrypted = try rsaEncrypted.decrypted(with: rsaPrv, padding: .NONE)
            return decrypted.base64String
        } catch {
            Logger.logError("decryptRsaNoPadding error \(error)")
            return ""
        }
    }

    // aes256 msglen:1300, original 11ms, now 7ms
    // performance untested for larger messages
    func decryptAesCfbNoPadding(_ ct: [UInt8], _ key: [UInt8], _ iv: [UInt8]) -> [UInt8] {
        Cryptor(operation: .decrypt, algorithm: .aes, mode: .CFB, padding: .NoPadding, key: key, iv: iv).update(byteArray: ct)!.final()!
    }
    
    // RSA relies on this method, which is slow in OpenPGP.js that uses BN.js
    // primarily added here because of slow decryption, slow signing, slow sig verification
    // particularly noticeable on RSA4096 (signing could originally be 30-90 seconds)
    func modPow(_ base: String, _ exponent: String, _ modulo: String) -> String {
        // If there is an error parsing provided numbers, the function returns empty string, and JS falls back on bn.js
        return String(cString: c_gmp_mod_pow(base, exponent, modulo))
    }

    func hashDigest(name: String, data: Data) throws -> [UInt8] {
        let algo = try getHashAlgo(name: name)
        var hash = [UInt8](repeating: 0, count: Int(algo.length))
        data.withUnsafeBytes {
            _ = algo.digest($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash
    }

    // this could be further optimised. Takes about 150ms per key
    // there tend to be two keys to decrypt in an armored key, so that makes it 300 ms
    // I suspect it could be optimised to 50ms per pass, or 100ms total
    // but still better than 20 SECONDS per pass in JS
    func produceHashedIteratedS2k(_ algo: String, _ prefix: [UInt8], _ salt: [UInt8], _ passphrase: [UInt8], _ count: Int) -> [UInt8] {
        let dataGroupSize = 750 // performance optimisation
        let data = salt + passphrase
        let dataRepeatCount = Int((Float(count - prefix.count) / Float(max(data.count, 1))).rounded(.up))
        var dataGroup = Data()
        for _ in 0 ..< dataGroupSize { // takes 11 ms
            dataGroup += data
        }
        var isp = prefix + dataGroup
        for _ in 0 ... dataRepeatCount / dataGroupSize { // takes 75 ms, just adding data (16mb)
            isp += dataGroup
        }
        let subArr = isp[0 ..< prefix.count + count] // free
        let hashable = Data(subArr) // takes 18 ms just recreating data, could be shaved off by passing ArraySlice to hash
        return try! hashDigest(name: algo, data: hashable) // takes 30 ms for sha256 16mb
    }

    // JavaScriptCore does not come with a RNG, use one from Swift
    func getSecureRandomByteNumberArray(_ byteCount: Int) -> [UInt8]? { // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return bytes
        }
        return nil // is checked for in JavaScript
    }

    func clearTimeout(_ id: String) {
        DispatchQueue.main.async { // use consistent queue for modifications
            let timer = timers.removeValue(forKey: id)
            timer?.invalidate()
        }
    }

    func setTimeout(_ cb: JSValue, _ ms: Double) -> String {
        let interval = ms / 1000.0
        let uuid = NSUUID().uuidString
        DispatchQueue.main.async { // queue all in the same executable queue, JS calls are getting lost if the queue is not specified
            let timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.callJsCb), userInfo: cb, repeats: false)
            timers[uuid] = timer // use consistent queue for modifications of timers
        }
        return uuid
    }

    func handleCallback(_ callbackId: String, _ string: String, _ data: [UInt8]) {
        Task {
            await Core.shared.handleCallbackResult(callbackId: callbackId, json: string, data: data)
        }
    }

    func log(_ message: String) {
        Logger.logDebug(message)
    }

    @objc func callJsCb(_ timer: Timer) {
        let callback = (timer.userInfo as! JSValue)
        callback.call(withArguments: nil)
        // todo - remove from timers by uuid, could cause possible memory leak
    }

    func getHashAlgo(name: String) throws -> HashAlgo {
        switch name {
        case "md5": return HashAlgo(digest: CC_MD5, length: CC_MD5_DIGEST_LENGTH)
        case "sha1": return HashAlgo(digest: CC_SHA1, length: CC_SHA1_DIGEST_LENGTH)
        case "sha224": return HashAlgo(digest: CC_SHA224, length: CC_SHA224_DIGEST_LENGTH)
        case "sha384": return HashAlgo(digest: CC_SHA384, length: CC_SHA384_DIGEST_LENGTH)
        case "sha256": return HashAlgo(digest: CC_SHA256, length: CC_SHA256_DIGEST_LENGTH)
        case "sha512": return HashAlgo(digest: CC_SHA512, length: CC_SHA512_DIGEST_LENGTH)
        default: throw CoreError.value("Unsupported iterated s2k hash algo: \(name). Please contact us to add support.") // ripemd
        }
    }

    struct HashAlgo {
        let digest: (_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>?
        let length: Int32
    }
}

extension SecPadding {
    // https://developer.apple.com/documentation/security/secpadding/ksecpaddingnone
    public static let NONE = SecPadding(rawValue: 0)
}
