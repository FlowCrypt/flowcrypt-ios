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
            var isSelected: Bool

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
                self.isSelected = false
            }
        }

        public enum State: CustomStringConvertible, Equatable {
            case idle(StateContext)
            case keyFound(StateContext)
            case keyExpired(StateContext)
            case keyRevoked(StateContext)
            case keyNotFound(StateContext)
            case invalidEmail(StateContext)
            case error(StateContext, Bool)

            private var stateContext: StateContext {
                switch self {
                case let .idle(context),
                     let .keyFound(context),
                     let .keyExpired(context),
                     let .keyRevoked(context),
                     let .keyNotFound(context),
                     let .invalidEmail(context),
                     let .error(context, _):
                    return context
                }
            }

            var alpha: CGFloat {
                if case .keyNotFound = self { // Increase opacity for keyNotFound state when selected
                    return stateContext.isSelected ? 2.0 : 1.0
                }
                return stateContext.isSelected ? 0.5 : 1.0
            }

            var backgroundColor: UIColor {
                stateContext.backgroundColor.scaleAlpha(by: alpha)
            }

            var borderColor: UIColor {
                stateContext.borderColor.scaleAlpha(by: alpha)
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
                get {
                    stateContext.isSelected
                }
                set {
                    switch self {
                    case var .idle(context):
                        context.isSelected = newValue
                        self = .idle(context)
                    case var .keyFound(context):
                        context.isSelected = newValue
                        self = .keyFound(context)
                    case var .keyExpired(context):
                        context.isSelected = newValue
                        self = .keyExpired(context)
                    case var .keyRevoked(context):
                        context.isSelected = newValue
                        self = .keyRevoked(context)
                    case var .keyNotFound(context):
                        context.isSelected = newValue
                        self = .keyNotFound(context)
                    case var .invalidEmail(context):
                        context.isSelected = newValue
                        self = .invalidEmail(context)
                    case var .error(context, flag):
                        context.isSelected = newValue
                        self = .error(context, flag)
                    }
                }
            }

            public var description: String {
                switch self {
                case .idle: return "idle"
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
