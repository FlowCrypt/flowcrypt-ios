//
// © 2017-2019 FlowCrypt Limited. All rights reserved.
//

import Foundation

extension String {

    var hasContent: Bool {
        return trimmingCharacters(in: .whitespaces).isEmpty == false
    }

}