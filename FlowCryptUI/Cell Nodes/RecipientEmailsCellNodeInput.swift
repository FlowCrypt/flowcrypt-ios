//
//  RecipientEmailsCellNodeInput.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 22/04/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit

// MARK: Input
public extension RecipientEmailsCellNode {
    struct Input {
        public struct StateContext: Equatable {
            let backgroundColor, borderColor, textColor: UIColor
            let image: UIImage?
            let accessibilityIdentifier: String?

            public init(
                backgroundColor: UIColor,
                borderColor: UIColor,
                textColor: UIColor,
                image: UIImage?,
                accessibilityIdentifier: String?
            ) {
                self.backgroundColor = backgroundColor
                self.borderColor = borderColor
                self.textColor = textColor
                self.image = image
                self.accessibilityIdentifier = accessibilityIdentifier
            }
        }

        public enum State: CustomStringConvertible, Equatable {
            case idle(StateContext)
            case selected(StateContext)
            case keyFound(StateContext)
            case keyExpired(StateContext)
            case keyRevoked(StateContext)
            case keyNotFound(StateContext)
            case invalidEmail(StateContext)
            case error(StateContext, Bool)

            private var stateContext: StateContext {
                switch self {
                case .idle(let context),
                     .selected(let context),
                     .keyFound(let context),
                     .keyExpired(let context),
                     .keyRevoked(let context),
                     .keyNotFound(let context),
                     .invalidEmail(let context),
                     .error(let context, _):
                    return context
                }
            }

            var backgroundColor: UIColor {
                stateContext.backgroundColor
            }

            var borderColor: UIColor {
                stateContext.borderColor
            }

            public var textColor: UIColor {
                stateContext.textColor
            }

            var stateImage: UIImage? {
                stateContext.image
            }

            var accessibilityIdentifier: String? {
                stateContext.accessibilityIdentifier
            }

            public var isSelected: Bool {
                switch self {
                case .selected: return true
                default: return false
                }
            }

            public var description: String {
                switch self {
                case .idle: return "idle"
                case .selected: return "selected"
                case .keyFound: return "keyFound"
                case .keyExpired: return "keyExpired"
                case .keyRevoked: return "keyRevoked"
                case .keyNotFound: return "keyNotFound"
                case .invalidEmail: return "invalidEmail"
                case .error: return "error"
                }
            }
        }

        let email: NSAttributedString
        let type: String
        var state: State

        public init(
            email: NSAttributedString,
            type: String,
            state: State
        ) {
            self.email = email
            self.type = type
            self.state = state
        }
    }
}
