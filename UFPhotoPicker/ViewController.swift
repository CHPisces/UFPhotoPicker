//
//  ViewController.swift
//  UFPhotoPicker
//
//  Created by 曹华 on 2018/11/29.
//  Copyright © 2018年 曹华. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var photoButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        photoButton = UIButton.init(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        photoButton!.backgroundColor = .red
        photoButton?.setTitle("Photo", for: .normal)
        self.view.addSubview(photoButton!)
        photoButton!.addTarget(self, action: #selector(enterPhotoVC), for: .touchUpInside)
    }

    @objc private func enterPhotoVC() {
        let photoVC = PhotoGridViewController()
        self.present(photoVC, animated: true, completion: nil)
    }
}

