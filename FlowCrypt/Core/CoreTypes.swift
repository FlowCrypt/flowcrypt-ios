//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import RealmSwift

struct CoreRes {
    struct Version: Decodable {
        let app_version: String
    }

    struct ComposeEmail {
        let mimeEncoded: Data
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

    struct DecryptFile {
        let decryptSuccess: DecryptSuccess?
        let decryptErr: DecryptErr?
        struct DecryptSuccess {
            let name: String
            let data: Data
        }
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

    struct AttachmentTreatAs: Decodable {
        let id: String
        let treatAs: String
    }
}

enum ReplyType: String, Decodable {
    case encrypted
    case plain
}

enum MsgFmt: String {
    case plain, encryptInline, encryptPgpmime
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
    let html: String?
    let to: [String]
    let cc: [String]
    let bcc: [String]
    let from: String
    let subject: String
    let replyToMsgId: String?
    let inReplyTo: String?
    let atts: [Attachment]
    let pubKeys: [String]?
    let signingPrv: Keypair?
    let password: String?
}

extension SendableMsg {
    func copy(body: SendableMsgBody, atts: [Attachment], pubKeys: [String]?, includeBcc: Bool = true) -> SendableMsg {
        SendableMsg(
            text: body.text,
            html: body.html,
            to: self.to,
            cc: self.cc,
            bcc: includeBcc ? bcc : [],
            from: self.from,
            subject: self.subject,
            replyToMsgId: self.replyToMsgId,
            inReplyTo: self.inReplyTo,
            atts: atts,
            pubKeys: pubKeys,
            signingPrv: self.signingPrv,
            password: self.password
        )
    }
}

struct SendableMsgBody {
    let text: String
    let html: String?
}

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

struct MsgBlock: Decodable {
    static func blockParseErr(with content: String) -> MsgBlock {
        MsgBlock(type: .blockParseErr, content: content, decryptErr: nil, keyDetails: nil, verifyRes: nil, attMeta: nil)
    }

    let type: BlockType
    let content: String
    let decryptErr: DecryptErr? // always present in decryptErr BlockType
    let keyDetails: KeyDetails? // always present in publicKey BlockType
    let verifyRes: VerifyRes?
    let attMeta: AttMeta?

    struct VerifyRes: Decodable {
        let match: Bool?
        let signer: String?
        let error: String?
        let mixed: Bool?
        let partial: Bool?
    }

    struct AttMeta: Decodable {
        let name: String
        let data: String
        let type: String
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

    static func decode(from data: Data) -> MsgBlock {
        guard let block = try? data.decodeJson(as: MsgBlock.self)
        else {
            let content = String(data: data, encoding: .utf8) ?? "(utf err)"
            return MsgBlock.blockParseErr(with: content)
        }

        return block
    }
}
