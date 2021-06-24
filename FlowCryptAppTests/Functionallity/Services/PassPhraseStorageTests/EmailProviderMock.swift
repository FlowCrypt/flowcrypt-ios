//
//  EmailProviderMock.swift
//  FlowCryptTests
//
//  Created by Anton Kharchevskyi on 07.06.2021.
//  Copyright © 2021 FlowCrypt Limited. All rights reserved.
//

import Foundation
@testable import FlowCrypt

class EmailProviderMock: EmailProviderType {
    var email: String? = "test@gmail.com"
}
