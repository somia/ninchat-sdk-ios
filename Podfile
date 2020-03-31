platform :ios, '9.0'
use_frameworks!

# Changing the source URL
# according to the thread: https://stackoverflow.com/questions/58958185/travis-ci-gets-stuck-in-pods-installation
source 'https://cdn.cocoapods.org/' 
source 'https://github.com/somia/ninchat-podspecs.git'

def all_pods
    pod 'AFNetworking'
    pod 'NinchatLowLevelClient', '~> 0.0.40'
    pod 'GoogleWebRTC', '~> 1.1'
end

target 'NinchatSDK' do
  all_pods
end

target 'NinchatSDKTests' do
  all_pods
end
