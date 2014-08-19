Gem::Specification.new do |s|
  s.name        = 'collmex-ruby'
  s.version     = '0.2.1'
  s.date        = '2012-07-29'
  s.summary     = "A ruby api lib for collmex"
  s.description = "A lib written in ruby that talks to the german accounting software collmex."
  s.authors     = ["Roman Lehnert, Stephan Schubert"]
  s.email       = 'roman.lehnert@googlemail.com, stphnschbrt@gmail.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    = 'https://github.com/romanlehnert/collmex-ruby'
  s.license     = "MIT"
  s.test_files  = Dir.glob("{spec,test}/**/*.rb")
end
