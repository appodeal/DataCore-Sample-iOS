//
//  UIApplicationExtensions.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 19.05.2021.
//  Copyright © 2021 com.appodeal. All rights reserved.
//

import Foundation
import UIKit


extension UIApplication {
    var topViewContoller: UIViewController? {
        if #available(iOS 13.0, *) {
            return connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .map { $0.windows }
                .reduce([], +)
                .first { $0.isKeyWindow }
                .flatMap { $0.topPresentedViewController() }
        } else {
            return keyWindow?.topPresentedViewController()
        }
    }
}


private extension UIWindow {
    func topPresentedViewController() -> UIViewController? {
        var topViewController = rootViewController
        while (true) {
            if topViewController?.presentedViewController != nil {
                topViewController = topViewController?.presentedViewController;
            } else if let navigationViewController = topViewController as? UINavigationController  {
                topViewController = navigationViewController.topViewController;
            } else if let tabBarViewController = topViewController as? UITabBarController {
                topViewController = tabBarViewController.selectedViewController;
            } else {
                break;
            }
        }
        return topViewController;
    }
}
