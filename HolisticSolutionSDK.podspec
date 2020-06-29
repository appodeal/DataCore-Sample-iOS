Pod::Spec.new do |spec|
  spec.name         = "HolisticSolutionSDK"
  spec.version      = "0.0.1"
  spec.summary      = "The HolisticSolutionSDK provides easy to use API for integration attribution, product testing and advertising platform."
  spec.description  = <<-DESC
  The Holistic Solution SDK is iOS framework. It provides easy to use API for integration attribution, product testing and advertising platform.
  It contains AppsFlyer, Firebase Remote Config, Appodeal connectors. The framework allows to send all data to Stack Holistic Solution service without 
  additional synchronisation code.
                   DESC
  spec.homepage     = "https://explorestack.com"
  spec.license      = "MIT"
  spec.author       = { "appodeal" => "https://appodeal.com" }
  spec.platform     = :ios, "9.0"

  spec.source       = { :git => "git@github.com:appodeal/DataCore-Sample-iOS.git", :branch => "feature-holistic-solution" }

  spec.source_files  = "HolisticSolutionSDK/**/*.{h,swift}"
  spec.exclude_files = 
  	"HolisticSolutionSDK/Appodeal",
  	"HolisticSolutionSDK/AppsFlyer",
  	"HolisticSolutionSDK/FirebaseRemoteConfig"

  spec.requires_arc = true
  spec.static_framewotrk = true
  spec.default_subspecs = "Full"

  spec.subspec "Appodeal" do |ss|
    ss.source_files	= "HolisticSolutionSDK/Appodeal"
    ss.dependency "Appodeal", ">= 2.6"
  end

  spec.subspec "AppsFlyer" do |ss|
    ss.source_files = "HolisticSolutionSDK/AppsFlyer"
    ss.dependency "AppsFlyerFramework", ">= 5.3"
  end

  spec.subspec "FirebaseRemoteConfig" do |ss|
    ss.source_files = "HolisticSolutionSDK/FirebaseRemoteConfig"
    ss.dependency "Firebase/Analytics", ">= 6.20"
  	ss.dependency "Firebase/RemoteConfig", ">= 4.4"
  end

  spec.subspec "Full" do |ss| 
  	ss.dependency "HolisticSolutionSDK/Appodeal"
  	ss.dependency "HolisticSolutionSDK/AppsFlyer"
  	ss.dependency "HolisticSolutionSDK/FirebaseRemoteConfig"
  end
end
