Gem::Specification.new do |s|
  s.name        = 'PQL'
  s.version     = '0.0.0'
  s.date        = '2014-06-26'
  s.summary     = 'Pattern Query Language'
  s.description = 'A small declarative language for describing patterns in streams of events.'
  s.authors     = ['Charlie Schwabacher']
  s.email       = 'charlie.schwbacher@chloeandisabel.com'
  s.files       = ['lib/entry.rb', 'lib/event.rb', 'lib/event_store.rb', 
                   'lib/ontology.rb', 'lib/parser.rb', 'lib/rule.rb', 
                   'lib/ruleset.rb', 'lib/stream.rb']
  s.homepage    = 'https://bitbucket.org/charlieschwabacher/pql'
end