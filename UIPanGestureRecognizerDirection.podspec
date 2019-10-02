# git tag 1.1.1
# git push origin 1.1.1
# pod lib lint UIPanGestureRecognizerDirection.podspec --no-clean --verbose
# pod spec lint UIPanGestureRecognizerDirection.podspec --allow-warnings
# pod trunk push UIPanGestureRecognizerDirection.podspec --verbose

Pod::Spec.new do |s|

s.name                  = 'UIPanGestureRecognizerDirection'
s.version               = '1.1.1'
s.ios.deployment_target = '11.0'
s.source_files          = 'UIPanGestureRecognizerDirection/Classes/**/*'
s.homepage              = 'https://github.com/iwheelbuy/UIPanGestureRecognizerDirection'
s.license               = 'MIT'
s.author                = { 'iwheelbuy' => 'iwheelbuy@gmail.com' }
s.source                = { :git => 'https://github.com/iwheelbuy/UIPanGestureRecognizerDirection.git', :tag => s.version.to_s }
s.summary               = 'UIPanGestureRecognizerDirection'
s.cocoapods_version     = '>= 1.8.1'
s.swift_versions        = ['5.1']

end
