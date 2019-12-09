//
//  ASSegmentedViewController.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 12/9/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import AsyncDisplayKit

struct Segment {
    let viewController: UIViewController
    let title: NSAttributedString
}

struct SegmentStyle {
    static let `default` = SegmentStyle(
        height: 50,
        insets: UIEdgeInsets.side(8),
        tabTintColor: .main
    )
    let height: CGFloat
    let insets: UIEdgeInsets
    let tabTintColor: UIColor
}

// TODO: - Move to page tab based layout
final class SegmentedViewController: ASViewController<ASDisplayNode> {
    private var dataSource: [Segment] = []
    private var collectionNode = ASCollectionNode(collectionViewLayout: UICollectionViewFlowLayout())
    private var style: SegmentStyle = .default
    private var segmentView = ASDisplayNode()
     
    init(
        dataSource: [Segment],
        style: SegmentStyle = .default
    ) {
        self.dataSource = dataSource
        self.style = style
        super.init(node: ASDisplayNode())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        node.addSubnode(collectionNode)
        node.addSubnode(segmentView)
        collectionNode.do {
            $0.backgroundColor = style.tabTintColor
            $0.view.contentInsetAdjustmentBehavior = .never
            $0.dataSource = self
        }
        node.backgroundColor = style.tabTintColor
        segmentView.backgroundColor = .red
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let calculatedWidth = dataSource
            .map { $0.title }
            .map { $0.size().width }
            .reduce(0, +)
        let collectionWidth = calculatedWidth
            + CGFloat(dataSource.count) * style.insets.width
        let x = (view.frame.size.width - collectionWidth) / 2
        
        collectionNode.frame = CGRect(
            x: x,
            y: 0,
            width: view.frame.width,
            height: style.height
        )
        segmentView.frame = CGRect(
            x: 0,
            y: collectionNode.frame.maxY,
            width: view.frame.width,
            height: view.frame.height - style.height - collectionNode.frame.origin.x
        )
        
    }
}

extension SegmentedViewController: ASCollectionDataSource {
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self, let item = self.dataSource[safe: indexPath.row] else { return ASCellNode() }
            return SetupTitleNode(title: item.title, insets: UIEdgeInsets.side(8))
        }
    }
}
