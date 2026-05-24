//
//  TabBarItem.swift
//
//
//  Created by Ali M. Zaghloul on 7/6/24.
//

import UIKit

public class TabBarItem: Equatable, Identifiable {
    
    public let id: UUID = UUID()
    
    var title: String = ""
    var image: UIImage?
    
    var viewControllerProvider: () -> UIViewController
    
    func getViewController() -> UIViewController {

        let viewController = viewControllerProvider()

        viewController.tabBarItem.title = title
        viewController.tabBarItem.image = image

        return viewController
    }
    
    public init(title: String,
                image: UIImage?,
                viewControllerProvider: @escaping () -> UIViewController) {
        self.title = title
        self.image = image
        self.viewControllerProvider = viewControllerProvider
    }
    
    public static func == (lhs: TabBarItem, rhs: TabBarItem) -> Bool {
        lhs.id == rhs.id
    }
}
