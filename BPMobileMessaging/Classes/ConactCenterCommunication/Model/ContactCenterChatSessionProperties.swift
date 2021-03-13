//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

/// Enumeration of allowed chat session state values.
/// - Tag: ContactCenterChatSessionState
public enum ContactCenterChatSessionState {
    /// A session is placed in the queue and is waiting for the next available Contact Center agent.
    case queued
    /// An agent has been reserved for the session; agent still has to accept the session.
    case connecting
    /// An agent has been reserved and connected to the session.
    case connected
    /// A server scenario which handles a sessionis in IVR stage (the system may send the messages to teh client and automatically handle the responses).
    case ivr
    /// A session has failed.
    case failed
    /// A session is complete; not more activity is allowed within the session.
    case completed
}

/// Describes the properties of the current chat session.
/// - Tag: ContactCenterChatSessionProperties
public struct ContactCenterChatSessionProperties {
    /// Chat session unique ID
    public let chatID: String
    /// Chat session state
    public let state: ContactCenterChatSessionState
    /// Estimated time the session will stay in the queue before an agent is available (seconds)
    public let estimatedWaitTime: Int
    /// Specifies if this is a new session. The `requestChat` method may return an existing session if the application was closed during active session and then reopened again
    public let isNewChat: Bool
    /// Client phone number specified in the `requestChat` method
    public let phoneNumber: String
}
