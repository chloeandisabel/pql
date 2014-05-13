class Rule

  def self.pattern(pql)
    @pattern = Parser.parse pql
  end

  def self.action(&block)
    @action = block
  end

  def apply(stream)
    pattern = self.class.instance_variable_get :@pattern
    action = self.class.instance_variable_get :@action

    match_set = pattern.apply stream

    match_set.each_match{|match| ActionContext.new(match).instance_eval &action}
  end

  class ActionContext
    def initialize(data)
      @data = data
    end

    def method_missing(name, *args)
      if @data[name]
        @data[name]
      else
        super
      end
    end
  end

end
