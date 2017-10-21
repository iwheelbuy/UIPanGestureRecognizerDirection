# git tag 1.0.0
# git push origin 1.0.0
# pod lib lint UIPanGestureRecognizerDirection.podspec --no-clean --verbose
# pod spec lint UIPanGestureRecognizerDirection.podspec --allow-warnings
# pod trunk push UIPanGestureRecognizerDirection.podspec --verbose

Pod::Spec.new do |s|

s.name                  = 'UIPanGestureRecognizerDirection'
s.version               = '1.0.0'
s.ios.deployment_target = '9.0'
s.source_files          = 'UIPanGestureRecognizerDirection/Classes/**/*'
s.homepage              = 'https://github.com/iwheelbuy/UIPanGestureRecognizerDirection'
s.license               = 'MIT'
s.author                = { 'iwheelbuy' => 'iwheelbuy@gmail.com' }
s.source                = { :git => 'https://github.com/iwheelbuy/UIPanGestureRecognizerDirection.git', :tag => s.version.to_s }
s.summary               = 'UIPanGestureRecognizerDirection'
s.cocoapods_version     = '>= 1.3.1'
s.pod_target_xcconfig   = { "SWIFT_VERSION" => "4.0" }

end
