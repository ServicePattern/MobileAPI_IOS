//
//  ViewController.swift
//  BPMobileMessaging
//
//  Created by BrightPattern on 02/12/2021.
//  Copyright (c) 2021 BrightPattern. All rights reserved.
//

import UIKit

class HelpRequestViewController: ViewController, ServiceDependencyProviding {
    var service: ServiceDependencyProtocol?
    var bundleIdentifier: String = Bundle.main.bundleIdentifier ?? ""
    @IBOutlet weak var pastConversationsBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var problemDescription: UITextView!
    @IBOutlet weak var helpMeButton: UIButton!
    @IBOutlet weak var caseNumber: UITextField!
    
    private lazy var viewModel: HelpRequestViewModel = {
        guard let service = service else {
            fatalError("Contact center service is not set")
        }

        let viewModel = HelpRequestViewModel(service: service)
        viewModel.delegate = self
        return viewModel
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isNavigationBarHidden = true
        setupViews()
        setupSubscriptions()
        update()
    }

    private func setupViews() {
        let backgroundImage = appDelegate.window?.frame.size.height ?? 0 > 568 ? UIImageView(image: #imageLiteral(resourceName: "splash-screen-tall")) : UIImageView(image: #imageLiteral(resourceName: "splash-screen-short"))
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImage)
        view.sendSubviewToBack(backgroundImage)
        NSLayoutConstraint.activate([
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        backgroundImage.isUserInteractionEnabled = true
        backgroundImage.addGestureRecognizer(tapGesture)
        problemDescription.backgroundColor = .white
//        textView.attributedPlaceholder = NSAttributedString(string: "Type your message here",
//                                                            attributes: [NSAttributedStringKey.font: textView.font,
//                                                                         NSAttributedStringKey.foregroundColor: UIColor.lightGray])
    }

    private func setupSubscriptions() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = true
    }

    @IBAction func helpMePressed(_ sender: UIButton) {
        viewModel.helpMePressed(problemDescription: problemDescription.text, caseNumber: caseNumber.text ?? "")
    }

    @objc
    private func handleImageTap(_ sender: UITapGestureRecognizer) {
        problemDescription.resignFirstResponder()
    }

    @objc
    private func keyboardWillShow(notification: Notification) {
        // Get keyboard size and location
        guard let keyboardBoundsGlobal = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
              let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber,
              let curve = UIView.AnimationCurve(rawValue: curveValue.intValue) else {
            return
        }
        // Need to translate the bounds to account for rotation.
        let keyboardBounds = view.convert(keyboardBoundsGlobal, to: nil)
        // get a rect for the textView frame
        let containerFrame = problemDescription.frame
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
//        pastConversationsBottomConstraint.constant = viewModel.bottomSpace
    }

    @objc
    private func keyboardWillHide(notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
              let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber,
              let curve = UIView.AnimationCurve(rawValue: curveValue.intValue) else {
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let chatVC = segue.destination as? ChatViewController {
            chatVC.currentChatID = viewModel.currentChatID
        }
    }

    @IBAction func unwind(_ segue: UIStoryboardSegue) {
    }
}

extension HelpRequestViewController: HelpRequestUpdatable {
    func update() {
        helpMeButton.isEnabled = viewModel.isChatAvailable
    }

    func showChat() {
        performSegue(withIdentifier: "\(ChatViewController.self)", sender: self)
    }
}
