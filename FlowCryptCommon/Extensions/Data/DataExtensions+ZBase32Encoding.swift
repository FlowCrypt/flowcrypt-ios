//
//  DataExtensions+Encoding.swift
//  FlowCryptCommon
//
//  Created by Yevhen Kyivskyi on 17.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import Foundation

public extension Data {

    private enum Constants {
        static let alphabet = "ybndrfg8ejkmcpqxot1uwisza345h769".unicodeScalars.map { UInt8(ascii: $0) }
        static let bitsInZBase32Character = 5
        static let bitsInByte = 8
    }

    func zBase32EncodedBytes() -> [UInt8] {

        let bytes = [UInt8](self)
        let capacity = (bytes.count / Constants.bitsInZBase32Character) * Constants.bitsInZBase32Character

        var encoded: [UInt8] = []

        encoded.reserveCapacity(capacity)

        var input = bytes.makeIterator()
        while let firstByte = input.next() {
            let secondByte = input.next()
            let thirdByte = input.next()
            let fourthByte = input.next()
            let fifthByte = input.next()

            let firstChar = encode(firstByte: firstByte)
            let secondChar = encode(firstByte: firstByte, secondByte: secondByte)
            let thirdChar = encode(secondByte: secondByte)
            let fourthChar = encode(secondByte: secondByte, thirdByte: thirdByte)
            let fifthChar = encode(thirdByte: thirdByte, fourthByte: fourthByte)
            let sixthChar = encode(fourthByte: fourthByte)
            let seventhChar = encode(fourthByte: fourthByte, fifthByte: fifthByte)
            let eightChar = encode(fifthByte: fifthByte)

            encoded.append(firstChar)
            encoded.append(secondChar)
            if let thirdChar = thirdChar {
                encoded.append(thirdChar)
            }
            if let fourthChar = fourthChar {
                encoded.append(fourthChar)
            }
            if let fifthChar = fifthChar {
                encoded.append(fifthChar)
            }
            if let sixthChar = sixthChar {
                encoded.append(sixthChar)
            }
            if let seventhChar = seventhChar {
                encoded.append(seventhChar)
            }
            if let eightChar = eightChar {
                encoded.append(eightChar)
            }
        }

        return encoded
    }

    private func encode(firstByte: UInt8) -> UInt8 {
        // First: 00000 ---
        let index = firstByte >> 3
        return Constants.alphabet[Int(index)]
    }

    private func encode(firstByte: UInt8, secondByte: UInt8?) -> UInt8 {
        // First: -----000
        var index = (firstByte & 0b00000111) << 2

        if let secondByte = secondByte {
            // Second: 00 ------
            index |= (secondByte & 0b11000000) >> 6
        }

        return Constants.alphabet[Int(index)]
    }

    private func encode(secondByte: UInt8?) -> UInt8? {
        guard let secondByte = secondByte else {
            return nil
        }
        // Second: --00000-
        let index = (secondByte & 0b00111110) >> 1
        return Constants.alphabet[Int(index)]
    }

    private func encode(secondByte: UInt8?, thirdByte: UInt8?) -> UInt8? {
        guard let secondByte = secondByte else {
            return nil
        }
        // Second: -------0
        var index = (secondByte & 0b00000001) << 4

        if let thirdByte = thirdByte {
            // Third: 0000----
            index |= (thirdByte & 0b11110000) >> 4
        }

        return Constants.alphabet[Int(index)]
    }

    private func encode(thirdByte: UInt8?, fourthByte: UInt8?) -> UInt8? {
        guard let thirdByte = thirdByte else {
            return nil
        }
        // Third:----0000
        var index = (thirdByte & 0b00001111) << 1

        if let fourthByte = fourthByte {
            // Fourth: 0-------
            index |= (fourthByte & 0b10000000) >> 7
        }

        return Constants.alphabet[Int(index)]
    }

    private func encode(fourthByte: UInt8?) -> UInt8? {
        guard let fourthByte = fourthByte else {
            return nil
        }
        // Fourth: -00000--
        let index = (fourthByte & 0b01111100) >> 2
        return Constants.alphabet[Int(index)]
    }

    private func encode(fourthByte: UInt8?, fifthByte: UInt8?) -> UInt8? {
        guard let fourthByte = fourthByte else {
            return nil
        }
        // Fourth: ------00
        var index = (fourthByte & 0b00000011) << 3

        if let fifthByte = fifthByte {
            // Fifth: 000-----
            index |= (fifthByte & 0b11100000) >> 5
        }

        return Constants.alphabet[Int(index)]
    }

    private func encode(fifthByte: UInt8?) -> UInt8? {
        guard let fifthByte = fifthByte else {
            return nil
        }
        // // Fifth: ---00000
        let index = fifthByte & 0b00011111
        return Constants.alphabet[Int(index)]
    }
}
