require File.join(File.expand_path(File.dirname(__FILE__)), '../lib/parser.rb')
require 'test/unit'

class TestParsing < Test::Unit::TestCase

  def test_parsing
    expressions = [
      
    'MATCH LAST 5 BY created_at WHERE type IS AwardCashbackedPaymentCreditEntry;',

    'MATCH ALL AS items WHERE type IS CheckoutItemSelected AND caused_by IS NULL',

    'MATCH FIRST BY id AS discount WHERE type IS CheckoutXPercentOffItemGeneralEntry AND label =~ /Spree/;
     MATCH EACH AS item WHERE type IS CheckoutItemSelected AND id NOT IN (applied_to WHERE type IS CheckoutItemRemoved)',

    'MATCH NONE WHERE type IS "CreditEarned" AND amount > (SUM amount OF LAST 3 BY id WHERE type IS PartialCreditEarned)',

    'MATCH EACH WHERE
      type IN ["CheckoutNetItemTotalEntry", "CheckoutPromotionApplied"] AND
      created_at >= (MAX created_at WHERE type IS CheckoutSummaryRequested);',

    'MATCH FIRST BY id WHERE
      type = "CheckoutItemRemoved" AND
      applied_to IN (id WHERE
        type = "CheckoutItemSelected" AND
        caused_by IN (id WHERE type = "CheckoutGiftSelected")
      );',

    'MATCH ALL WHERE
      type = "CheckoutItemRemoved" AND
      applied_to IN (id WHERE
        type = "CheckoutItemSelected" AND
        caused_by IN (id WHERE
          type = "CheckoutGiftSelected" AND
          caused_by IN (id WHERE type = "CheckoutGiftEarned")
        )
      )',

    'MATCH EACH WHERE
      type IN [
        "CheckoutXPercentOffOrderCouponEntry",
        "CheckoutXDollarOffOrderCouponEntry",
        "CheckoutXPercentOffOrderRaffleEntry",
        "CheckoutXDollarOffOrderRaffleEntry",
        "CheckoutXPercentOffOrderGeneralEntry",
        "CheckoutXDollarOffOrderGeneralEntry",
        "CheckoutXPercentOffItemCouponEntry",
        "CheckoutXDollarOffItemCouponEntry",
        "CheckoutXPercentOffItemLiquidationEntry",
        "CheckoutXDollarOffItemLiquidationEntry",
        "CheckoutXPercentOffItemGeneralEntry",
        "CheckoutXDollarOffItemGeneralEntry",
        "CheckoutPromotionGiftItemEntry",
        "CheckoutPromotionCodeEntered",
        "CheckoutPromotionRemoved",
        "CheckoutItemSelected",
        "CheckoutItemRemoved",
        "ShippingMethodSelected"
      ] AND
      created_at >= (MAX created_at WHERE
        TYPE = "CheckoutSummaryRequested" AND
        created_at >= (MAX created_at WHERE
          type = "PageViewed" AND
          url =~ /\/orders\/R[0-9]+\/checkout_confirmation/
        )
      );'
    ]

    expressions.each do |expression|
      puts "\n"
      puts expression;
      puts "\n"
      Parser.print_tree(Parser.parse(expression))
      puts "\n"
    end
  end

end
