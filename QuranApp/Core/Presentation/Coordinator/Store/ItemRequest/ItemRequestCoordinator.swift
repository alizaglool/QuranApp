//
//  ItemRequestCoordinator.swift
//  QuranApp
//
//  Created by Mohamed Mostafa on 30/06/2025.
//

import Foundation
import UIKit
import Core

protocol ItemRequestCoordinating: AnyObject {
    func coordinateToAddItemRequest()
}

class ItemRequestCoordinator: MainCoordinator, ItemRequestCoordinating {
    
    var navigationController: UINavigationController
    var tabBarController: StoreTabBarController
    
    init(navigationController: UINavigationController, tabBarController: StoreTabBarController) {
        self.navigationController = navigationController
        self.tabBarController = tabBarController
    }
    
    func start() {
        let itemRequestView = ItemRequestView(coordinator: self)
        coordinateToView(itemRequestView)
    }
    
    func coordinateToAddItemRequest() {
        let addItemRequestCoordinator = AddItemRequestCoordinator(navigationController: navigationController)
        addItemRequestCoordinator.start()
    }
}
