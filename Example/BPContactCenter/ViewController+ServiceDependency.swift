//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation
import UIKit
import BPContactCenter

protocol ServiceDependencyProtocol: class {
    var contactCenterService: ContactCenterCommunicating { get set }
    var useFirebase: Bool { get set }
    var deviceToken: String? { get set }
}

protocol ServiceDependencyProviding: class {
    var service: ServiceDependencyProtocol? { get set }
}

class ViewController: UIViewController {
    // Try to inject service container dependency on transition between view controllers
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let sourceVC = segue.source as? ServiceDependencyProviding,
           let destinationVC = segue.destination as? ServiceDependencyProviding {
            destinationVC.service = sourceVC.service
        }
    }
}
