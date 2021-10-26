//
//  EmailProviderMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import Foundation

class EmailProviderMock: EmailProviderType {
    var email: String? = "test@gmail.com"
}
