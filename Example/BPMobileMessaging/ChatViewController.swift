//
// Copyright © 2021 BrightPattern. All rights reserved. 

import UIKit
import MessageKit
import InputBarAccessoryView

extension UIColor {
    static let primaryColor = UIColor.systemBlue
}

/// A base class for the example controllers
class ChatViewController: MessagesViewController, MessagesDataSource, ServiceDependencyProviding {
    var service: ServiceDependencyProtocol?
    var currentChatID: String?
    lazy var viewModel: ChatViewModel = {
        guard let service = service, let currentChatID = currentChatID else {
            fatalError("ChatViewModel parameters empty")
        }
        return ChatViewModel(service: service, currentChatID: currentChatID)
    }()

    // MARK: - Private properties

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    private var showPastConversationsButton: UIBarButtonItem?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMessageCollectionView()
        configureMessageInputBar()
        configureNavigationBar()

        viewModel.delegate = self
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? PastConversationsViewController {
            vc.chatSessions = viewModel.chatSessions
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private func configureNavigationBar() {
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        let showPastConversationsButton = UIBarButtonItem.init(title: "Past Conversations",
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(showPastConversationsPressed))
        let endCurrentChatButton = UIBarButtonItem.init(title: "End",
                                                        style: .done,
                                                        target: self,
                                                        action: #selector(endCurrentChatPressed))
        navigationItem.rightBarButtonItems = [endCurrentChatButton, showPastConversationsButton]
        self.showPastConversationsButton = showPastConversationsButton
    }

    func configureMessageCollectionView() {

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        scrollsToBottomOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true

        guard let flowLayout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout else {
            print("Failed to get flowLayout")
            return
        }
        if #available(iOS 13.0, *) {
            flowLayout.collectionView?.backgroundColor = .systemBackground
        }
    }

    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.sendButton.setTitleColor(.primaryColor, for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.primaryColor.withAlphaComponent(0.3),
            for: .highlighted
        )
        // Prepare for a dark mode
        if #available(iOS 13.0, *) {
            messageInputBar.inputTextView.textColor = .label
            messageInputBar.inputTextView.placeholderLabel.textColor = .secondaryLabel
            messageInputBar.backgroundView.backgroundColor = .systemBackground
        }
    }

    @objc
    private func endCurrentChatPressed(_ sender: UITabBarItem) {
        viewModel.endCurrentChatPressed()
    }

    @objc
    private func showPastConversationsPressed(_ sender: UITabBarItem) {
        viewModel.showPastConversationsPressed()
    }

    // MARK: - Helpers

    func lastSectionVisible() -> Bool {
        guard let lastIndexPath = viewModel.lastMessageIndexPath else {
            return false
        }
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }

    // MARK: - MessagesDataSource

    func currentSender() -> SenderType {
        viewModel.currentSender
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        viewModel.chatMessagesCount()
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        viewModel.chatMessage(at: indexPath.section)
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

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {

    // MARK: - Text Messages

    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor.white : .darkText
    }

    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        case .hashtag, .mention: return [.foregroundColor: UIColor.blue]
        default: return MessageLabel.defaultAttributes
        }
    }

    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
    }

    // MARK: - All Messages

    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .primaryColor : UIColor.gray
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {

        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {

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

// MARK: - MessageInputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {

    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }

    func processInputBar(_ inputBar: InputBarAccessoryView) {
        // Here we can parse for which substrings were autocompleted
        let attributedText = inputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in

            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }

        let components = inputBar.inputTextView.components
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        // Send button activity animation
        inputBar.sendButton.startAnimating()
        inputBar.inputTextView.placeholder = "Sending..."
        // Resign first responder for iPad split view
        inputBar.inputTextView.resignFirstResponder()
        viewModel.userEnteredData(components) {
            inputBar.sendButton.stopAnimating()
            inputBar.inputTextView.placeholder = "Aa"
        }
    }
}

// MARK: - View model delegate
extension ChatViewController: ChatViewModelUpdatable {
    func update(appendedCount: Int, updatedCount: Int, _ completion: (() -> Void)?) {
        showPastConversationsButton?.isEnabled = viewModel.showPastConversationsButtonEnabled
        messagesCollectionView.performBatchUpdates({
            let messagesCount = viewModel.chatMessagesCount()
            guard messagesCount > 0 else {
                return
            }
            // There are two use cases:
            //  a) One or more messages added
            //  b) One or more messages updated(message has been read by a remote party)
            // So, there are two group of messages: added and updated
            // Insert sections for appended messages
            if appendedCount > 0 {
                let sectionsToInsert = IndexSet(messagesCount - appendedCount..<messagesCount)
                messagesCollectionView.insertSections(sectionsToInsert)
            }
            // Reload sections with messages that were updated
            let startingIndexToReload = messagesCount - appendedCount - updatedCount
            if updatedCount > 0, startingIndexToReload >= 0 {
                let sectionsToReload = IndexSet(startingIndexToReload..<messagesCount - appendedCount)
                messagesCollectionView.reloadSections(sectionsToReload)
            }
        }, completion: { [weak self] _ in
            if self?.lastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
            completion?()
        })
    }

    func goBack() {
        performSegue(withIdentifier: "unwidnToHelpRequest", sender: self)
    }

    func showPastConversations() {
        performSegue(withIdentifier: "\(PastConversationsViewController.self)", sender: self)
    }
}
