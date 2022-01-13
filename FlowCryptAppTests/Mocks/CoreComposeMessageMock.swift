//
//  CoreComposeMessageMock.swift
//  FlowCryptAppTests
//
//  Created by Anton Kharchevskyi on 25.07.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Foundation

class CoreComposeMessageMock: CoreComposeMessageType, KeyParser {
    var composeEmailResult: ((SendableMsg, MsgFmt) -> (CoreRes.ComposeEmail))!
    func composeEmail(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail {
        return composeEmailResult(msg, fmt)
    }

    var parseKeysResult: ((Data) -> (CoreRes.ParseKeys))!
    func parseKeys(armoredOrBinary: Data) throws -> CoreRes.ParseKeys {
        return parseKeysResult(armoredOrBinary)
    }

    func encryptMsg(msg: SendableMsg, fmt: MsgFmt) async throws -> CoreRes.ComposeEmail {
        throw(AppErr.general("not implemented"))
    }

    func encryptFile(pubKeys: [String]?, fileData: Data, name: String) async throws -> CoreRes.EncryptFile {
        throw(AppErr.general("not implemented"))
    }
}
