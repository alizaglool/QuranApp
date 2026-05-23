//
//  MainViewModel.swift
//  
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import Foundation

@MainActor
public protocol MainViewModel: ObservableObject {
    
    var isTabBarVisible: Bool { get }
    
    func onAppear()
    
    func onDisappear()
}

public extension MainViewModel {
    
    var isTabBarVisible: Bool { true }
    
    func onDisappear() {
        
    }
}
