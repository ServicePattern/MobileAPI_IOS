//
// Copyright © 2021 BrightPattern. All rights reserved.

import UIKit
import MessageKit
import BPMobileMessaging

class PastConversationsViewController: MessagesViewController, ServiceDependencyProviding {

    var service: ServiceDependencyProtocol?
    var chatSessions = [ContactCenterChatSession]()
    lazy var viewModel: PastConversationsViewModel = {
        PastConversationsViewModel(sessions: chatSessions)
    }()

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    override var inputAccessoryView: UIView? {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMessageCollectionView()
        viewModel.delegate = self
    }

    func configureMessageCollectionView() {

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        guard let flowLayout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout else {
            print("Failed to get flowLayout")
            return
        }
        if #available(iOS 13.0, *) {
            flowLayout.collectionView?.backgroundColor = .systemBackground
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    func lastSectionVisible() -> Bool {
        guard let lastIndexPath = viewModel.lastMessageIndexPath else {
            return false
        }
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
}

extension PastConversationsViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        viewModel.currentSender
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        viewModel.chatMessage(at: indexPath.section)
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        viewModel.chatMessagesCount()
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.systemGray])
        }
        return nil
    }

    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        (message as? ChatMessage)?.read == true ?
            NSAttributedString(string: "Read", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.systemGray]) :
            NSAttributedString(string: "")
    }

    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
}

// MARK: - Chat Layout

extension PastConversationsViewController: MessagesLayoutDelegate {
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 18
    }

    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 17
    }

    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }

    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
}

// MARK: - Chat Display

extension PastConversationsViewController: MessagesDisplayDelegate {

    // MARK: - Text Messages

    func textColor(for messageType: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        viewModel.textColor(for: messageType, isFromCurrentSender: isFromCurrentSender(message: messageType))
    }

    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        case .hashtag, .mention:
            return [.foregroundColor: UIColor.blue]
        default:
            return MessageLabel.defaultAttributes
        }
    }

    func enabledDetectors(for messageType: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
    }

    // MARK: - All Messages

    func backgroundColor(for messageType: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        viewModel.backgroundColor(for: messageType,
                                  isFromCurrentSender: isFromCurrentSender(message: messageType))
    }

    func messageStyle(for messageType: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {

        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: messageType) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }
}

extension PastConversationsViewController: PastConversationsViewModelUpdatable {
    func update() {
        messagesCollectionView.performBatchUpdates({
            let messagesCount = viewModel.chatMessagesCount()
            guard messagesCount > 0 else {
                return
            }
            let sectionsToInsert = IndexSet(0..<messagesCount)
            messagesCollectionView.insertSections(sectionsToInsert)
        }, completion: { [weak self] _ in
            if self?.lastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        })
    }
}
