#
# Be sure to run `pod lib lint BPMobileMessaging.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BPMobileMessaging'
  s.version          = '0.1.1'
  s.summary          = 'Mobile Messaging API Library for iOS RESTful API for chat and voice interactions'

  s.description      = <<-DESC
  Mobile Messaging API Library for iOS is a RESTful API that allows developers to integrate chat and voice interactions with mobile devices or third-party applications. This API can be used for development of rich contact applications, such as customer-facing mobile and web applications for advanced chat, voice, and video communications with Bright Pattern Contact Center-based contact centers
                       DESC

  s.homepage         = 'https://github.com/ServicePattern/MobileAPI_IOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'https://www.brightpattern.com' => 'https://www.brightpattern.com' }
  s.source           = { :git => 'https://github.com/ServicePattern/MobileAPI_IOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files = 'BPMobileMessaging/Classes/**/*'
  
  s.swift_versions = '4.0'
end
