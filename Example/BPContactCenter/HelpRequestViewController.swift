//
//  ViewController.swift
//  BPContactCenter
//
//  Created by BrightPattern on 02/12/2021.
//  Copyright (c) 2021 BrightPattern. All rights reserved.
//

import UIKit
import BPContactCenter

class HelpRequestViewController: ViewController, ServiceDependencyProviding {
    var service: ServiceDependencyProtocol?
    var bundleIdentifier: String = Bundle.main.bundleIdentifier ?? ""

    private lazy var viewModel: HelpRequestViewModel = {
        guard let service = service else {
            fatalError("Contact center service is not set")
        }

        return HelpRequestViewModel(service: service)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = true
    }

    @IBAction func helpMePressed(_ sender: UIButton) {
        viewModel.helpMePressed()
    }
}
