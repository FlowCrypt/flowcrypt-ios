//
//  PublicKey.swift
//  SwiftyRSA
//
//  Created by Lois Di Qual on 5/17/17.
//  Copyright © 2017 Scoop. All rights reserved.
//

import Foundation

public class PublicKey: Key {

    /// Reference to the key within the keychain
    public let reference: SecKey

    /// Data of the public key as provided when creating the key.
    /// Note that if the key was created from a base64string / DER string / PEM file / DER file,
    /// the data holds the actual bytes of the key, not any textual representation like PEM headers
    /// or base64 characters.
    public let originalData: Data?

    let tag: String? // Only used on iOS 8/9

    /// Returns a PEM representation of the public key.
    ///
    /// - Returns: Data of the key, PEM-encoded
    /// - Throws: SwiftyRSAError
    public func pemString() throws -> String {
        let data = try self.data()
        let pem = SwiftyRSA.format(keyData: data, withPemType: "RSA PUBLIC KEY")
        return pem
    }

    /// Creates a public key with a keychain key reference.
    /// This initializer will throw if the provided key reference is not a public RSA key.
    ///
    /// - Parameter reference: Reference to the key within the keychain.
    /// - Throws: SwiftyRSAError
    public required init(reference: SecKey) throws {

        guard SwiftyRSA.isValidKeyReference(reference, forClass: kSecAttrKeyClassPublic) else {
            throw SwiftyRSAError.notAPublicKey
        }

        self.reference = reference
        self.tag = nil
        self.originalData = nil
    }

    /// Data of the public key as returned by the keychain.
    /// This method throws if SwiftyRSA cannot extract data from the key.
    ///
    /// - Returns: Data of the public key as returned by the keychain.
    /// - Throws: SwiftyRSAError
    public required init(data: Data) throws {

        let tag = UUID().uuidString
        self.tag = tag

        self.originalData = data
        let dataWithoutHeader = try SwiftyRSA.stripKeyHeader(keyData: data)

        reference = try SwiftyRSA.addKey(dataWithoutHeader, isPublic: true, tag: tag)
    }

    static let publicKeyRegex: NSRegularExpression? = {
        let publicKeyRegex = "(-----BEGIN PUBLIC KEY-----.+?-----END PUBLIC KEY-----)"
        return try? NSRegularExpression(pattern: publicKeyRegex, options: .dotMatchesLineSeparators)
    }()

    deinit {
        if let tag {
            SwiftyRSA.removeKey(tag: tag)
        }
    }
}
