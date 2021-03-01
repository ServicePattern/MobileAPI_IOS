//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation
import UIKit

class ChatViewController: ViewController, ServiceDependencyProviding {
    var service: ServiceDependencyProtocol?
    var currentChatID: String?
    lazy var viewModel: ChatViewModel = {
        guard let service = service, let currentChatID = currentChatID else {
            fatalError("ChatViewModel parameters empty")
        }
        let model = ChatViewModel(service: service, currentChatID: currentChatID)
        model.delegate = self
        return model
    }()

    @IBOutlet weak var chatTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        chatTableView.register(ChatBubbleCell.self, forCellReuseIdentifier: ChatBubbleCell.reuseIdentifier)
    }
}

extension ChatViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sectionsCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(section: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatBubbleCell.reuseIdentifier, for: indexPath) as? ChatBubbleCell else {

            return UITableViewCell()
        }


        let message = viewModel.chatMessage(at: indexPath.row)
        configure(cell, at: indexPath, with: message)
        cell.message = message

        return cell
    }

    func configure(_ cell: ChatBubbleCell, at: IndexPath, with message: ChatMessage) {
    }
}

extension ChatViewController: ChatViewModelUpdatable {
    func update() {
        // TODO: optimize it
        chatTableView.reloadData()
    }
}
