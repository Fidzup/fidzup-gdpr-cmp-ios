Pod::Spec.new do |spec|
  spec.name                  = "FidzupCMP"
  spec.version               = "5"
  spec.author                = "Fidzup"
  spec.license               = { :type => "Creative Commons Legal Code, Attribution 3.0 Unported" }
  spec.homepage              = "https://github.com/Fidzup/fidzup-gdpr-cmp-ios"
  spec.summary               = "Fidzup CMP, fork from Smart AdServer's CMP - Compliant with IAB Transparency and Consent Framework and Consent String and Vendor List v1.1 specifications"
  spec.source                = { :git => "https://github.com/Fidzup/fidzup-gdpr-cmp-ios.git", :tag => "v#{spec.version}" }
  spec.module_name           = "FidzupCMP"
  spec.swift_version         = "4.0"
  spec.platform              = :ios, "8.0"
  spec.ios.deployment_target = "8.0"
  spec.source_files          = "framework/SmartCMP/**/*.{h,m,swift}"
  spec.resources             = "framework/SmartCMP/**/*.{plist,storyboard}"
  spec.framework             = "AdSupport"
end
