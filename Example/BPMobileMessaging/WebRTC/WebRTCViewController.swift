//
//  WebRTCViewController.swift
//  BPMobileMessaging_Example
//
//  Created by Artem Mkrtchyan on 4/24/23.
//  Copyright © 2023 BrightPattern. All rights reserved.
//

import UIKit
import WebRTC


class WebRTCViewController: UIViewController, ServiceDependencyProviding, WebRTCViewModelUpdatable {
    var service: ServiceDependencyProtocol?
    var offerSDP: String?
    var currentChatID: String?
    var partyID: String?
    lazy var viewModel: WebRTCViewModel = {
        guard let service = service, let currentChatID = currentChatID , let partyID = partyID else {
            fatalError("WebRTCViewModel parameters empty")
        }
        return WebRTCViewModel(service: service, currentChatID: currentChatID, partyID: partyID)
    }()
    
    //MARK: - Properties

    
    // Constants
    let likeStr: String = "Like"
    
    // UI
    var wsStatusLabel: UILabel!
    var webRTCStatusLabel: UILabel!
    var webRTCMessageLabel: UILabel!
    var likeImage: UIImage!
    var likeImageViewRect: CGRect!
    
    //MARK: - ViewController Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        #if targetEnvironment(simulator)
        // simulator does not have camera
//        self.useCustomCapturer = false
        #endif
        
        viewModel.setupAPI()
        viewModel.delegate = self
        if let offerSDP = offerSDP {
            viewModel.receiveOffer(offerSDP: RTCSessionDescription(type: .offer, sdp: offerSDP))
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goBack() {
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UI
    private func setupUI(){
        let remoteVideoViewContainter = UIView(frame: CGRect(x: 0, y: 0, width: ScreenSizeUtil.width(), height: ScreenSizeUtil.height()*0.7))
        remoteVideoViewContainter.backgroundColor = .gray
        self.view.addSubview(remoteVideoViewContainter)
        
        let remoteVideoView = viewModel.webRTCClient.remoteVideoView()
        viewModel.webRTCClient.setupRemoteViewFrame(frame: CGRect(x: 0, y: 0, width: ScreenSizeUtil.width()*0.9, height: ScreenSizeUtil.height()*0.9))
        remoteVideoView.center = remoteVideoViewContainter.center
        remoteVideoViewContainter.addSubview(remoteVideoView)
        
        let localVideoView = viewModel.webRTCClient.localVideoView()
        viewModel.webRTCClient.setupLocalViewFrame(frame: CGRect(x: 0, y: 0, width: ScreenSizeUtil.width()/3, height: ScreenSizeUtil.height()/3))
        localVideoView.center.y = self.view.center.y
        localVideoView.subviews.last?.isUserInteractionEnabled = true
        self.view.addSubview(localVideoView)
        
        let localVideoViewButton = UIButton(frame: CGRect(x: 0, y: 0, width: localVideoView.frame.width, height: localVideoView.frame.height))
        localVideoViewButton.backgroundColor = UIColor.clear
        localVideoViewButton.addTarget(self, action: #selector(self.localVideoViewTapped(_:)), for: .touchUpInside)
        localVideoView.addSubview(localVideoViewButton)
        
        
        wsStatusLabel = UILabel(frame: CGRect(x: 0, y: remoteVideoViewContainter.bottom, width: ScreenSizeUtil.width(), height: 30))
        wsStatusLabel.textAlignment = .center
        self.view.addSubview(wsStatusLabel)
        webRTCStatusLabel = UILabel(frame: CGRect(x: 0, y: wsStatusLabel.bottom, width: ScreenSizeUtil.width(), height: 30))
        webRTCStatusLabel.textAlignment = .center
        webRTCStatusLabel.text = "initialized"
        self.view.addSubview(webRTCStatusLabel)
        webRTCMessageLabel = UILabel(frame: CGRect(x: 0, y: webRTCStatusLabel.bottom, width: ScreenSizeUtil.width(), height: 30))
        webRTCMessageLabel.textAlignment = .center
        webRTCMessageLabel.textColor = .black
        self.view.addSubview(webRTCMessageLabel)
        
        let hangupButton = UIButton(frame: CGRect(x: 0, y: 0, width: ScreenSizeUtil.width()*0.8, height: 60))
        hangupButton.setBackgroundImage(UIColor.red.rectImage(width: hangupButton.frame.width, height: hangupButton.frame.height), for: .normal)
        hangupButton.layer.cornerRadius = 30
        hangupButton.layer.masksToBounds = true
        hangupButton.center.x = ScreenSizeUtil.width()/2
        hangupButton.center.y = webRTCStatusLabel.bottom + (ScreenSizeUtil.height() - webRTCStatusLabel.bottom)/2
        hangupButton.setTitle("hang up" , for: .normal)
        hangupButton.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        hangupButton.addTarget(self, action: #selector(self.hangupButtonTapped(_:)), for: .touchUpInside)
        self.view.addSubview(hangupButton)
    }
    
    // MARK: - UI Events

    
    @objc func hangupButtonTapped(_ sender: UIButton){
        viewModel.disconnect()
    }
    
    @objc func localVideoViewTapped(_ sender: UITapGestureRecognizer) {
        viewModel.webRTCClient.switchCameraPosition()
    }
    
    private func startLikeAnimation(){
        let likeImageView = UIImageView(frame: likeImageViewRect)
        likeImageView.backgroundColor = UIColor.clear
        likeImageView.contentMode = .scaleAspectFit
        likeImageView.image = likeImage
        likeImageView.alpha = 1.0
        self.view.addSubview(likeImageView)
        UIView.animate(withDuration: 0.5, animations: {
            likeImageView.alpha = 0.0
        }) { (reuslt) in
            likeImageView.removeFromSuperview()
        }
    }
      
}
