//
//  LoadingState.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import Foundation

public enum LoadingState {
    
    case loading
    case loaded
    case failed
    
    var isLoading: Bool {
        self == .loading
    }
}
