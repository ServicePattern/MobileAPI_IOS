//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation
import UIKit
import MobileCoreServices

protocol UITableCellIdentifiable {
    static var reuseIdentifier: String { get }
}

protocol ChatBubbleCellDelegate: class {
    func bubbleCellImageTapped(_ cell: ChatBubbleCell?, containingMessage message: ChatMessage?)
}

class ChatBubbleCell: UITableViewCell {
    private static let kMaxImageWidth: CGFloat = 180.0
    private static let kNippleMarginX: CGFloat = 11.0
    private static let kImageIndentY: CGFloat = 8.0
    private let kMyBubbleContentIndentX: CGFloat = 5.0
    private let kOtherBubbleContentIndentX: CGFloat = 10.0
    private let kContentIndentX: CGFloat = 5.0
    private static let kContentIndentY: CGFloat = 16.0
    private let kAvatarMarginX: CGFloat = 2.0
    private static let kAvatarMarginY: CGFloat = 4.0
    private static let kTimeStampMarginY: CGFloat = 8.0
    private let kTimeStampMarginX: CGFloat = 4.0
    ///  Chat message
    private var messageValue: ChatMessage?
    var message: ChatMessage? {
        get {
            messageValue
        }
        set {
            setMessageValue(newValue)
        }
    }
    ///  Cell's delegate
    weak var delegate: ChatBubbleCellDelegate?
    ///  Image for message bubble
    var bubbleImage: UIImage?
    ///  Avatar image
    var avatarImage: UIImage?
    ///  Image shown if video file was sent within the message
    var videoFilePlaceholderImage: UIImage?
    ///  Image shown if other (not image or video) file was sent within the message
    var otherFilePlaceholderImage: UIImage?
    ///  Approximate size of message bubble
    var contentWidth: CGFloat = 0.0
    var avatarSize: CGFloat = 0.0
    var avatarCornerRadius: CGFloat = 0.0
    private(set) var messageLabel: LinkLabel?
    private(set) var nameLabel: UILabel?
    private(set) var timeStampLabel: UILabel?
    var timeStampLabelAlignment: TimeStampLabelAlignment?

    private var messageImageView: UIImageView?
    private var bubbleImageView: UIImageView?
    private var avatarImageView: UIImageView?
    private var messageSize = CGSize.zero
    private var titleSize = CGSize.zero
    private var links: [AnyHashable]?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        p_setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        p_resizeControls()
    }

    // MARK: - Properties
    func setMessageValue(_ newMessage: ChatMessage?) {
        guard self.messageValue?.time != newMessage?.time ||
            self.messageValue?.text != newMessage?.text ||
            self.messageValue?.chatID != newMessage?.chatID else {
            return
        }

        //BOOL messageTypeDiffers = (_message.type != message.type);

        self.messageValue = newMessage
        messageLabel?.text = self.messageValue?.text
        messageLabel?.sizeToFit()

        nameLabel?.text = self.messageValue?.senderName

        if let messageAttachment = self.messageValue?.attachment,
           messageAttachment.data != nil,
           let uti = messageAttachment.uti {
            if UTTypeConformsTo(uti as CFString, kUTTypeImage) {
                if let attachmentData = self.messageValue?.attachment?.data,
                   let messageImage = UIImage(data: attachmentData) {
                    messageImageView?.image = messageImage
                    messageSize = Self.p_sizeOf(messageImage)
                } else {
                    messageImageView?.image = nil
                    messageSize = .zero
                    print("Failed to get image data")
                }
            } else if UTTypeConformsTo(uti as CFString, kUTTypeMovie) {
                messageImageView?.image = videoFilePlaceholderImage
                if let videoFilePlaceholderImage = videoFilePlaceholderImage {
                    messageSize = Self.p_sizeOf(videoFilePlaceholderImage)
                } else {
                    messageSize = .zero
                }
            } else {
                messageImageView?.image = otherFilePlaceholderImage
                if let otherFilePlaceholderImage = otherFilePlaceholderImage {
                    messageSize = Self.p_sizeOf(otherFilePlaceholderImage)
                } else {
                    messageSize = .zero
                }
            }
        } else {
            messageImageView?.image = nil
            messageSize = Self.p_calculateSizeOfMessage(
                message,
                messageFont: messageLabel?.font,
                limitedByWidth: contentWidth)
        }

        if let message = self.messageValue,
           MessageType.messageMine == message.type,
           let messageTime = message.time,
           let timeStampLabel = timeStampLabel {
            timeStampLabel.text = DateFormatter.localizedString(
                from: messageTime,
                dateStyle: .medium,
                timeStyle: .short)
        }

        avatarImageView?.image = avatarImage

        if let bubbleImage = bubbleImage,
           let bubbleImageView = bubbleImageView {
            let center = CGPoint(x: bubbleImage.size.width / 2,
                                 y: bubbleImage.size.height / 2)
            let capInsets = UIEdgeInsets(top: center.y,
                                         left: center.x,
                                         bottom: center.y,
                                         right: center.x)
            bubbleImageView.image = bubbleImage.resizableImage(withCapInsets: capInsets,
                                                                resizingMode: .stretch)
        }
        setNeedsLayout()
    }

    func setContentWidth(_ contentWidth: CGFloat) {
        if self.contentWidth == contentWidth {
            return
        }
        self.contentWidth = contentWidth
        setNeedsLayout()
    }

    func setAvatarSize(_ avatarSize: CGFloat) {
        if self.avatarSize == avatarSize {
            return
        }
        self.avatarSize = avatarSize
        setNeedsLayout()
    }

    func setAvatarCornerRadius(_ avatarCornerRadius: CGFloat) {
        guard self.avatarCornerRadius != avatarCornerRadius else {
            return
        }
        self.avatarCornerRadius = avatarCornerRadius

        avatarImageView?.layer.cornerRadius = self.avatarCornerRadius
        avatarImageView?.layer.masksToBounds = true

        setNeedsLayout()
    }

    // MARK: - Public
    class func requiredHeight(
        forCellDisplayingMessage message: ChatMessage?,
        avatarHeight: CGFloat,
        videoFilePlaceholderImage: UIImage?,
        otherFilePlaceholderImage: UIImage?,
        messageFont: UIFont?,
        timeStamp timeStampFont: UIFont?,
        senderNameFont: UIFont?,
        timeStamp alignment: TimeStampLabelAlignment,
        limitedByWidth width: CGFloat
    ) -> CGFloat {
        let timeStampHeight = Self.p_calculateSizeOfText(
            "date",
            using: timeStampFont,
            limitedByWidth: width).height

        let userNameHeight = Self.p_calculateSizeOfText(
            message?.senderName,
            using: senderNameFont,
            limitedByWidth: width).height
        let avatarOffsetY = avatarHeight != 0.0 ? avatarHeight + Self.kAvatarMarginY : 0.0
        let messageSize: CGSize

        if let messageAttachment = message?.attachment,
           messageAttachment.data != nil,
           let uti = messageAttachment.uti {
            if UTTypeConformsTo(uti as CFString, kUTTypeImage) {
                if let data = messageAttachment.data,
                   let messageImage = UIImage(data: data) {
                    messageSize = Self.p_sizeOf(messageImage)
                } else {
                    messageSize = .zero
                }
            } else if UTTypeConformsTo(uti as CFString, kUTTypeMovie) {
                if let videoFilePlaceholderImage = videoFilePlaceholderImage {
                    messageSize = Self.p_sizeOf(videoFilePlaceholderImage)
                } else {
                    messageSize = .zero
                }
            } else {
                if let otherFilePlaceholderImage = otherFilePlaceholderImage {
                    messageSize = Self.p_sizeOf(otherFilePlaceholderImage)
                } else {
                    messageSize = .zero
                }
            }
        } else {
            messageSize = Self.p_calculateSizeOfMessage(
                message,
                messageFont: messageFont,
                limitedByWidth: width)
        }

        let height: CGFloat
        if .timeStampCenterAligned == alignment {
            height = ceil(kTimeStampMarginY + timeStampHeight + CGFloat(max(messageSize.height, avatarOffsetY)) + userNameHeight) + kContentIndentY
        } else {
            height = ceil(kTimeStampMarginY + max(timeStampHeight, max(messageSize.height, avatarOffsetY)) + userNameHeight)
        }
        return height
    }

    func p_resizeControls() {
        let messageFrame: CGRect
        let avatarOffsetX: CGFloat
        //CGFloat labelOffset = kContentIndentX;
        if avatarImage != nil {
            //labelOffset += kAvatarMarginX + _avatarSize;
            avatarOffsetX = avatarSize + kAvatarMarginX + 2 * kContentIndentX
        } else {
            avatarOffsetX = 0
        }

        let titleSize = Self.p_calculateSizeOfText(
            message?.senderName,
            using: nameLabel?.font,
            limitedByWidth: contentWidth)

        if MessageType.messageMine == message?.type {
            let timeStampSize = p_timeStampSizeLimited(byWidth: frame.width)
            timeStampLabel?.frame = CGRect(
                x: 0,
                y: 0,
                width: frame.width,
                height: timeStampSize.height)

            nameLabel?.frame = CGRect(
                x: frame.width - titleSize.width - kContentIndentX,
                y: frame.height - titleSize.height + timeStampSize.height / 3 - Self.kAvatarMarginY - Self.kContentIndentY,
                width: titleSize.width,
                height: titleSize.height)

            messageLabel?.changeTextColor(to: .white)

            if avatarImage != nil,
               let avatarImageView = avatarImageView {
                avatarImageView.frame = CGRect(
                    x: frame.width - kContentIndentX - avatarSize,
                    y: frame.height - titleSize.height - Self.kAvatarMarginY - avatarSize - Self.kContentIndentY,
                    width: avatarSize,
                    height: avatarSize)
            }

            if let bubbleImageView = bubbleImageView {
                bubbleImageView.frame = CGRect(
                    x: frame.width - messageSize.width - avatarOffsetX - kContentIndentX,
                    y: frame.height - titleSize.height - messageSize.height + timeStampSize.height / 2 - Self.kContentIndentY,
                    width: messageSize.width - Self.kNippleMarginX,
                    height: messageSize.height - Self.kImageIndentY - 2.0)

                messageFrame = CGRect(
                    x: bubbleImageView.frame.minX + kMyBubbleContentIndentX,
                    y: bubbleImageView.frame.minY + Self.kImageIndentY - 2.0,
                    width: messageSize.width - 2 * Self.kNippleMarginX,
                    height: messageSize.height - 3 * Self.kImageIndentY)
            } else {
                messageFrame = CGRect.zero
            }
        } else {
            nameLabel?.frame = CGRect(
                x: 3 * kContentIndentX + 2.0,
                y: frame.height - titleSize.height - Self.kContentIndentY,
                width: titleSize.width,
                height: titleSize.height)

            messageLabel?.changeTextColor(to: .black)

            if avatarImage != nil {
                let avatarOffsetY: CGFloat = avatarSize + Self.kAvatarMarginY
                avatarImageView?.frame = CGRect(
                    x: 3 * kContentIndentX,
                    y: frame.height - titleSize.height - avatarOffsetY - Self.kContentIndentY,
                    width: avatarSize,
                    height: avatarSize)
            }

            if let bubbleImageView = bubbleImageView {
                bubbleImageView.frame = CGRect(
                    x: avatarOffsetX + 3 * kContentIndentX + 2.0,
                    y: frame.height - titleSize.height - messageSize.height - Self.kContentIndentY,
                    width: messageSize.width - Self.kNippleMarginX,
                    height: messageSize.height - Self.kImageIndentY - 2.0)

                messageFrame = CGRect(
                    x: bubbleImageView.frame.minX + kOtherBubbleContentIndentX,
                    y: bubbleImageView.frame.minY + Self.kImageIndentY - 2.0,
                    width: messageSize.width - 2.0 * Self.kNippleMarginX,
                    height: messageSize.height - 3.0 * Self.kImageIndentY)
            } else {
                messageFrame = CGRect.zero
            }

            if TimeStampLabelAlignment.timeStampCenterAligned == timeStampLabelAlignment {
                let timeStampSize = p_timeStampSizeLimited(byWidth: frame.width)
                timeStampLabel?.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: frame.width,
                    height: timeStampSize.height)
            } else if let bubbleImageView = bubbleImageView,
                      let timeStampLabel = timeStampLabel {
                let timeStampSize = p_timeStampSizeLimited(byWidth: frame.width - bubbleImageView.frame.width - kTimeStampMarginX)

                timeStampLabel.frame = CGRect(
                    x: bubbleImageView.frame.minX + bubbleImageView.frame.width + kTimeStampMarginX,
                    y: bubbleImageView.frame.minY,
                    width: timeStampSize.width,
                    height: timeStampSize.height)
            }
        }

        if message?.attachment?.data != nil {
            messageImageView?.frame = messageFrame
            messageLabel?.isHidden = true
            messageImageView?.isHidden = false
            bubbleImageView?.image = nil
        } else {
            messageLabel?.frame = messageFrame
            messageLabel?.isHidden = false
            messageImageView?.isHidden = true
        }
    }

    @objc func p_handleImageTap(_ recognizer: UITapGestureRecognizer?) {
        delegate?.bubbleCellImageTapped(self, containingMessage: message)
    }

    class func p_sizeOf(_ image: UIImage) -> CGSize {
        if image.size.width > kMaxImageWidth {
            return CGSize(width: Self.kMaxImageWidth,
                          height: image.size.height * Self.kMaxImageWidth / image.size.width)
        } else {
            return image.size
        }
    }

    func p_timeStampSizeLimited(byWidth limitWidth: CGFloat) -> CGSize {
        guard let timeStampLabel = timeStampLabel else {
            return .zero
        }

        guard timeStampLabel.text?.count ?? 0 > 0 ||
            timeStampLabel.isHidden == false else {
            return .zero
        }

        let timeStampSize: CGSize
        if let font = timeStampLabel.font {
            timeStampSize = timeStampLabel.text?.boundingRect(
                    with: CGSize(width: frame.width, height: limitWidth),
                    options: .usesLineFragmentOrigin,
                    attributes: [
                        NSAttributedString.Key.font: font
                    ],
                    context: nil).size ?? .zero
        } else {
            timeStampSize = .zero
        }

        return CGSize(width: ceil(timeStampSize.width),
                      height: ceil(timeStampSize.height + Self.kTimeStampMarginY))
    }

    func p_setupCell() {
        selectionStyle = UITableViewCell.SelectionStyle.none
        backgroundColor = UIColor.clear

        let messageLabel = LinkLabel(frame: .zero)
        messageLabel.isUserInteractionEnabled = true
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.backgroundColor = UIColor.clear

        self.messageLabel = messageLabel

        let nameLabel = UILabel(frame: .zero)
        nameLabel.backgroundColor = UIColor.clear
        self.nameLabel = nameLabel

        let timeStampLabel = UILabel(frame: CGRect.zero)
        timeStampLabel.backgroundColor = UIColor.clear
        timeStampLabel.textAlignment = .center
        timeStampLabel.lineBreakMode = .byWordWrapping
        timeStampLabel.numberOfLines = 0
        self.timeStampLabel = timeStampLabel

        let bubbleImageView = UIImageView(frame: CGRect.zero)
        self.bubbleImageView = bubbleImageView
        let avatarImageView = UIImageView(frame: CGRect.zero)
        self.avatarImageView = avatarImageView
        let messageImageView = UIImageView(frame: CGRect.zero)
        messageImageView.layer.cornerRadius = 5.0
        messageImageView.layer.masksToBounds = true
        messageImageView.isUserInteractionEnabled = true
        self.messageImageView = messageImageView

        contentView.addSubview(bubbleImageView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(messageImageView)
        contentView.addSubview(messageLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeStampLabel)

        bubbleImageView.isUserInteractionEnabled = false
        contentView.bringSubview(toFront: messageLabel)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(p_handleImageTap))
        messageImageView.addGestureRecognizer(tapRecognizer)
    }

    // MARK: - Private
    class func p_calculateSizeOfMessage(
        _ message: ChatMessage?,
        messageFont: UIFont?,
        limitedByWidth width: CGFloat
    ) -> CGSize {
        let labelSize = Self.p_calculateSizeOfText(
            message?.text,
            using: messageFont,
            limitedByWidth: width)

        let messageSize = CGSize(
            width: ceil(labelSize.width) + 2.0 * Self.kNippleMarginX,
            height: ceil(labelSize.height) + 3.0 * kImageIndentY)

        return messageSize
    }

    class func p_calculateSizeOfText(_ text: String?, using font: UIFont?, limitedByWidth width: CGFloat) -> CGSize {
        guard text != nil && font != nil else {
            return CGSize.zero
        }

        let size: CGSize
        if let font = font {
            size = text?.boundingRect(
                with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: [
                    NSAttributedString.Key.font: font
                ],
                context: nil).size ?? .zero
        } else {
            size = .zero
        }

        return CGSize(width: ceil(size.width) + 14.0, height: ceil(size.height))
    }

    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
    }
}

extension ChatBubbleCell: UITableCellIdentifiable {
    static var reuseIdentifier: String {
        "\(ChatBubbleCell.self)"
    }

}
