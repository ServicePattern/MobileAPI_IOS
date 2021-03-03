//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation
import UIKit

class LinkDetectorTextStorage: NSTextStorage {
    var linkRanges = [NSTextCheckingResult]()
    private let impl: NSMutableAttributedString
    private lazy var linkDetector: NSDataDetector = {
        do {
            return try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        } catch {
            fatalError("Cannot create data detector")
        }
    }()

    override var string: String {
        impl.string
    }

    var attributedString: NSAttributedString {
        get {
            impl
        }
        set {
            let oldLength = impl.length
            beginEditing()
            impl.setAttributedString(newValue)
            let range = NSMakeRange(0, oldLength)
            edited(.editedCharacters, range: range, changeInLength: newValue.length - oldLength)
            edited(.editedAttributes, range: NSMakeRange(0, newValue.length), changeInLength: 0)
            linkRanges.removeAll()
            p_detectLinks(in: NSMakeRange(0, newValue.length))
            endEditing()
        }
    }

    override var length: Int {
        impl.length
    }

    override init() {
        impl = NSMutableAttributedString()
        super.init()
    }

    //- (instancetype)initWithAttributedString:(NSAttributedString *)attrStr;
    override init(attributedString attrStr: NSAttributedString) {
        let impl = NSMutableAttributedString()
        impl.setAttributedString(attrStr)
        self.impl = impl
        super.init()
        p_detectLinks(in: NSMakeRange(0, attrStr.length))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Overrides
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        impl.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()

        impl.replaceCharacters(in: range, with: str)

        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
        let paragaphRange = (string as NSString).paragraphRange(for: NSMakeRange(range.location, str.count))
        p_detectLinks(in: paragaphRange)
        endEditing()
    }

    override func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        beginEditing()
        let str = attrString.string

        impl.replaceCharacters(in: range, with: attrString)
        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
        let paragaphRange = (string as NSString).paragraphRange(for: NSMakeRange(range.location, str.count))
        p_detectLinks(in: paragaphRange)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        impl.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
    }

    override func addAttributes(_ attrs: [NSAttributedString.Key : Any] = [:], range: NSRange) {
        beginEditing()
        impl.addAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func addAttribute(_ name: NSAttributedString.Key, value: Any, range: NSRange) {
        beginEditing()
        impl.addAttribute(name, value: value, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func removeAttribute(_ name: NSAttributedString.Key, range: NSRange) {
        beginEditing()
        impl.removeAttribute(name, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    //MARK:- Private
    func p_detectLinks(in range: NSRange) {
        linkDetector.enumerateMatches(in: string, options: [], range: range) { (result, flags, stop) in
            guard let result = result, let url = result.url else {
                return
            }
            addAttribute(.link,
                         value: url,
                         range: result.range)
            addAttribute(.foregroundColor,
                         value: UIColor.blue,
                         range: result.range)
            addAttribute(.underlineStyle,
                         value: NSUnderlineStyle.styleSingle,
                         range: result.range)
            linkRanges.append(result)
        }
    }
}
