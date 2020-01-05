//
//  LegalViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

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
    
    required init?(coder: NSCoder) {
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
        segment.didMove(toParent: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let y = safeAreaWindowInsets.top
            + (navigationController?.navigationBar.frame.height ?? 0)
        segment.node.view.frame = CGRect(
            x: 0,
            y: y,
            width: view.frame.width,
            height: view.frame.height - y
        )
    }
}
