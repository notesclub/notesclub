# frozen_string_literal: true

creds = Aws::Credentials.new(ENV["AWS_SES_ACCESS_KEY_ID"], ENV["AWS_SES_SECRET_ACCESS_KEY"])

Aws::Rails.add_action_mailer_delivery_method(
  :ses,
  credentials: creds,
  region: "eu-central-1"
)
