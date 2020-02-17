import UIKit
import PlaygroundSupport
import AsyncDisplayKit
import FlowCryptUI

final class MyViewController: ASViewController<ASTableNode> {
    enum Elements: Int, CaseIterable {
        case divider
    }

    init() {
        super.init(node: ASTableNode())
        self.node.delegate = self
        self.node.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MyViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        print("tyt")
        return 1
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let part = Elements(rawValue: indexPath.row) else { return ASCellNode() }
            switch part {
            case .divider:
                print("divider")
                return DividerNode(color: .red)
            }
        }
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
