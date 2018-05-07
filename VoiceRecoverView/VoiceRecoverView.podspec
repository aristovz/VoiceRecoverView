
Pod::Spec.new do |s|

  s.name         = "VoiceRecoverView"
  s.version      = "1.0.0"
  s.swift_version = '4.0'
  s.summary      = "UI for voice recording like in mobile app vk.com"
  
  s.description = <<-DESC
                     A simple and easy framework that allows you to add a panel for voice recording. Replica of the interface of the most popular Russian social network - vk.com
                   DESC

  s.homepage     = "https://github.com/aristovz/VoiceRecoverView.git"
  s.license      = { :type => "MIT", :file => "../LICENSE" }

  s.author             = { "pavelaristov" => "nbapavel@me.com" }
  s.social_media_url   = "https://vk.com/aristovz"

  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/aristovz/VoiceRecoverView.git", :tag => s.version.to_s }

  s.source_files  = "VoiceRecoverView/**/*.{h,m,swift}"
  s.resource_bundles = {
    'VoiceRecoverView' => ['VoiceRecoverView/**/*.{storyboard,xib}']
  }

  #s.framework  = "Foundation"
  #s.requires_arc = true

  s.dependency "FontAwesome.swift"

end