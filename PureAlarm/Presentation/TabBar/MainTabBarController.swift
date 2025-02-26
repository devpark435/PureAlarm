//
//  MainTabBarController.swift
//  PureAlarm
//
//  Created by 박현렬 on 2/26/25.
//

import UIKit

final class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
    }
    
    private func setupTabBar() {
        // 알람 탭
        let alarmVC = AlarmListViewController()
        let alarmNavController = UINavigationController(rootViewController: alarmVC)
        alarmNavController.navigationBar.isHidden = true // 내비게이션 바 숨김
        alarmNavController.tabBarItem = UITabBarItem(
            title: "알람",
            image: UIImage(systemName: "alarm"),
            selectedImage: UIImage(systemName: "alarm.fill")
        )
        
        // 수면 관리 탭
        let sleepVC = SleepManagementViewController()
        let sleepNavController = UINavigationController(rootViewController: sleepVC)
        sleepNavController.navigationBar.isHidden = true // 내비게이션 바 숨김
        sleepNavController.tabBarItem = UITabBarItem(
            title: "수면 관리",
            image: UIImage(systemName: "bed.double"),
            selectedImage: UIImage(systemName: "bed.double.fill")
        )
        
        // 탭바 스타일 설정
        tabBar.tintColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        tabBar.unselectedItemTintColor = UIColor(white: 0.6, alpha: 1.0)
        
        // iOS 15 이상에서 탭바 배경색 설정
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
            
            // 선택된 아이템과 기본 아이템의 외형 설정
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(white: 0.6, alpha: 1.0)]
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)]
            
            appearance.stackedLayoutAppearance = itemAppearance
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            // iOS 15 미만
            tabBar.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        }
        
        // 뷰 컨트롤러 설정
        viewControllers = [alarmNavController, sleepNavController]
        
        // 그림자 효과 추가
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -3)
        tabBar.layer.shadowRadius = 8
        tabBar.layer.shadowOpacity = 0.3
    }
}
