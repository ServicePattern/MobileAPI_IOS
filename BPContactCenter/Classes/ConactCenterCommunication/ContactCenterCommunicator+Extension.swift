//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

// MARK: - Poll action
extension ContactCenterCommunicator {
    private func pollAction() {
        do {
            guard let currentChatID = currentChatID else {
                log.debug("Poll requested when current chatID is nil")
                return
            }
            let urlRequest = try httpGetRequest(with: .getNewChatEvents(chatID: currentChatID))
            pollRequestDataTask = networkService.dataTask(using: urlRequest) { [weak self] (result: Result<ContactCenterEventsContainerDto, Error>) -> Void in
                switch result {
                case .success(let eventsContainer):
                    //  Report received server events to the application
                    self?.delegate?(.success(eventsContainer.events))
                    //  Stop polling timer if session has ended; otherwise need to start new getNewChatEvents request
                    for e in eventsContainer.events {
                        switch e {
                        case .chatSessionEnded:
                            self?.currentChatID = nil
                            break
                        default:()
                        }
                    }
                default:
                    break
                }
            }
        } catch {
            log.error("Failed to send poll request: \(error)")
            // If fails re-try polling request
            startPolling()
        }
    }

    /// Stop a poll request and a timer
    /// The reason why to use a Timer is to be able to cancel it if the app goes to the background or the session ends
    private func setupPollTimer() {
        guard pollTimer == nil else {
            log.debug("Timer already set")
            return
        }
        let timer =  Timer(timeInterval: self.pollInterval, repeats: false) { [weak self] _ in
            self?.pollAction()
        }
        // Allow a timer to run when a UI thread block execution
        RunLoop.current.add(timer, forMode: .commonModes)
        // Gives OS a chance to safe a battery life
        timer.tolerance = Self.timerTolerance

        pollTimer = timer
    }

    internal func invalidatePollTimer() {
        self.pollRequestDataTask?.cancel()
        self.pollTimer?.invalidate()
        self.pollTimer = nil
    }

    private func startPolling() {
        guard self.currentChatID != nil else {
            log.debug("Poll requested when current chatID is nil")
            return
        }
        self.setupPollTimer()
    }

    private func stopPolling() {
        self.invalidatePollTimer()
    }

    internal func startPollingIfNeeded() {
        // Make sure that a timer is scheduled and invalidated on the same thread
        DispatchQueue.main.async { [weak self] in
            if self?.isForeground == true && self?.currentChatID != nil {
                self?.startPolling()
            } else {
                self?.stopPolling()
            }
        }
    }
}
