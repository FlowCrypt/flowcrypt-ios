//
//  XCUIApplicationBuilder.swift
//  FlowCryptUITests
//
//  Created by Anton Kharchevskyi on 18.10.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import Foundation
import XCTest

struct XCUIApplicationBuilder {
    private let app: XCUIApplication
    
    init() {
        app = XCUIApplication()
        app.launchArguments.append("--is-ui-test")
    }
    
    func reset() -> XCUIApplicationBuilder {
        app.launchArguments.append(AppReset.reset.rawValue)
        return self
    }

    func build() -> XCUIApplication {
        return app
    }
}
