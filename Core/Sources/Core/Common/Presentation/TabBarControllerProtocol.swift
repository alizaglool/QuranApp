//
//  TabBarControllerProtocol.swift
//
//
//  Created by Ali M. Zaghloul on 7/6/24.
//

import UIKit

public protocol TabBarControllerProtocol: UITabBarController {
    
    var tabBarItems: [TabBarItem] { get set }
    
    var selectedTabItem: TabBarItem? { get set }
    
    var height: CGFloat { get }
    
    var isHidden: Bool { get }
    
    func configure()
    func getTabBarControllers() -> [UIViewController]
    
    func configureTitles()
    
    func configureSemanticContentAttribute(semanticContentAttribute: UISemanticContentAttribute)
    
    func hide()
    func show()
}

public extension TabBarControllerProtocol {
    
    var height: CGFloat {
        tabBar.frame.height
    }
    
    var isHidden: Bool {
        tabBar.isHidden
    }
    
    func hide() {
        tabBar.isHidden = true
    }
    
    func show() {
        tabBar.isHidden = false
    }
    
    func configure() {
        
        tabBar.tintColor = .primaryColor
        
        tabBar.unselectedItemTintColor = .tabBarItemUnselected
        
        tabBar.backgroundColor = .tabBarBackground
        
        self.viewControllers = getTabBarControllers()
        
        configureTitles()
    }
    
    func getTabBarControllers() -> [UIViewController] {
        var viewControllers: [UIViewController] = []
        
        for i in 0..<tabBarItems.count {
            
            let viewController = tabBarItems[i].getViewController()
            
            viewControllers.append(viewController)
        }
        
        return viewControllers
    }
    
    func configureTitles() {
        
        for i in 0..<tabBarItems.count {
            self.tabBar.items?[i].title = tabBarItems[i].title
        }
    }
    
    func configureSemanticContentAttribute(semanticContentAttribute: UISemanticContentAttribute) {
        self.tabBar.semanticContentAttribute = semanticContentAttribute
    }
}
