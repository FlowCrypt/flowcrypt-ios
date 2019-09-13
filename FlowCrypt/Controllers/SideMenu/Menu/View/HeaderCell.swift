//
//  HeaderCell.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 9/13/19.
//  Copyright © 2019 FlowCrypt Limited. All rights reserved.
//

import UIKit

final class HeaderCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        selectionStyle = .none
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel]).then {
            $0.distribution = .equalCentering
            $0.axis = .vertical
            $0.alignment = .leading
            $0.spacing = 8
            addSubview($0)
        }
        constrainToEdges(stackView, insets:  UIEdgeInsets(top: 32, left: 16, bottom: 32, right: 16))
    }

    func setup(with viewModel: MenuHeaderViewModel) -> Self {
        titleLabel.attributedText = viewModel.title
        subTitleLabel.attributedText = viewModel.subtitle
        backgroundColor = .main
        return self
    }
}
