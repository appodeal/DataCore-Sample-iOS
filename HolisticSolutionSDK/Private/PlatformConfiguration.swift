//
//  HSAppServicesPlist.swift
//  HolisticSolutionSDK
//
//  Created by Stas Kochkin on 25.06.2020.
//  Copyright © 2020 com.appodeal. All rights reserved.
//

import Foundation


internal struct PlatformConfiguration: Decodable {
    enum Keys: String, CodingKey {
        case appsFlyer = "AppsFlyer"
        case adjust = "Adjust"
    }
    
    struct AppsFlyerData: Decodable {
        enum Keys: String, CodingKey {
            case devKey = "DevKey"
            case appId = "AppId"
        }
        
        var devKey: String
        var appId: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            devKey = try container.decode(String.self, forKey: .devKey)
            appId = try container.decode(String.self, forKey: .appId)
        }
    }
    
    struct AdjustData: Decodable {
        enum Keys: String, CodingKey {
            case appToken = "AppToken"
        }
        
        var appToken: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            appToken = try container.decode(String.self, forKey: .appToken)
        }
    }
    
    let appsFlyer: AppsFlyerData?
    let adjust: AdjustData?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        appsFlyer = try? container.decode(AppsFlyerData.self, forKey: .appsFlyer)
        adjust = try? container.decode(AdjustData.self, forKey: .adjust)
    }
}

internal extension PropertyListDecoder {
    enum HSDecodeError: Error {
        case notFound
    }
    
    func decodeConfiguration(fromPlist: String) throws -> PlatformConfiguration {
        let xmlData: Data? = Bundle.main
            .path(forResource: fromPlist, ofType: "plist")
            .flatMap(FileManager.default.contents)
        guard let xml = xmlData else { throw HSDecodeError.notFound }
        return try decode(PlatformConfiguration.self, from: xml)
    }
}
