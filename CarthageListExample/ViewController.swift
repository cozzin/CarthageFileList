//
//  ViewController.swift
//  CarthageListExample
//
//  Created by seongho on 2019/06/30.
//  Copyright © 2019 seongho. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    
    private lazy var bodyView: UIView = {
        let bodyView: UIView = UIView()
        bodyView.backgroundColor = .blue
        return bodyView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(bodyView)
        bodyView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(100)
        }
    }
}

