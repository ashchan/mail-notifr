Pod::Spec.new do |s|
  s.name         =  'MASShortcut'
  s.version      =  '0.0.1'
  s.summary      =  'Modern framework for managing global keyboard shortcuts compatible with Mac App Store.'
  s.homepage     =  'https://github.com/shpakovski/MASShortcut'
  s.author       =  { 'Vadim Shpakovski' => 'vadim@shpakovski.com' }
  s.source       =  { :git => 'https://github.com/shpakovski/MASShortcut.git' }
  s.license      =  '2-clause BSD'

  s.requires_arc = true
  s.source_files = 'MAS*.{h,m}'
end
