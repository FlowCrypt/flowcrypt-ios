//
//  LegalViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

/**
 * View controller which shows legal information (privacy, license, sources, terms)
 * - User can be redirected here from settings *SettingsViewController*
 */
final class LegalViewController: UIViewController {
    private let provider: LegalViewControllersProviderType
    private lazy var segment: SegmentedViewController = SegmentedViewController(
        dataSource: self.provider.viewControllers()
    )

    init(
        provider: LegalViewControllersProviderType = LegalViewControllersProvider()
    ) {
        self.provider = provider
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        title = "settings_screen_legal".localized
        edgesForExtendedLayout = [.top]
        addChild(segment)
        view.addSubview(segment.node.view)
        view.backgroundColor = .backgroundColor
        segment.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let originY = safeAreaWindowInsets.top
            + (navigationController?.navigationBar.frame.height ?? 0)
        segment.node.view.frame = CGRect(
            x: 0,
            y: originY,
            width: view.frame.width,
            height: view.frame.height - originY
        )
    }
}
