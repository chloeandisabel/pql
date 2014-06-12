class ExampleRule < Rule

  pattern <<-PQL
    MATCH EACH AS a WHERE type IS "A";
    MATCH ALL AS b WHERE type IS "B";
  PQL

  method :do_something do
    'abcd'
  end

  action do |t|
    @@counter += 1
  end
end



block = ->(){return 5}

ExampleRule.method(:do_something, &block)

ExampleRule.method :abcd do
  return 5
end



class A
  def self.a
    5
  end
end

class B
  def self.a
    7
  end
end

block = ->(){
  a + 1
}

block.call() # error!

A.class_eval(&block) # == 6
B.class_eval(&block) # == 8


c = B.class_eval do
  a + 1
end

c == 8 # true