require File.join(File.expand_path(File.dirname(__FILE__)), 'parser.rb')

class Rule

  @match_expressions = {}
  @test_blocks = {}

  def self.match(name, expression)
    @match_expressions[name] = Parser.parse(expression)
  end

  def self.test(&block)
  end

  def self.perform(description, &block)
  end
end


class CheckoutDefaultCreditCardSelectionRule < Rule
  match :customer_selected, "LAST BY created_at WHERE type = 'CustomerSelected'"
  match :existing_cc_selected, "WHERE type = 'credit_card_selected'"

  test do
    existing_cc_selected.none? and customer_selected and customer_selected.customer.defualt_credit_card_id
  end

  perform 'assign default credit card to order' do
    credit_card_selected credit_card_id: customer_selected.customer.defualt_credit_card_id
  end 
end
