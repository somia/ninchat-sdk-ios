platform :ios, '9.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/somia/ninchat-podspecs.git'

def all_pods
    pod 'AFNetworking', '~> 3.0'
    #pod 'NinchatLowLevelClient', '~> 0'
    pod 'NinchatLowLevelClient', :path => '.'
end

target 'NinchatSDK' do
  all_pods
end

target 'NinchatSDKTests' do
  all_pods
end
