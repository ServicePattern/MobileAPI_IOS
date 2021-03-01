//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation
import UIKit

enum TimeStampLabelAlignment : Int {
    ///  Timestamp labels will be horizontally aligned on the cell.
    case kBPNTimeStampCenterAligned
    ///  Timestamp libels will be shown at the left or right side of the bubble.
    case kBPNTimeStampSideAligned
}

enum MessageType : Int {
    case kBPNMessageMine
    case kBPNMessageSomeone
    case kBPNMessageTypingMine
    case kBPNMessageTypingSomeone
    case kBPNMessageStatus
}

protocol ChatAttachmentProtocol: NSObjectProtocol {
    var fileId: String? { get set }
    var data: Data? { get set }
    var uti: String? { get set }
    var as_attachment: Bool { get set }
}

protocol BPNChatProfileImageProtocol: NSObjectProtocol {
    var partyId: String? { get set }
    var data: Data? { get set }
}

protocol BPNChatMessageProtocol: NSObjectProtocol {
    var type: Int16 { get set }
    var text: String? { get set }
    var attachment: ChatAttachmentProtocol? { get set }
    var senderName: String? { get set }
    var time: Date? { get set }
    var profileImage: ChatProfileImageProtocol? { get set }
    var chatID: String? { get set }
}

protocol ChatBubbleCellDelegate: NSObjectProtocol {
    func bubbleCellImageTapped(_ cell: BPNChatBubbleCell?, containingMessage message: BPNChatMessageProtocol?)
}

class ChatBubbleCell: UITableViewCell {
    private let kMaxImageWidth: CGFloat = 180.0
    private let kNippleMarginX: CGFloat = 11.0
    private let kImageIndentY: CGFloat = 8.0
    private let kMyBubbleContentIndentX: CGFloat = 5.0
    private let kOtherBubbleContentIndentX: CGFloat = 10.0
    private let kContentIndentX: CGFloat = 5.0
    private let kContentIndentY: CGFloat = 16.0
    private let kAvatarMarginX: CGFloat = 2.0
    private let kAvatarMarginY: CGFloat = 4.0
    private let kTimeStampMarginY: CGFloat = 8.0
    private let kTimeStampMarginX: CGFloat = 4.0
    ///  Chat message
    var message: BPNChatMessageProtocol?
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
        p_setup()
    }

    func layoutSubviews() {
        super.layoutSubviews()

        p_resizeControls()
    }

    // MARK: - Properties
    func setMessage(_ message: BPNChatMessageProtocol?) {
        if self.message == message {
            return
        }

        //BOOL messageTypeDiffers = (_message.type != message.type);

        self.message = message
        messageLabel.text = self.message.text
        messageLabel.sizeToFit()

        nameLabel.text = self.message.senderName


        if self.message.attachment.data {
            if let uti = (self.message.attachment.uti) as? CFString? {
                if UTTypeConformsTo(uti, kUTTypeImage) {
                    let messageImage = UIImage(data: self.message.attachment.data)
                    messageImageView.image = messageImage
                    messageSize = BPNChatBubbleCell.p_sizeOf(messageImage)
                } else if UTTypeConformsTo(uti, kUTTypeMovie) {
                    messageImageView.image = videoFilePlaceholderImage
                    messageSize = BPNChatBubbleCell.p_sizeOfImage(videoFilePlaceholderImage)
                } else {
                    messageImageView.image = otherFilePlaceholderImage
                    messageSize = BPNChatBubbleCell.p_sizeOfImage(otherFilePlaceholderImage)
                }
            }
        } else {
            messageImageView.image = nil
            messageSize = BPNChatBubbleCell.p_calculateSizeOfMessage(
                message,
                messageFont: messageLabel.font,
                limitedByWidth: contentWidth)
        }
        if kBPNMessageMine == self.message.type {
            timeStampLabel.text = DateFormatter.localizedString(
                from: self.message.time,
                dateStyle: .medium,
                timeStyle: .short)
        }


        avatarImageView.image = avatarImage

        let center = CGPoint(x: bubbleImage.size.width / 2.0, y: bubbleImage.size.height / 2.0)
        let capInsets = UIEdgeInsets(top: center.y, left: center.x, bottom: center.y, right: center.x)

        bubbleImageView.image = bubbleImage.resizableImage(withCapInsets: capInsets,
                                                           resizingMode: UIImageResizingModeStretch)
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
        if self.avatarCornerRadius == avatarCornerRadius {
            return
        }
        self.avatarCornerRadius = avatarCornerRadius

        avatarImageView.layer.cornerRadius = self.avatarCornerRadius
        avatarImageView.layer.masksToBounds = true
        setNeedsLayout()
    }

    // MARK: - Public
    class func requiredHeight(
        forCellDisplayingMessage message: BPNChatMessageProtocol?,
        avatarHeight: CGFloat,
        videoFilePlaceholderImage: UIImage?,
        otherFilePlaceholderImage: UIImage?,
        messageFont: UIFont?,
        timeStamp timeStampFont: UIFont?,
        senderNameFont: UIFont?,
        timeStamp alignment: BPNTimeStampLabelAlignment,
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

        let avatarOffsetY = avatarHeight != 0.0 ? avatarHeight + kAvatarMarginY : 0.0

        var messageSize: CGSize

        if message?.attachment.data {
            if let uti = (message?.attachment.uti) as? CFString? {
                if UTTypeConformsTo(uti, kUTTypeImage) {
                    var messageImage: UIImage? = nil
                    if let data = message?.attachment.data {
                        messageImage = UIImage(data: data)
                    }
                    messageSize = Self.p_sizeOf(messageImage)
                } else if UTTypeConformsTo(uti, kUTTypeMovie) {
                    messageSize = Self.p_sizeOf(videoFilePlaceholderImage)
                } else {
                    messageSize = Self.p_sizeOf(otherFilePlaceholderImage)
                }
            }
        } else {
            messageSize = Self.p_calculateSizeOfMessage(
                message,
                messageFont: messageFont,
                limitedByWidth: width)
        }

        let height: CGFloat
        if kBPNTimeStampCenterAligned == alignment {
            height = ceilf(kTimeStampMarginY + timeStampHeight + CGFloat(max(messageSize.height, avatarOffsetY)) + userNameHeight) + kContentIndentY
        } else {
            height = ceilf(kTimeStampMarginY + max(timeStampHeight, max(messageSize.height, avatarOffsetY)) + userNameHeight)
        }
        return height
    }

    func p_resizeControls() {
        var messageFrame: CGRect

        var avatarOffsetX: CGFloat = 0.0
        //CGFloat labelOffset = kContentIndentX;
        if avatarImage {
            //labelOffset += kAvatarMarginX + _avatarSize;
            avatarOffsetX = avatarSize + kAvatarMarginX + 2 * kContentIndentX
        }

        let titleSize = BPNChatBubbleCell.p_calculateSizeOfText(
            message.senderName,
            usingFont: nameLabel.font,
            limitedByWidth: contentWidth)

        if kBPNMessageMine == message.type {
            let timeStampSize = p_timeStampSizeLimited(byWidth: frame.width)
            timeStampLabel.frame = CGRect(
                x: 0,
                y: 0,
                width: frame.width,
                height: timeStampSize.height)

            nameLabel.frame = CGRect(
                x: frame.width - titleSize.width - kContentIndentX,
                y: frame.height - titleSize.height + timeStampSize.height / 3 - kAvatarMarginY - kContentIndentY,
                width: titleSize.width,
                height: titleSize.height)
            messageLabel.changeTextColor(to: UIColor.white)

            if avatarImage {
                avatarImageView.frame = CGRect(
                    x: frame.width - kContentIndentX - avatarSize,
                    y: frame.height - titleSize.height - kAvatarMarginY - avatarSize - kContentIndentY,
                    width: avatarSize,
                    height: avatarSize)
            }

            bubbleImageView.frame = CGRect(
                x: frame.width - messageSize.width - avatarOffsetX - kContentIndentX,
                y: frame.height - titleSize.height - messageSize.height + timeStampSize.height / 2 - kContentIndentY,
                width: messageSize.width - kNippleMarginX,
                height: messageSize.height - kImageIndentY - 2.0)

            messageFrame = CGRect(
                x: bubbleImageView.frame.minX + kMyBubbleContentIndentX,
                y: bubbleImageView.frame.minY + kImageIndentY - 2.0,
                width: messageSize.width - 2 * kNippleMarginX,
                height: messageSize.height - 3 * kImageIndentY)
        } else {
            nameLabel.frame = CGRect(
                x: 3 * kContentIndentX + 2.0,
                y: frame.height - titleSize.height - kContentIndentY,
                width: titleSize.width,
                height: titleSize.height)
            messageLabel.changeTextColor(to: UIColor.black)

            if avatarImage {
                let avatarOffsetY: CGFloat = avatarSize + kAvatarMarginY
                avatarImageView.frame = CGRect(
                    x: 3 * kContentIndentX,
                    y: frame.height - titleSize.height - avatarOffsetY - kContentIndentY,
                    width: avatarSize,
                    height: avatarSize)
            }

            bubbleImageView.frame = CGRect(
                x: avatarOffsetX + 3 * kContentIndentX + 2.0,
                y: frame.height - titleSize.height - messageSize.height - kContentIndentY,
                width: messageSize.width - kNippleMarginX,
                height: messageSize.height - kImageIndentY - 2.0)

            messageFrame = CGRect(
                x: bubbleImageView.frame.minX + kOtherBubbleContentIndentX,
                y: bubbleImageView.frame.minY + kImageIndentY - 2.0,
                width: messageSize.width - 2.0 * kNippleMarginX,
                height: messageSize.height - 3.0 * kImageIndentY)

            if kBPNTimeStampCenterAligned == timeStampLabelAlignment {
                let timeStampSize = p_timeStampSizeLimited(byWidth: frame.width)
                timeStampLabel.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: frame.width,
                    height: timeStampSize.height)
            } else {
                let timeStampSize = p_timeStampSizeLimited(byWidth: frame.width - bubbleImageView.frame.width - kTimeStampMarginX)

                timeStampLabel.frame = CGRect(
                    x: bubbleImageView.frame.minX + bubbleImageView.frame.width + kTimeStampMarginX,
                    y: bubbleImageView.frame.minY,
                    width: timeStampSize.width,
                    height: timeStampSize.height)
            }
        }

        if message.attachment.data != nil {
            messageImageView?.frame = messageFrame
            messageLabel.hidden = true
            messageImageView?.isHidden = false
            bubbleImageView?.image = nil
        } else {
            messageLabel.frame = messageFrame
            messageLabel.hidden = false
            messageImageView?.isHidden = true
        }
    }

    func p_handleImageTap(_ recognizer: UITapGestureRecognizer?) {
        delegate.bubbleCellImageTapped(self, containingMessage: message)
    }

    class func p_sizeOf(_ image: UIImage?) -> CGSize {
        let size = image?.size
        if (size?.width ?? 0.0) > kMaxImageWidth {
            size?.height /= (size?.width ?? 0.0) / kMaxImageWidth
            size?.width = kMaxImageWidth
        }
        return size ?? CGSize.zero
    }

    func p_timeStampSizeLimited(byWidth limitWidth: CGFloat) -> CGSize {
        if !timeStampLabel.text.length || timeStampLabel.hidden {
            return CGSize.zero
        }

        let timeStampSize = timeStampLabel.text.boundingRect(
            with: CGSize(width: frame.width, height: limitWidth),
            options: .usesLineFragmentOrigin,
            attributes: [
                NSAttributedString.Key.font: timeStampLabel.font
            ],
            context: nil).size

        return CGSize(width: ceilf(timeStampSize.width), height: ceilf(timeStampSize.height + kTimeStampMarginY))
    }

    func p_setupCell() {
        selectionStyle = EKCalendarChooserSelectionStyle(rawValue: UITableViewCell.SelectionStyle.none.rawValue)
        backgroundColor = UIColor.clear

        messageLabel = BPNLinkLabel(frame: CGRect.zero)
        messageLabel.isUserInteractionEnabled = true
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.backgroundColor = UIColor.clear

        nameLabel = UILabel(frame: CGRect.zero)
        nameLabel.backgroundColor = UIColor.clear

        timeStampLabel = UILabel(frame: CGRect.zero)
        timeStampLabel.backgroundColor = UIColor.clear
        timeStampLabel.textAlignment = .center
        timeStampLabel.lineBreakMode = .byWordWrapping
        timeStampLabel.numberOfLines = 0

        bubbleImageView = UIImageView(frame: CGRect.zero)
        avatarImageView = UIImageView(frame: CGRect.zero)
        messageImageView = UIImageView(frame: CGRect.zero)
        messageImageView.layer.cornerRadius = 5.0
        messageImageView.layer.masksToBounds = true
        messageImageView.isUserInteractionEnabled = true

        contentView.addSubview(bubbleImageView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(messageImageView)
        contentView.addSubview(messageLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeStampLabel)

        bubbleImageView.isUserInteractionEnabled = false
        contentView.bringSubviewToFront(messageLabel)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(p_handleImageTap(_:)))
        messageImageView.addGestureRecognizer(tapRecognizer)
    }

    // MARK: - Private
    class func p_calculateSizeOfMessage(
        _ message: BPNChatMessageProtocol?,
        messageFont: UIFont?,
        limitedByWidth width: CGFloat
    ) -> CGSize {
        let labelSize = BPNChatBubbleCell.p_calculateSizeOfText(
            message?.text,
            using: messageFont,
            limitedByWidth: width)

        let messageSize = CGSize(
            width: ceilf(labelSize.width) + 2.0 * kNippleMarginX,
            height: ceilf(labelSize.height) + 3.0 * kImageIndentY)

        return messageSize
    }

    class func p_calculateSizeOfText(_ text: String?, using font: UIFont?, limitedByWidth width: CGFloat) -> CGSize {
        if text == nil || font == nil {
            return CGSize.zero
        }

        var size: CGSize? = nil
        if let font = font {
            size = text?.boundingRect(
                with: CGSize(width: width, height: CGFLOAT_MAX),
                options: .usesLineFragmentOrigin,
                attributes: [
                    NSAttributedString.Key.font: font
                ],
                context: nil).size
        }

        return CGSize(width: ceilf(size?.width) + 14.0, height: ceilf(size?.height))
    }

    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
    }
}
