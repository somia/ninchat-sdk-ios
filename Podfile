platform :ios, '9.0'
use_frameworks!

#source 'https://github.com/CocoaPods/Specs.git'

# Changing the source URL
# according to the thread: https://stackoverflow.com/questions/58958185/travis-ci-gets-stuck-in-pods-installation
source 'https://cdn.cocoapods.org/' 
source 'https://github.com/somia/ninchat-podspecs.git'

def all_pods
    pod 'AFNetworking', '~> 3.0'
    pod 'NinchatLowLevelClient', '~> 0'
    pod 'GoogleWebRTC', '~> 1.1'
    #pod 'NinchatLowLevelClient', :path => '.'
end

target 'NinchatSDK' do
  all_pods
end

target 'NinchatSDKTests' do
  all_pods
end
