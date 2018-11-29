//
//  AlbumTableViewCell.swift
//  UFPhotoPicker
//
//  Created by 曹华 on 2018/11/28.
//  Copyright © 2018年 曹华. All rights reserved.
//

import UIKit
import SnapKit

let AlbumCellIdentifier = "AlbumCellIdentifier"

class AlbumTableViewCell: UITableViewCell {

    lazy var thumnailImageView: UIImageView = {
        let thumnailImageView = UIImageView.init()
        thumnailImageView.contentMode = .scaleAspectFill
        thumnailImageView.clipsToBounds = true
        self.contentView.addSubview(thumnailImageView)
        return thumnailImageView;
    }()

    lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .black
        lbl.textAlignment = .left
        lbl.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        self.contentView.addSubview(lbl)
        return lbl
    }()

    lazy var countLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .gray
        lbl.textAlignment = .left
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.contentView.addSubview(lbl)
        return lbl
    }()
    
    var title: String? = "" {
        didSet {
            self.titleLabel.text = title
        }
    }
    
    var count: Int = 0 {
        didSet {
            self.countLabel.text = String(count)
        }
    }
    
    var thumnail: UIImage! {
        didSet {
            self.thumnailImageView.image = thumnail
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }

    override var frame: CGRect{
        didSet {
            var newFrame = frame
            newFrame.origin.y += 5
            newFrame.size.height -= 10
            super.frame = newFrame
        }
    }

    func setupUI() {
        self.contentView.clipsToBounds = true
        
        self.thumnailImageView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(self.thumnailImageView.snp.height)
        }
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalTo(self.thumnailImageView.snp.right).offset(17)
        }
        self.countLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(self.titleLabel)
        }
    }
}
