//
//  SceneDelegate.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 의존성 설정
        let storage = AlarmStorage.shared
        let repository = AlarmRepository(storage: storage)
        let useCase = AlarmUseCase(repository: repository)
        let viewModel = AlarmListViewModel(useCase: useCase)
        
        // 알람 뷰컨트롤러 생성 (의존성 주입)
        let alarmViewController = AlarmListViewController(viewModel: viewModel)
        let alarmNavController = UINavigationController(rootViewController: alarmViewController)
        
        // 수면관리 뷰컨트롤러 생성
        let sleepManagementViewController = SleepManagementViewController()
        let sleepNavController = UINavigationController(rootViewController: sleepManagementViewController)
        
        // 탭바 컨트롤러 설정
        let tabBarController = MainTabBarController()
        tabBarController.setViewControllers([alarmNavController, sleepNavController], animated: false)
        tabBarController.setupTabItems() // 탭 아이템 설정
        
        // 윈도우 설정
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = tabBarController
        window?.overrideUserInterfaceStyle = .dark // 다크모드 적용
        window?.makeKeyAndVisible()
        window?.tintColor = .orange
        window?.backgroundColor = .black
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
    }
    
    
}

