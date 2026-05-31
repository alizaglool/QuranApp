//
//  SceneDelegate.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 21/04/2025.
//

import UIKit
import Core

class SceneDelegate: UIResponder, UIWindowSceneDelegate, SceneDelegateProtocol {

    var window: UIWindow?
    
    var coordinator: AppCoordinatorProtocol?
    
    var coordinatorProvider: AppCoordinatorProtocol? {
        if let window {
            return AppCoordinator(window: window)
        }
        return nil
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        setupLocalization()
        prepareApp()
        applyStoredTheme()
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        StorageManager.shared.forceSave()
    }
}

// MARK: - Localization Setup
private extension SceneDelegate {

    func setupLocalization() {
        LocalizationManager.shared.delegate = self
        LocalizationManager.shared.setAppInnitLanguage()
    }

    func applyStoredTheme() {
        let mode = StorageManager.shared.getSettings()?.themeMode ?? "system"
        let style: UIUserInterfaceStyle
        switch mode {
        case "light": style = .light
        case "dark":  style = .dark
        default:      style = .unspecified
        }
        window?.overrideUserInterfaceStyle = style
    }
}

// MARK: - LocalizationDelegate
extension SceneDelegate: LocalizationDelegate {
    
    func resetAppAfterChangeLanguge() {
        guard let window = window else { return }
        
        coordinator = AppCoordinator(window: window)
        coordinator?.start(showSplash: false)
        
        let options: UIView.AnimationOptions = .transitionCrossDissolve
        let duration: TimeInterval = 0.3
        UIView.transition(with: window, duration: duration, options: options, animations: nil, completion: nil)
    }
    
    func resetAppFromTabBar() {
        guard let window = window else { return }
        
        let tabBarViewController = TabBarController()
        
        tabBarViewController.selectedIndex = 4
        
        window.rootViewController = tabBarViewController
        
        let options: UIView.AnimationOptions = .transitionCrossDissolve
        let duration: TimeInterval = 0.3
        UIView.transition(with: window, duration: duration, options: options, animations: nil, completion: nil)
    }
}
