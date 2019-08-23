//
//  NavigationBarItemsView.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 8/23/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class NavigationBarItemsView: UIBarButtonItem {
    struct Input {
        let image: UIImage?
        let insents: UIEdgeInsets? = Constants.rightUiBarButtonItemImageInsets
        let prefferableFrame: CGRect? = Constants.uiBarButtonItemFrame
        let action: (target: Any?, selector: Selector)?
    }

    init(with input: [Input]) {
        super.init()

        let buttons = input.map { (input: Input) -> UIButton in
            let button = UIButton(type: .system)
            button.setImage(input.image, for: .normal)
            button.imageEdgeInsets = input.insents ?? .zero
            button.frame = input.prefferableFrame ?? .zero
            if let action = input.action {
                button.addTarget(action.target, action: action.selector, for: .touchUpInside)
            }

            return button
        }

        customView = UIStackView(arrangedSubviews: buttons)
            .with {
                $0.distribution = .equalSpacing
                $0.axis = .horizontal
                $0.alignment = .center
                $0.spacing = 15
            }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
