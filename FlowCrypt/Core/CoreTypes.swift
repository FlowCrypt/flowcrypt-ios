//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import RealmSwift

struct CoreRes {

    struct Version: Decodable {
        let app_version: String
    }

    struct ComposeEmail {
        let mimeEncoded: Data
    }

    struct ParseDecryptMsgWithoutBlocks: Decodable {
        let replyType: ReplyType
        let text: String
    }

    struct ParseDecryptMsg {
        let replyType: ReplyType
        let text: String
        let blocks: [MsgBlock]
    }

    struct ParseKeys: Decodable {
        internal enum Format: String, Decodable {
            case binary;
            case armored; case unknown;
        }
        let format: Format
        let keyDetails: [KeyDetails]
    }

    struct DecryptKey: Decodable {
        let decryptedKey: String?
    }

    struct GenerateKey: Decodable {
        let key: KeyDetails
    }

    struct Error: Decodable {
        internal struct ErrorWithOptionalStack: Decodable {
            let message: String
            let stack: String?
        }
        let error: ErrorWithOptionalStack
    }

    internal enum ReplyType: String, Decodable {
        case encrypted;
        case plain;
    }

}


enum MsgFmt: String {
    case plain = "plain"
    case encryptInline = "encrypt-inline" // todo - rename these in TypeScript to be camelCase
    case encryptPgpmime = "encrypt-pgpmime"
}

enum KeyVariant: String {
    case rsa2048
    case rsa4096
    case curve25519
}

struct UserId: Encodable {
    let email: String;
    let name: String;
}

struct PrvKeyInfo: Encodable {
    let `private`: String
    let longid: String
    let passphrase: String?

    static func from(keyInfo ki: KeyInfo) -> PrvKeyInfo {
        return PrvKeyInfo(private: ki.private, longid: ki.longid, passphrase: ki.passphrase)
    }

    static func from(realm keyInfoResults: Results<KeyInfo>) -> [PrvKeyInfo] {
        return Array(keyInfoResults).map { PrvKeyInfo.from(keyInfo: $0) }
    }
}

struct SendableMsg {
    let text: String
    let to: [String]
    let cc: [String]
    let bcc: [String]
    let from: String
    let subject: String
    let replyToMimeMsg: String?
}

struct MsgBlock: Decodable {
    let type: BlockType
    let content: String
    let decryptErr: DecryptErr? // always present in decryptErr BlockType
    let keyDetails: KeyDetails? // always present in publicKey BlockType
    // let verifyRes: VerifyRes?,
    // let attMeta: AttMeta?; // always present in plainAtt, encryptedAtt, decryptedAtt, encryptedAttLink

    // let signature: String? // possibly not neded in Swift

    internal struct DecryptErr: Decodable {
        let error: Error
        let longids: Longids
        let content: String?
        let isEncrypted: Bool?

        internal struct Error: Decodable {
            let type: ErrorType
            let message: String
        }

        internal struct Longids: Decodable {
            let message: [String]
            let matching: [String]
            let chosen: [String]
            let needPassphrase: [String]
        }

        internal enum ErrorType: String, Decodable {
            case keyMismatch = "key_mismatch"
            case usePassword = "use_password"
            case wrongPwd = "wrong_password"
            case noMdc = "no_mdc"
            case badMdc = "bad_mdc"
            case needPassphrase = "need_passphrase"
            case format = "format"
            case other = "other"
        }
    }

    internal enum BlockType: String, Decodable {
        case plainHtml; // all content blocks, regardless if encrypted or not, formatted as a plainHtml (todo - rename this one day to formattedHtml)
        case publicKey;
        case privateKey;
        case encryptedMsgLink;
        case plainAtt;
        case encryptedAtt;
        case decryptedAtt;
        case encryptedAttLink;
        case decryptErr;
        case blockParseErr; // block type for situations where block json could not be parsed out
        // case cryptupVerification; // not sure if Swift code will ever encounter this
    }
}

internal struct KeyId: Decodable {
    let shortid: String;
    let longid: String;
    let fingerprint: String;
    let keywords: String;
}

struct KeyDetails: Decodable {
    let `public`: String
    let `private`: String?
    let isDecrypted: Bool?
    let ids: [KeyId]
    // todo
    //    let users: [String]
    //    let created: Int64
    //    let algo: { // same as OpenPGP.key.AlgorithmInfo
    //        algorithm: string;
    //        algorithmId: number;
    //        bits?: number;
    //        curve?: string;
    //    };
}
