//
//  RecipientEmailsCellNodeInput.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 22/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

public typealias RecipientState = RecipientEmailsCellNode.Input.State
public typealias RecipientStateContext = RecipientEmailsCellNode.Input.StateContext

// MARK: Input

extension RecipientEmailsCellNode {
    public struct Input {
        public struct StateContext {
            let backgroundColor, borderColor, textColor: UIColor
            let image: UIImage?

            public init(
                backgroundColor: UIColor,
                borderColor: UIColor,
                textColor: UIColor,
                image: UIImage?
            ) {
                self.backgroundColor = backgroundColor
                self.borderColor = borderColor
                self.textColor = textColor
                self.image = image
            }
        }

        public enum State: CustomStringConvertible {
            case idle(StateContext)
            case selected(StateContext)
            case keyFound(StateContext)
            case keyNotFound(StateContext)
            case error(StateContext, Bool)

            private var stateContext: StateContext {
                switch self {
                case .idle(let context),
                     .selected(let context),
                     .keyFound(let context),
                     .keyNotFound(let context),
                     .error(let context, _):
                    return context
                }
            }

            public var backgroundColor: UIColor {
                stateContext.backgroundColor
            }

            public var borderColor: UIColor {
                stateContext.borderColor
            }

            public var textColor: UIColor {
                stateContext.textColor
            }

            public var stateImage: UIImage? {
                stateContext.image
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
                case .keyNotFound: return "keyNotFound"
                case .error: return "error"
                }
            }
        }

        public let email: NSAttributedString
        public var state: State

        public init(
            email: NSAttributedString,
            state: State
        ) {
            self.email = email
            self.state = state
        }
    }
}
