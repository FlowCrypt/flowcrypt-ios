//
//  Taptic.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 24.09.2019.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

enum TapTicFeedback {

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

enum TapTicType {
    case error, warning, success, light, medium, heavy, changed
}
