//
//  LegalViewControllersProvider.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import SafariServices
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

    var url: URL? {
        switch self {
        case .privacy: return URL(string: "https://flowcrypt.com/privacy")
        case .terms: return URL(string: "https://flowcrypt.com/terms")
        case .license: return URL(string: "https://flowcrypt.com/license")
        case .sources: return URL(string: "https://github.com/FlowCrypt/flowcrypt-ios")
        }
    }

    var viewController: UIViewController {
        guard let link = self.url else {
            fatalError("Links are hardcoded so they have not to be nil")
        }
        let vc = WebViewController(url: link)
        return vc
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
