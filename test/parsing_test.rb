require_relative '../lib/pql/parser.rb'
require_relative '../lib/pql/applications.rb'
require_relative '../lib/pql/node_extensions.rb'
require 'test/unit'

class TestParsing < Test::Unit::TestCase

  def test_parsing
    expressions = [

    'MATCH EACH AS item WHERE type IS "CheckoutItemSelected" AND id NOT IN (applied_to WHERE type IS "CheckoutItemRemoved");
     MATCH EACH AS tax WHERE type IS "CheckoutItemTaxEntry" JOINING item WHERE applied_to = item.id;',
    
    'MATCH EACH AS item WHERE type IS "CheckoutItemSelected";
     MATCH EACH AS tax WHERE type IS "CheckoutItemTaxEntry" JOINING item WHERE sku = item.sku;
     MATCH EACH AS credit WHERE type IS "CheckoutItemCreditEntry" JOINING item WHERE sku = item.sku;',

    'MATCH LAST 5 IN ORDER BY created_at WHERE type IS "AwardCashbackedPaymentCreditEntry";',

    'MATCH ALL AS items WHERE type IS "CheckoutItemSelected" AND caused_by IS NULL',

    'MATCH FIRST IN ORDER BY id AS discount WHERE type IS "CheckoutXPercentOffItemGeneralEntry" AND label =~ /Spree/;
     MATCH EACH AS item WHERE type IS "CheckoutItemSelected" AND id NOT IN (applied_to WHERE type IS "CheckoutItemRemoved")',

    'MATCH NONE WHERE type IS "CreditEarned" AND amount > (SUM amount OF LAST 3 IN ORDER BY id WHERE type IS "PartialCreditEarned")',

    'MATCH EACH WHERE
      type IN ["CheckoutNetItemTotalEntry", "CheckoutPromotionApplied"] AND
      created_at >= (MAX created_at WHERE type IS CheckoutSummaryRequested);',

    'MATCH FIRST IN ORDER BY id WHERE
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
      );',

      'MATCH LAST IN ORDER BY created_at AS item_total WHERE TYPE IS "CheckoutNetItemTotalEntry";
       MATCH LAST IN ORDER BY created_at AS shipping_total WHERE TYPE IS "CheckoutNetShippingTotalEntry";
       MATCH LAST IN ORDER BY created_at AS tax_total WHERE TYPE IS "CheckoutTaxTotalEntry";
       MATCH EACH AS credit WHERE
         TYPE IN [
           "AwardAdminPaymentCreditEntry",
           "AwardMerchandiserPaymentCreditEntry",
           "AwardHostessPaymentCreditEntry",
           "AwardLegacyPaymentCreditEntry"
         ]
         AND amount > (SUM amount WHERE
           TYPE IN [
             "RedeemAdminPaymentCreditEntry",
             "RedeemCashbackedPaymentCreditEntry",
             "RedeemMerchandiserPaymentCreditEntry",
             "RedeemHostessPaymentCreditEntry",
             "RedeemLegacyPaymentCreditEntry"
           ]
           AND applied_to = ^id
         );'
    ]

    expressions.each do |expression|
      puts "\n"
      puts expression;
      puts "\n"
      PQL::Parser.print(PQL::Parser.parse(expression))
      puts "\n"
    end
  end

end
