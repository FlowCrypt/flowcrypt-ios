//
//  RecipientEmailsCellNodeInput.swift
//  FlowCryptUI
//
//  Created by Anton Kharchevskyi on 22/04/2020.
//  Copyright © 2020 FlowCrypt Limited. All rights reserved.
//

import UIKit

// MARK: Input
extension RecipientEmailsCellNode {
    public struct Input {
        public enum State {
            case idle(_ backgroundColor: UIColor, _ borderColor: UIColor, _ textColor: UIColor)
            case selected(_ backgroundColor: UIColor, _ borderColor: UIColor, _ textColor: UIColor)
            case keyFound(_ backgroundColor: UIColor, _ borderColor: UIColor, _ textColor: UIColor)
            case keyNotFound(_ backgroundColor: UIColor, _ borderColor: UIColor, _ textColor: UIColor)
            case error(_ backgroundColor: UIColor, _ borderColor: UIColor, _ textColor: UIColor)

            public var backgroundColor: UIColor {
                switch self {
                case .idle(let color, _, _),
                     .selected(let color, _, _),
                     .keyFound(let color, _, _),
                     .keyNotFound(let color, _, _),
                     .error(let color, _, _):
                    return color
                }
            }

            public var borderColor: UIColor {
                switch self {
                case .idle(_, let color, _),
                     .selected(_, let color, _),
                     .keyFound(_, let color, _),
                     .keyNotFound(_, let color, _),
                     .error(_, let color, _):
                    return color
                }
            }
            
            public var textColor: UIColor {
                switch self {
                case .idle(_, _, let color),
                     .selected(_, _, let color),
                     .keyFound(_, _, let color),
                     .keyNotFound(_, _, let color),
                     .error(_, _, let color):
                    return color
                }
            }

            public var isSelected: Bool {
                switch self {
                case .selected: return true
                default: return false
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
