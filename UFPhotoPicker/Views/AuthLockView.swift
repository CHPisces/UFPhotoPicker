//
//  AuthLockView.swift
//  UFPhotoPicker
//
//  Created by 曹华 on 2018/11/28.
//  Copyright © 2018年 曹华. All rights reserved.
//

import UIKit

protocol AuthLockViewDelegate {
    func toSetting()
}

class AuthLockView: UIView {

    private var titleLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var actionButton: UIButton!

    var delegate: AuthLockViewDelegate? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        self.backgroundColor = UIColor.gray
        self.titleLabel = UILabel.init()
        self.titleLabel.textAlignment = .center
        self.titleLabel.textColor = .white
        self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.titleLabel.numberOfLines = 0
        self.addSubview(self.titleLabel)

        self.descriptionLabel = UILabel.init()
        self.descriptionLabel.textAlignment = .center
        self.descriptionLabel.textColor = .white
        self.descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.descriptionLabel.numberOfLines = 0
        self.addSubview(self.descriptionLabel)

        self.actionButton = UIButton(type: .custom)
        self.actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.actionButton.titleLabel?.textColor = .white
        self.addSubview(self.actionButton)

        self.descriptionLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.right.lessThanOrEqualToSuperview()
        }
        self.titleLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.descriptionLabel.snp.top).offset(-50)
            make.left.right.lessThanOrEqualToSuperview()
        }
        self.actionButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.descriptionLabel.snp.bottom).offset(50)
            make.width.equalTo(100)
            make.height.equalTo(30)
        }
    }
    
    var title: String = "Denied." {
        didSet {
            titleLabel.text = title
        }
    }
    
    var detail: String = "" {
        didSet {
            descriptionLabel.text = detail
        }
    }
    
    var buttonTitle: String = "Setting" {
        didSet {
            actionButton.setTitle(buttonTitle, for: .normal)
            actionButton.addBorder(.all, color: UIColor.white, thickness: 2.0)
            actionButton.addTarget(self, action: #selector(goToAction), for: .touchUpInside)
        }
    }

    @objc private func goToAction() {
        if delegate != nil {
            delegate?.toSetting()
        }
    }
}
