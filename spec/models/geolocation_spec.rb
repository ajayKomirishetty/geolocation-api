require "rails_helper"

RSpec.describe Geolocation, type: :model do
  subject(:geolocation) do
    described_class.new(
      ip_address: "8.8.8.8"
    )
  end

  it "is valid with an IP address" do
    expect(geolocation).to be_valid
  end

  it "is invalid without an IP address or URL" do
    geolocation.ip_address = nil

    expect(geolocation).not_to be_valid
  end

  it "does not allow duplicate IP addresses" do
    described_class.create!(
      ip_address: "8.8.8.8"
    )

    expect(geolocation).not_to be_valid
  end
end
