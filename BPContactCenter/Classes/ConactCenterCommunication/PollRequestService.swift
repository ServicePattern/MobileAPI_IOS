//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

protocol PollRequestServiceable {
    var currentChatID: String? { get set }
    var delegate: ContactCenterEventsDelegating? { get set }
}

// MARK: - Poll action
class PollRequestService: PollRequestServiceable {
    internal let pollInterval: Double
    private var currentChatIDValue: String?
    internal var currentChatID: String? {
        get {
            readerWriterQueue.sync {
                currentChatIDValue
            }
        }
        set {
            readerWriterQueue.async(flags: .barrier) { [weak self] in
                self?.currentChatIDValue = newValue
                self?.startPollingIfNeeded()
            }
        }
    }

    private var isForegroundValue: Bool = true
    internal var isForeground: Bool {
        get {
            readerWriterQueue.sync {
                isForegroundValue
            }
        }
        set {
            readerWriterQueue.async(flags: .barrier) { [weak self] in
                self?.isForegroundValue = newValue
                self?.startPollingIfNeeded()
            }
            startOrStopReachability(start: newValue)
        }
    }
    internal var pollRequestDataTask: URLSessionDataTask?
    private let readerWriterQueue = DispatchQueue(label: "com.BPContactCenter.PollRequestServiceable.reader-writer", attributes: .concurrent)
    internal let pollRequestQueue = DispatchQueue(label: "com.BPContactCenter.pollRequestQueue")
    private let networkService: NetworkServiceable
    internal weak var httpRequestBuilder: HttpRequestBuilding?
    internal weak var delegate: ContactCenterEventsDelegating?
    private let reachability: Reachability

    init(networkService: NetworkServiceable, pollInterval: Double) {
        self.networkService = networkService
        self.pollInterval = pollInterval
        do {
            self.reachability = try Reachability()
        } catch {
            fatalError("Failed to initialize reachability: \(error)")
        }

        subscribeToNotifications()
        setupReachability()
    }

    // MARK:- Deinitialization part
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Make sure to access pollRequestDataTask from the same queue it was set before
        pollRequestQueue.sync {
            pollRequestDataTask?.cancel()
        }
    }

    private func pollAction() {
        /// - Note: Make sure that this function is called from pollRequestQueue!!!
        do {
            guard let currentChatID = currentChatID else {
                log.debug("Poll requested when current chatID is nil")
                return
            }
            guard pollRequestDataTask == nil else {
                log.debug("There is already poll task running")
                return
            }
            guard let urlRequest = try httpRequestBuilder?.httpGetRequest(with: .getNewChatEvents(chatID: currentChatID)) else {
                log.error("Failed to create URL request")

                throw ContactCenterError.failedToCreateURLRequest
            }
            pollRequestDataTask = networkService.dataTask(using: urlRequest) { [weak self] (result: Result<ContactCenterEventsContainerDto, Error>) -> Void in
                self?.pollRequestQueue.sync {
                    self?.pollRequestDataTask = nil
                }
                switch result {
                case .success(let eventsContainer):
                    //  Report received server events to the application
                    self?.delegate?.chatSessionEvents(events: .success(eventsContainer.events))
                    //  Reset currentChatID to stop polling timer if session has ended
                    for e in eventsContainer.events {
                        switch e {
                        case .chatSessionEnded:
                            self?.currentChatID = nil
                            break
                        default:()
                        }
                    }
                    // Check and start new getNewChatEvents request if needed
                    self?.startPollingIfNeeded()
                case .failure(let error):
                    if let contactCenterError = error as? ContactCenterError,
                       case .chatSessionNotFound = contactCenterError {
                        // If the backend says that a chat id does not exist then forget it
                        self?.currentChatID = nil
                    }
                }
            }
        } catch {
            log.error("Failed to send poll request: \(error)")
            // If fails re-try polling request
            startPollingIfNeeded()
        }
    }

    private func startPolling() {
        pollRequestQueue.asyncAfter(deadline: .now() + pollInterval) { [weak self] in
            self?.pollAction()
        }
    }

    private func stopPolling() {
        pollRequestQueue.async { [weak self] in
            self?.pollRequestDataTask?.cancel()
            self?.pollRequestDataTask = nil
        }
    }

    internal func startPollingIfNeeded() {
        pollRequestQueue.async { [weak self] in
            if self?.isForeground == true && self?.currentChatID != nil {
                self?.startPolling()
            } else {
                self?.stopPolling()
            }
        }
    }
}

// MARK:- Background/foreground notifications subscribtion
extension PollRequestService {
    private func subscribeToNotifications() {
        // Restore a poll action when the app is going to go the foreground
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: .UIApplicationWillEnterForeground,
                                               object: nil)
        // Pause a poll action after the app goes to the background
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
    }

    @objc private func willEnterForeground() {
        self.isForeground = true
    }

    @objc private func didEnterBackground() {
        self.isForeground = false
    }
}

// MARK:- Network reachability
extension PollRequestService {
    private func setupReachability() {
        reachability.whenReachable = { [weak self] reachability in
            log.debug("Start polling if needed because network became reachable: \(reachability)")
            self?.startPollingIfNeeded()
        }
        reachability.whenUnreachable = { [weak self] reachability in
            log.debug("Stop polling because network is unreachable: \(reachability)")
            self?.stopPolling()
        }
        startOrStopReachability(start: true)
    }

    private func startOrStopReachability(start: Bool) {
        if start {
            do {
                try reachability.startNotifier()
                log.debug("Reachability notifications started")
            } catch {
                log.error("Failed to start reachability notifications:\(error)")
            }
        } else {
            reachability.stopNotifier()
            log.debug("Reachability notifications stopped")
        }
    }
}
