//
//  ViewController.swift
//  BPContactCenter
//
//  Created by BrightPattern on 02/12/2021.
//  Copyright (c) 2021 BrightPattern. All rights reserved.
//

import UIKit
import BPContactCenter

class HelpRequestViewController: ViewController, ServiceDependencyProviding {
    var service: ServiceDependencyProtocol?
    var bundleIdentifier: String = Bundle.main.bundleIdentifier ?? ""
    @IBOutlet weak var pastConversationsBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    
    private lazy var viewModel: HelpRequestViewModel = {
        guard let service = service else {
            fatalError("Contact center service is not set")
        }

        return HelpRequestViewModel(service: service)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isNavigationBarHidden = true
        setupViews()
        setupSubscriptions()
    }

    private func setupViews() {
        let backgroundImage = appDelegate.window?.frame.size.height ?? 0 > 568 ? UIImageView(image: #imageLiteral(resourceName: "splash-screen-tall")) : UIImageView(image: #imageLiteral(resourceName: "splash-screen-short"))
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImage)
        view.sendSubview(toBack: backgroundImage)
        NSLayoutConstraint.activate([
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupSubscriptions() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = true
    }

    @IBAction func helpMePressed(_ sender: UIButton) {
        viewModel.helpMePressed()
    }

    @objc
    private func keyboardWillShow(notification: Notification) {
        // Get keyboard size and location
        guard let keyboardBoundsGlobal = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
              let curveValue = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber,
              let curve = UIViewAnimationCurve(rawValue: curveValue.intValue) else {
            return
        }
        // Need to translate the bounds to account for rotation.
        let keyboardBounds = view.convert(keyboardBoundsGlobal, to: nil)
        // get a rect for the textView frame
        let containerFrame = textView.convert(textView.frame, to: view)
        let diff = keyboardBounds.origin.y - containerFrame.maxY
        if diff < 10 {
            self.pastConversationsBottomConstraint.constant += 10 - diff
        }
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(duration.doubleValue)
        UIView.setAnimationCurve(curve)
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }

    private func resetBottomSpace() {
        pastConversationsBottomConstraint.constant = viewModel.bottomSpace
    }

    @objc
    private func keyboardWillHide(notification: Notification) {
        guard let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber,
              let curveValue = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber,
              let curve = UIViewAnimationCurve(rawValue: curveValue.intValue) else {
            return
        }

        resetBottomSpace()

        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(duration.doubleValue)
        UIView.setAnimationCurve(curve)
        view.layoutIfNeeded()
        UIView.commitAnimations()
    }
}
