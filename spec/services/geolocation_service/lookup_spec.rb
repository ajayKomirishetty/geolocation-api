require "rails_helper"

RSpec.describe GeolocationService::Lookup do
  let(:provider) { instance_double(GeolocationService::Provider) }

  subject(:service) do
    described_class.new(provider: provider)
  end

  let(:location) do
    {
      country: "United States",
      region: "California",
      city: "Mountain View",
      latitude: 37.386,
      longitude: -122.0838
    }
  end

  it "creates a geolocation using the provider" do
    allow(provider)
      .to receive(:lookup)
      .with("8.8.8.8")
      .and_return(location)

    result = service.call(ip_address: "8.8.8.8")

    expect(result).to be_persisted
    expect(result.ip_address).to eq("8.8.8.8")
    expect(result.country).to eq("United States")
  end

  it "returns an existing geolocation without calling provider" do
    existing = Geolocation.create!(
      ip_address: "8.8.8.8",
      country: "United States",
      region: "California",
      city: "Mountain View",
      latitude: 37.386,
      longitude: -122.0838,
      provider: "ipstack_provider"
    )

    expect(provider).not_to receive(:lookup)

    result = service.call(ip_address: "8.8.8.8")

    expect(result).to eq(existing)
  end
end