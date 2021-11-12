//
//  RawClientConfigurationTests.swift
//  FlowCryptTests
//
//  Created by Yevhen Kyivskyi on 20.05.2021.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class RawClientConfigurationTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_complete_client_configuraion_json_parse() {
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "client_configuraion", ofType: "json")!)
        let data = try! Data(contentsOf: urlPath, options: .dataReadingMapped)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let model = try? decoder.decode(RawClientConfiguration.self, from: data)

        XCTAssert(model?.flags != nil)
        XCTAssert(model?.customKeyserverUrl != nil)
        XCTAssert(model?.keyManagerUrl != nil)
        XCTAssert(model?.disallowAttesterSearchForDomains != nil)
        XCTAssert(model?.enforceKeygenAlgo != nil)
        XCTAssert(model?.enforceKeygenExpireMonths != nil)
    }

    func test_partial_client_configuraion_json_parse() {
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "client_configuraion_partly_empty", ofType: "json")!)
        let data = try! Data(contentsOf: urlPath, options: .dataReadingMapped)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let model = try? decoder.decode(RawClientConfiguration.self, from: data)

        XCTAssert(model?.flags != nil)
        XCTAssert(model?.enforceKeygenAlgo != nil)
        XCTAssert(model?.enforceKeygenExpireMonths != nil)

        XCTAssert(model?.customKeyserverUrl == nil)
        XCTAssert(model?.keyManagerUrl == nil)
        XCTAssert(model?.disallowAttesterSearchForDomains == nil)
    }

    func test_empty_client_configuraion_json_parse() {
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "client_configuraion_empty", ofType: "json")!)
        let data = try! Data(contentsOf: urlPath, options: .dataReadingMapped)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let model = try? decoder.decode(RawClientConfiguration.self, from: data)

        XCTAssert(model != nil)

        XCTAssert(model?.flags == nil)
        XCTAssert(model?.enforceKeygenAlgo == nil)
        XCTAssert(model?.enforceKeygenExpireMonths == nil)
        XCTAssert(model?.customKeyserverUrl == nil)
        XCTAssert(model?.keyManagerUrl == nil)
        XCTAssert(model?.disallowAttesterSearchForDomains == nil)
    }

    func test_client_configuraion_with_unknown_flag_json_parse() {
        let urlPath = URL(fileURLWithPath: Bundle(for: type(of: self)).path(forResource: "client_configuraion_with_unknown_flag", ofType: "json")!)
        let data = try! Data(contentsOf: urlPath, options: .dataReadingMapped)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let model = try? decoder.decode(RawClientConfiguration.self, from: data)

        XCTAssert(model?.flags != nil)
        XCTAssert(model?.customKeyserverUrl != nil)
        XCTAssert(model?.keyManagerUrl != nil)
        XCTAssert(model?.disallowAttesterSearchForDomains != nil)
        XCTAssert(model?.enforceKeygenAlgo != nil)
        XCTAssert(model?.enforceKeygenExpireMonths != nil)

        XCTAssert(model?.flags?.contains(.unknown) == true)
    }
}
