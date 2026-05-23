//
//  ItemRequestCoordinator.swift
//  QuranApp
//
//  Created by Mohamed Mostafa on 30/06/2025.
//

import Foundation
import UIKit
import Core

protocol AddItemRequestCoordinating: AnyObject {
    func coordinateToPop()
}

class AddItemRequestCoordinator: MainCoordinator, AddItemRequestCoordinating {
    
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let addItemRequestView = AddItemRequestView(coordinator: self)
        coordinateToView(addItemRequestView)
    }
    
    func coordinateToPop() {
        navigationController.popViewController(animated: true)
    }
}
