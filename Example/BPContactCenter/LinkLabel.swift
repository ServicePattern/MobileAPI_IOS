//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation
import UIKit

protocol LinkLabelDelegate: class {
    func didTappedAtLink(_ linkLabel: LinkLabel, link: NSTextCheckingResult)
}

class LinkLabel: UILabel {
    weak var delegate: LinkLabelDelegate?
    let layoutManager: NSLayoutManager
    let textContainer: NSTextContainer
    let textStorage: BPNLinkDetectorTextStorage

    func changeTextColorTo(color: UIColor) {
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        p_configureTextKit()
    }

    override required init?(coder: NSCoder) {
        super.init(coder: coder)

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
        let glyphRange = layoutManager?.glyphRange(for: textContainer)
        textOffset = p_calcTextOffset(forGlyphRange: glyphRange)

        // Drawing code
        if let glyphRange = glyphRange {
            layoutManager?.drawBackground(forGlyphRange: glyphRange, at: textOffset)
            layoutManager?.drawGlyphs(forGlyphRange: glyphRange, at: textOffset)
        }
    }
}
