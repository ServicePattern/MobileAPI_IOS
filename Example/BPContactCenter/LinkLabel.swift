//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation
import UIKit

protocol LinkLabelDelegate: class {
    func didTapped(at linkLabel: LinkLabel, link: NSTextCheckingResult)
}

class LinkLabel: UILabel {
    weak var delegate: LinkLabelDelegate?
    var layoutManager = NSLayoutManager()
    var textContainer = NSTextContainer()
    var textStorage = LinkDetectorTextStorage()

    override var numberOfLines: Int {
        didSet {
            self.textContainer.maximumNumberOfLines = numberOfLines
        }
    }

    override var text: String? {
        didSet {
            let textString: String = text ?? ""
            let attributedText = NSAttributedString(string: textString, attributes: p_attributesFromProperties())
            self.textStorage.attributedString = attributedText
        }
    }

    override var attributedText: NSAttributedString? {
        didSet {
            guard let attributedText = attributedText else {
                return
            }
            self.textStorage.attributedString = attributedText
        }
    }

    override var frame: CGRect {
        didSet {
            self.textContainer.size = self.bounds.size;
        }
    }

    override var bounds: CGRect {
        didSet {
            self.textContainer.size = self.bounds.size;
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        p_configureTextKit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        p_configureTextKit()
    }

    func changeTextColor(to color: UIColor) {
        self.textColor = color
        p_configureTextKit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.textContainer.size = self.bounds.size
    }

    override func drawText(in rect: CGRect) {
        // Don't call super implementation. Might want to uncomment this out when
        // debugging layout and rendering problems.
        //        [super drawTextInRect:rect];

        // Calculate the offset of the text in the view
        var textOffset: CGPoint
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        textOffset = p_calcTextOffset(for: glyphRange)

        // Drawing code
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: textOffset)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: textOffset)
    }

    //MARK: - Interactions
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard let touchLocation = touches.randomElement()?.location(in: self) else {
            super.touchesBegan(touches, with: event)
            return
        }

        if let touchedLink = p_getLinkAtLocation(at: touchLocation) {
            delegate?.didTapped(at: self, link: touchedLink)
        } else {
            super.touchesBegan(touches, with: event)
        }
    }

    //MARK: - Private
    func p_configureTextKit() {
        //   self.userInteractionEnabled = YES;

        let textContainer = NSTextContainer()
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        textContainer.size = frame.size
        self.textContainer = textContainer

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        self.layoutManager = layoutManager

        if let attributedText = attributedText {
            let textStorage = LinkDetectorTextStorage(attributedString: attributedText)
            textStorage.addLayoutManager(layoutManager)
            layoutManager.textStorage = textStorage
            self.textStorage = textStorage

            super.attributedText = textStorage.attributedString
        } else {
            super.attributedText = nil
        }
    }

    // Returns the XY offset of the range of glyphs from the view's origin
    func p_calcTextOffset(for glyphRange: NSRange) -> CGPoint {
        var textOffset = CGPoint.zero

        let textBounds = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let paddingHeight = (bounds.size.height - textBounds.size.height) / 2.0
        if paddingHeight > 0 {
            textOffset.y = paddingHeight
        }

        return textOffset
    }

    func p_attributesFromProperties() -> [NSAttributedString.Key : Any]? {
        let shadow = NSShadow()
        if let shadowColor = shadowColor {
            shadow.shadowColor = shadowColor
            shadow.shadowOffset = shadowOffset
        } else {
            shadow.shadowOffset = CGSize(width: 0, height: -1)
            shadow.shadowColor = nil
        }

        let colour = textColor
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = textAlignment

        var attributes: [NSAttributedString.Key : Any]? = nil
        if let colour = colour, let font = font {
            attributes = [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: colour,
                NSAttributedString.Key.shadow: shadow,
                NSAttributedString.Key.paragraphStyle: paragraph
            ]
        }
        return attributes
    }

    func p_getLinkAtLocation(at location: CGPoint) -> NSTextCheckingResult? {
        guard self.textStorage.string.count > 0 else {
            return nil
        }

        // Work out the offset of the text in the view
        let glyphRange = layoutManager.glyphRange(for: self.textContainer)
        let textOffset = p_calcTextOffset(for: glyphRange)

        // Get the touch location and use text offset to convert to text container coords
        // use offset here cause we used it in drawTextInRect
        let locationWithOffset = CGPoint(x: location.x - textOffset.x,
                                         y: location.y - textOffset.y)

        let touchedChar = layoutManager.glyphIndex(for: locationWithOffset, in: textContainer)

        // If the touch is in white space after the last glyph on the line we don't
        // count it as a hit on the text
        var lineRange = NSRange()
        let lineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: touchedChar, effectiveRange: &lineRange)
        if lineRect.contains(location) == false {
            return nil
        }
        // Find the word that was touched and call the detection block
        for result in self.textStorage.linkRanges {
            let range = result.range
            if (touchedChar >= range.location) &&
                    (touchedChar < (range.location + range.length)) {
                return result
            }
        }
        return nil
    }
}
