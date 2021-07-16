//
//  HSAdvertisingPlatform.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 25.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation


protocol Advertising {
    func setTrackId(_ trackId: String)
    func setAttributionId(_ attributionId: String)
    func setConversionData(_ converstionData: [AnyHashable: Any])
    func setProductTestData(_ productTestData: [AnyHashable: Any])
    func setMMP(mmp: String)
}

