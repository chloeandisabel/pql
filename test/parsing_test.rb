require File.join(File.expand_path(File.dirname(__FILE__)), '../lib/parser.rb')


expressions = [
  
'WHERE type = "AwardCashbackedPaymentCreditEntry"',

'WHERE type = "AwardCashbackedPaymentCreditEntry" AND a = 1 OR b = 2',

'WHERE type = "AwardCashbackedPaymentCreditEntry" AND (a = 1 OR b = 2)',

# 'WHERE type = "CheckoutItemSelected" AND caused_by = NULL',

# 'WHERE type = "CheckoutXPercentOffItemGeneralEntry" OR (label =~ /Spree/ AND amount <= 100.00)',

# 'WHERE type = "CheckoutItemSelected" AND id != (applied_to WHERE type = "CheckoutItemRemoved")',

# 'WHERE
#   type IN ["CheckoutNetItemTotalEntry", "CheckoutPromotionApplied"] AND
#   created_at >= (MAX created_at WHERE type = "CheckoutSummaryRequested")',

# 'WHERE
#   type = "CheckoutItemRemoved" AND
#   applied_to = (id WHERE
#     type = "CheckoutItemSelected" AND
#     caused_by = (id WHERE type = "CheckoutGiftSelected")
#   )',

# 'WHERE
#   type = "CheckoutItemRemoved" AND
#   applied_to = (id WHERE
#     type = "CheckoutItemSelected" AND
#     caused_by = (id WHERE
#       type = "CheckoutGiftSelected" AND
#       caused_by = (id WHERE type = "CheckoutGiftEarned")
#     )
#   )',

# 'WHERE
#   type IN [
#     "CheckoutXPercentOffOrderCouponEntry",
#     "CheckoutXDollarOffOrderCouponEntry",
#     "CheckoutXPercentOffOrderRaffleEntry",
#     "CheckoutXDollarOffOrderRaffleEntry",
#     "CheckoutXPercentOffOrderGeneralEntry",
#     "CheckoutXDollarOffOrderGeneralEntry",
#     "CheckoutXPercentOffItemCouponEntry",
#     "CheckoutXDollarOffItemCouponEntry",
#     "CheckoutXPercentOffItemLiquidationEntry",
#     "CheckoutXDollarOffItemLiquidationEntry",
#     "CheckoutXPercentOffItemGeneralEntry",
#     "CheckoutXDollarOffItemGeneralEntry",
#     "CheckoutPromotionGiftItemEntry",
#     "CheckoutPromotionCodeEntered",
#     "CheckoutPromotionRemoved",
#     "CheckoutItemSelected",
#     "CheckoutItemRemoved",
#     "ShippingMethodSelected"
#   ] AND
#   created_at >= (MAX created_at WHERE
#     TYPE = "CheckoutSummaryRequested" AND
#     created_at >= (MAX created_at WHERE
#       type = "PageViewed" AND
#       url =~ /\/orders\/R[0-9]+\/checkout_confirmation/
#     )
#   )'
]

expressions.each do |expression|
  puts "\n"
  puts expression;
  puts "\n"
  Parser.print_tree(Parser.parse(expression))
  puts "\n"
end
