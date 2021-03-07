//
// Copyright © 2021 BrightPattern. All rights reserved.

import UIKit
import BPMobileMessaging

class PastConversationsViewController: UIViewController, ServiceDependencyProviding {
    var service: ServiceDependencyProtocol?
    var pastConversationsEvents = [ContactCenterEvent]()

}
