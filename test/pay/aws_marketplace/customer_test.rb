require "test_helper"

class Pay::AwsMarketplace::CustomerTest < ActiveSupport::TestCase
  setup do
    @pay_customer = pay_customers(:fake)
  end

  test "allows aws_marketplace processor" do
    assert_nothing_raised do
      users(:none).set_payment_processor :aws_marketplace
    end
  end

  test "aws processor api_record" do
    assert_equal @pay_customer, @pay_customer.api_record
  end

  test "aws processor charge" do
    assert_difference "Pay::Charge.count" do
      @pay_customer.charge(10_00)
    end
  end

  test "aws processor charge options" do
    assert_difference "Pay::Charge.count" do
      @pay_customer.charge(10_00, {description: "Hello world"})
    end
  end

  test "aws processor subscribe" do
    assert_difference "Pay::Subscription.count" do
      @pay_customer.subscribe
    end
  end

  test "aws processor subscribe with promotion code" do
    assert_difference "Pay::Subscription.count" do
      @pay_customer.subscribe(promotion_code: "promo_xxx123")
    end
  end

  test "aws processor add new default payment method" do
    old_payment_method = @pay_customer.add_payment_method("old", default: true)
    assert_equal old_payment_method.id, @pay_customer.default_payment_method.id

    new_payment_method = nil
    assert_difference "Pay::PaymentMethod.count" do
      new_payment_method = @pay_customer.add_payment_method("new", default: true)
    end

    payment_method = @pay_customer.default_payment_method
    assert_equal new_payment_method.id, payment_method.id
    assert_equal "card", payment_method.payment_method_type
    assert_equal "Fake", payment_method.brand
  end

  test "generates aws processor_id" do
    user = users(:none)
    pay_customer = user.set_payment_processor :aws_processor, allow_fake: true
    assert_nil pay_customer.processor_id
    pay_customer.api_record
    assert_not_nil pay_customer.processor_id
  end

  test "generic trial" do
    user = users(:none)
    pay_customer = user.set_payment_processor :aws_processor, allow_fake: true

    refute pay_customer.on_generic_trial?

    time = 14.days.from_now
    pay_customer.subscribe(trial_ends_at: time, ends_at: time)

    assert pay_customer.on_generic_trial?
  end
end
