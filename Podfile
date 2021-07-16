platform :ios, '10.0'
workspace 'HolisticSolutionSDK.xcworkspace'

source 'https://cdn.cocoapods.org/'
source 'https://github.com/appodeal/CocoaPods.git'

install! 'cocoapods', :deterministic_uuids => false, :warn_for_multiple_pod_sources => false
use_frameworks!

def appodeal
  pod 'Appodeal', '>= 2.9'
  pod 'StackConsentManager', '>= 1.1.0'
end

def firebase
  pod 'Firebase/Core', '>= 8.0.0'
  pod 'Firebase/Analytics', '>= 8.0.0'
  pod 'Firebase/RemoteConfig', '>= 8.0.0'
end

def appsflyer
  pod 'AppsFlyerFramework', '>= 5.3'
end

def facebook 
  pod 'FBSDKCoreKit', '>= 11.0'
end

def adjust
  pod 'Adjust', '~> 4.29.2'
  pod 'AdjustPurchase', :git => 'https://github.com/adjust/ios_purchase_sdk', :tag => 'v1.0.0'
end

def deps
  firebase
  appsflyer
  adjust
  facebook
  appodeal
end


target 'HolisticSolutionSDK' do
  project 'HolisticSolutionSDK.xcodeproj'
  deps
end

target 'Sample-Swift' do
  project 'Sample-Swift.xcodeproj'
	deps
end

target 'Sample-ObjC' do
  project 'Sample-ObjC.xcodeproj'
	deps
end
