//
//  LegalViewControllersProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit
import SafariServices

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
        let url: URL?
        switch self {
        case .privacy: url = AppLinks.privacy.url
        case .terms: url = AppLinks.terms.url
        case .license: url = AppLinks.security.url
        case .sources: url = URL(string: "https://github.com/FlowCrypt/")
        }
        guard let link = url else {
            assertionFailure()
            return UIViewController()
        }
        let vc = WebViewController(url: link)
        return vc
    }
}

protocol LegalViewControllersProviderType {
    func viewControllers() -> [Segment]
}

final class LegalViewControllersProvider: NSObject, LegalViewControllersProviderType {
    func viewControllers() -> [Segment] {
        Items.allCases.map {
            Segment(
                viewController: $0.viewController,
                title: $0.title.attributed(.medium(16), color: .white)
            )
        }
    }
}
