//
//  ViewController.swift
//  Sample
//
//  Created by Stas Kochkin on 04.05.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import UIKit
import Appodeal
import HolisticSolutionSDK
import Adjust
import AppsFlyerLib
import Firebase
import FirebaseRemoteConfig
import FBSDKCoreKit


private extension UITableViewCell {
    static func base(
        title: String,
        detail: String? = nil,
        style: UITableViewCell.CellStyle = .value1,
        accesory: UITableViewCell.AccessoryType = .none,
        userInteractionEnabled: Bool = false,
        reuseIdentifier: String = ViewController.cellId
    ) -> UITableViewCell {
        let cell = UITableViewCell(style: style, reuseIdentifier: reuseIdentifier)
        cell.isUserInteractionEnabled = userInteractionEnabled
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = detail
        cell.accessoryType = accesory
        return cell
    }
}

final class ViewController: StaticTableViewController {
    fileprivate static let cellId: String = "basic.cell"
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(holisitcSolutionDidComplete),
            name: AppDelegate.complete,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "basic.cell")
        sections = [
            behaviour,
            adjust,
            appsflyer,
            firebase,
            facebook,
            appodeal
        ]
    }
    
    private var adjust: Section {
        .init(
            header: "Adjust",
            rows: [
                .init { _ in .base(title: "Version", detail: Adjust.sdkVersion()) },
                .init { _ in .base(title: "Attribution ID", detail: Adjust.adid() ?? "-") }
            ]
        )
    }
    
    private var appsflyer: Section {
        .init(
            header: "AppsFlyer",
            rows: [
                .init { _ in .base(title: "Version", detail: AppsFlyerLib.shared().getSDKVersion()) },
                .init { _ in .base(title: "Attribution ID", detail:  AppsFlyerLib.shared().getAppsFlyerUID()) }
            ]
        )
    }
    
    private var firebase: Section {
        .init(
            header: "Firebase (Remote Config)",
            rows: [
                .init { _ in .base(title: "Version", detail: FirebaseVersion()) },
                .init { _ in .base(title: "Keywords", detail: RemoteConfig.remoteConfig().allKeys(from: .remote).joined(separator: ", ")) }
            ]
        )
    }
    
    private var facebook: Section {
        .init(
            header: "FB SDK",
            rows: [
                .init { _ in .base(title: "Version", detail: FBSDK_VERSION_STRING) },
                .init { _ in .base(title: "App ID", detail: Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String) }
            ]
        )
    }
    
    
    private var appodeal: Section {
        .init(
            header: "Appodeal",
            rows: [
                .init { _ in .base(title: "Version", detail: APDSdkVersionString()) },
                .init { _ in .base(title: "Initialized", accesory: Appodeal.isInitalized(for: AppDelegate.AppodealConstants.adType) ? .checkmark : .none) },
            ]
        )
    }
    
    private var behaviour: Section {
        .init(
            header: "Behavior",
            rows: [
                .init(
                    cell: { _ in .base(title: "Event", detail: "Synthesize random event", style: .subtitle, userInteractionEnabled: true) },
                    select: { [unowned self] in self.synthesizeEvent() }
                ),
                .init(
                    cell: { _ in .base(title: "Purchase", detail: "Synthesize random in-app purchase", style: .subtitle, userInteractionEnabled: true) },
                    select: { [unowned self] in self.synthesizePurchase(.consumable) }
                ),
                .init(
                    cell: { _ in .base(title: "Subscription", detail: "Synthesize random subscription", style: .subtitle, userInteractionEnabled: true) },
                    select: { [unowned self] in self.synthesizePurchase(.autoRenewableSubscription) }
                )
            ]
        )
    }
    
    
    @objc private
    func holisitcSolutionDidComplete() {
        Appodeal.showAd(.bannerBottom, rootViewController: self)
        tableView.reloadSections(IndexSet(1..<sections.count), with: .fade)
    }
    
    func synthesizePurchase(_ type: PurchaseType) {
        let additionalParameters = [
            "Test Custom 1" : "Value 1",
            "Test Custom 2" : "Value 2"
        ]
        Appodeal.hs.validateAndTrackInAppPurchase(
            productId: "some product id",
            type: type,
            price: "9.99",
            currency: "USD",
            transactionId: "some transaction id",
            additionalParameters: additionalParameters,
            success: { [weak self] in self?.alert("Purchase is valid", message: $0.description) },
            failure: { [weak self] error, _ in self?.alert("Purchase is invalid", message: error?.localizedDescription) }
        )
    }
    
    func synthesizeEvent() {
        Appodeal.hs.trackEvent("level_started", customParameters: nil)
    }
    
    func alert(_ title: String, message: String? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

