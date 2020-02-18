#warning("Add Comments")

import UIKit
import PlaygroundSupport
import AsyncDisplayKit
import FlowCryptUI

final class MyViewController: ASViewController<ASTableNode> {
    enum Elements: Int, CaseIterable {
        case divider = 0
        case menu = 1
    }

    init() {
        super.init(node: ASTableNode())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.node.delegate = self
        self.node.dataSource = self
        self.node.reloadData()
    }
}

extension MyViewController: ASTableDelegate, ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            let element = Elements(rawValue: indexPath.row)!
            switch element {
            case .divider:
                return DividerNode(color: .red, height: 10)
            case .menu:
                let title = NSAttributedString(string: "tiasmfasfmasmftlmmme", attributes: [NSAttributedString.Key.foregroundColor : UIColor.red])

                let input = MenuNode.Input(
                    attributedText: title,
                    image: nil
                )
                let n = MenuNode(input: input)
                print(n)
                return n
            }
        }
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()

// TODO:
// - Separate Extensions to Common Module
// - prefferedHeight typo
