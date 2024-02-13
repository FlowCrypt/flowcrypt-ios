//
//  TapTicFeedback.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 01.10.2019.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import UIKit.UINotificationFeedbackGenerator

public enum TapTicFeedback {
    public static func generate(_ ticType: TapTicType) {
        switch ticType {
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)

        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .changed:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

public enum TapTicType {
    case error, warning, success, light, medium, heavy, changed
}
