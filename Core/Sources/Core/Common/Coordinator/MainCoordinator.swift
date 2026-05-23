//
//  MainCoordinator.swift
//  
//
//  Created by Ali M. Zaghloul on 7/6/24.
//

import SwiftUI

public protocol MainCoordinator {
    
    var navigationController: UINavigationController { get set }
    
    func start()
    
    func coordinate(to coordinator: MainCoordinator)
    
    func coordinateToView(_ view: some View)
    
    func coordinateBack()    
}

public extension MainCoordinator {
    
    func coordinate(to coordinator: MainCoordinator) {
        coordinator.start()
    }
    
    func coordinateToView(_ view: some View) {
        let manager = LocalizationManager.shared
        
        let hostedView = view
            .environmentObject(manager)
            .environment(\.layoutDirection, manager.currentLanguage.direction)
        
        let hostingController = UIHostingController(rootView: hostedView)
        navigationController.pushViewController(hostingController, animated: true)
    }
    
    func coordinateBack() {
        navigationController.popViewController(animated: true)
    }
}
