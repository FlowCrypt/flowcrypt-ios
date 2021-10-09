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
        enum Format: String, Decodable {
            case binary
            case armored
            case unknown
        }

        let format: Format
        let keyDetails: [KeyDetails]
    }

    struct DecryptKey: Decodable {
        let decryptedKey: String
    }

    struct EncryptKey: Decodable {
        let encryptedKey: String
    }

    struct GenerateKey: Decodable {
        let key: KeyDetails
    }
    
    struct DecryptFile: Decodable {
        let name: String
        let content: Data
    }
    
    struct EncryptFile: Decodable {
        let encryptedFile: Data
    }
    
    struct DecryptFileMeta: Decodable {
        let name: String
    }

    struct Error: Decodable {
        struct ErrorWithOptionalStack: Decodable {
            let message: String
            let type: String?
            let stack: String?
        }

        let error: ErrorWithOptionalStack
    }

    struct ZxcvbnStrengthBar: Decodable {
        struct WordDetails: Decodable {
            enum Word: String, Decodable {
                case perfect
                case great
                case good
                case reasonable
                case poor
                case weak
            }

            enum Color: String, Decodable {
                case green
                case orange
                case darkorange
                case darkred
                case red
            }

            let word: Word
            let bar: Int32 // 0-100
            let color: Color
            let pass: Bool
        }

        let word: WordDetails
        let time: String
    }

    enum ReplyType: String, Decodable {
        case encrypted
        case plain
    }
}

enum MsgFmt: String {
    case plain
    case encryptInline = "encrypt-inline" // todo - rename these in TypeScript to be camelCase
    case encryptPgpmime = "encrypt-pgpmime"
}

enum KeyVariant: String {
    case rsa2048
    case rsa4096
    case curve25519
}

struct UserId: Encodable {
    let email: String
    let name: String
}

struct SendableMsg: Equatable {
    struct Attachment: Equatable {
        let name: String
        let type: String
        let base64: String
    }

    let text: String
    let to: [String]
    let cc: [String]
    let bcc: [String]
    let from: String
    let subject: String
    let replyToMimeMsg: String?
    let atts: [Attachment]
    let pubKeys: [String]?
    let signingPrv: PrvKeyInfo?
}

struct MsgBlock: Decodable {
    static func blockParseErr(with content: String) -> MsgBlock {
        MsgBlock(type: .blockParseErr, content: content, decryptErr: nil, keyDetails: nil, attMeta: nil)
    }

    let type: BlockType
    let content: String
    let decryptErr: DecryptErr? // always present in decryptErr BlockType
    let keyDetails: KeyDetails? // always present in publicKey BlockType
    let attMeta: AttMeta? // always present in plainAtt, encryptedAtt, decryptedAtt, encryptedAttLink
    // let verifyRes: VerifyRes?,

    // let signature: String? // possibly not neded in Swift

    struct DecryptErr: Decodable {
        let error: Error
        let longids: Longids
        let content: String?
        let isEncrypted: Bool?

        struct Error: Decodable {
            let type: ErrorType
            let message: String
        }

        struct Longids: Decodable {
            let message: [String]
            let matching: [String]
            let chosen: [String]
            let needPassphrase: [String]
        }

        enum ErrorType: String, Decodable {
            case keyMismatch = "key_mismatch"
            case usePassword = "use_password"
            case wrongPwd = "wrong_password"
            case noMdc = "no_mdc"
            case badMdc = "bad_mdc"
            case needPassphrase = "need_passphrase"
            case format
            case other
        }
    }

    struct AttMeta: Decodable {
        let name: String
        let data: Data
        let length: Int
    }

    enum BlockType: String, Decodable {
        case plainHtml // all content blocks, regardless if encrypted or not, formatted as a plainHtml (todo - rename this one day to formattedHtml)
        case publicKey
        case privateKey
        case encryptedMsgLink
        case plainAtt
        case encryptedAtt
        case decryptedAtt
        case encryptedAttLink
        case decryptErr
        case blockParseErr // block type for situations where block json could not be parsed out
        // case cryptupVerification; // not sure if Swift code will ever encounter this
    }
}

// TODO: - ANTON - tests
extension MsgBlock {
    var isAttachmentBlock: Bool {
        type == .plainAtt || type == .encryptedAtt || type == .decryptedAtt
    }
}
