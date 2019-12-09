//
//  LegalViewControllersProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

private enum Items: Int, CaseIterable {
    case privacy, terms, license, sources
    
    var title: String {
        switch self {
        case .privacy: return "settings_legal_privacy".localized
        case .terms: return "settings_legal_terms".localized
        case .license: return "settings_legal_license".localized
        case .sources: return "settings_legal_sources".localized
        }
    }
    
    var viewController: UIViewController {
        UIViewController()
    }
}

protocol LegalViewControllersProviderType {
    func viewControllers() -> [Segment]
}

struct LegalViewControllersProvider: LegalViewControllersProviderType {
    func viewControllers() -> [Segment] {
        Items.allCases.map {
            Segment(
                viewController: $0.viewController,
                title: $0.title.attributed(.medium(16), color: .white)
            )
        }
    }
}
