Gem::Specification.new do |s|
  s.name        = 'pql'
  s.version     = '0.0.0'
  s.date        = '2014-06-26'
  s.summary     = 'Pattern Query Language'
  s.description = 'A small declarative language for describing patterns in streams of events.'
  s.authors     = ['Charlie Schwabacher']
  s.email       = 'charlie.schwbacher@chloeandisabel.com'
  s.files       = ['lib/pql.rb', 'lib/pql/node_extensions.rb']
  s.homepage    = 'https://bitbucket.org/charlieschwabacher/pql'

  s.add_runtime_dependency 'treetop'
end