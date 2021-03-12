//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

protocol PollRequestServiceable {
    var delegate: ContactCenterEventsDelegating? { get set }
    func addChatID(_ chatID: String)
}

// MARK: - Poll action
class PollRequestService: PollRequestServiceable {
    internal let pollInterval: Double
    private var chatIDsValue = Set<String>()
    private var chatIDs: Set<String> {
        get {
            readerWriterQueue.sync {
                chatIDsValue
            }
        }
        set {
            readerWriterQueue.async(flags: .barrier) { [weak self] in
                guard self?.chatIDsValue != newValue else {
                    log.debug("No changes made to chatIDs, so don't stop poll action")
                    return
                }
                self?.chatIDsValue = newValue
                // Wait until all network tasks have finished
                self?.stopPolling(synchronously: true)
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
    internal var pollRequestDataTask = Set<URLSessionDataTask>()
    private let readerWriterQueue = DispatchQueue(label: "com.BPMobileMessaging.PollRequestServiceable.reader-writer", attributes: .concurrent)
    internal let pollRequestQueue = DispatchQueue(label: "com.BPMobileMessaging.pollRequestQueue")
    private let networkService: NetworkServiceable
    internal weak var httpRequestBuilder: HttpRequestBuilding?
    internal weak var delegate: ContactCenterEventsDelegating?
    private let reachability: Reachability
    private let pollActionHttpRequestLock = NSLock()

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
        // Make sure that no additional poll request will be made by cleaning up all chat IDs
        chatIDs.removeAll()
        stopPolling(synchronously: true)
    }

    func addChatID(_ chatID: String) {
        chatIDs.insert(chatID)
    }

    private func pollAction() {
        /// - Note: Make sure that this function is called from pollRequestQueue!!!
        guard let httpRequestBuilder = httpRequestBuilder else {
            fatalError("httpRequestBuilder is not set")
        }
        guard pollActionHttpRequestLock.try() else {
            log.debug("Skip poll request because another is in progress")
            return
        }
        do {
            guard chatIDs.count > 0 else {
                log.debug("Skip poll request because there are no chatIDs")
                return
            }
            let urlRequestsWithChatIDs = try chatIDs.map { chatID in
                (try httpRequestBuilder.httpGetRequest(with: .getNewChatEvents(chatID: chatID)), chatID)
            }
            let pollRequestsGroup = DispatchGroup()
            pollRequestDataTask = Set(urlRequestsWithChatIDs.map { urlRequest, chatID in
                pollRequestsGroup.enter()
                return networkService.dataTask(using: urlRequest) { [weak self] (result: Result<ContactCenterEventsContainerDto, Error>) -> Void in
                    guard let self = self else { return }
                    switch result {
                    case .success(let eventsContainer):
                        //  Report received server events to the application
                        self.delegate?.chatSessionEvents(result: .success(eventsContainer.events))
                        //  Reset currentChatID to stop polling timer if session has ended
                        for e in eventsContainer.events {
                            switch e {
                            case .chatSessionEnded:
                                self.chatIDs.remove(chatID)
                                break
                            default:()
                            }
                        }
                    case .failure(let error):
                        if let contactCenterError = error as? ContactCenterError,
                           case .chatSessionNotFound = contactCenterError {
                            // If the backend says that a chat id does not exist then remove it
                            // To prevent another poll request with this chatID
                            self.chatIDs.remove(chatID)
                        }
                    }
                    // Check and start new getNewChatEvents request if needed
                    self.startPollingIfNeeded()
                    pollRequestsGroup.leave()
                }
            })
            pollRequestsGroup.wait()
            // All network tasks have been finished, so unlock a mutex to allow another poll action
            self.pollActionHttpRequestLock.unlock()
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

    private func stopPolling(synchronously: Bool = false) {
        let stopPollingBlock = { [weak self] in
            guard let self = self else { return }
            self.pollRequestDataTask.forEach { $0.cancel() }
            self.pollRequestDataTask.removeAll()
        }
        if synchronously {
            pollRequestQueue.sync(execute: stopPollingBlock)
        } else {
            pollRequestQueue.async(execute: stopPollingBlock)
        }
    }

    internal func startPollingIfNeeded() {
        pollRequestQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isForeground == true && self.chatIDs.count > 0 {
                self.startPolling()
            } else {
                self.stopPolling()
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
