//
//  ViewChecker.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import Foundation

public struct ViewChecker {
    
    public var state: CheckerState
    
    var messages: Dictionary<CheckerState, String>
    
    var message: String { messages[state] ?? "" }
    
    public var isCorrect: Bool { state == .correct }
    
    public init(state: CheckerState,
                messages: Dictionary<CheckerState, String>) {
        self.state = state
        self.messages = messages
    }
}

public extension ViewChecker {
    static let emptyChecker = ViewChecker(state: .correct, messages: [:])
}
