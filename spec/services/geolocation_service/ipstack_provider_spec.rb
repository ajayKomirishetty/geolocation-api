require "rails_helper"

RSpec.describe GeolocationService::IpstackProvider do
  let(:provider) do
    described_class.new(api_key: "test-api-key")
  end

  it "returns normalized geolocation data" do
    stub_request(
      :get,
      %r{api\.ipstack\.com/8\.8\.8\.8}
    ).to_return(
      status: 200,
      body: {
        success: true,
        country_name: "United States",
        region_name: "California",
        city: "Mountain View",
        latitude: 37.386,
        longitude: -122.0838
      }.to_json
    )

    result = provider.lookup("8.8.8.8")

    expect(result).to eq(
      country: "United States",
      region: "California",
      city: "Mountain View",
      latitude: 37.386,
      longitude: -122.0838
    )
  end

  it "raises ProviderError when ipstack fails" do
    stub_request(
      :get,
      %r{api\.ipstack\.com/8\.8\.8\.8}
    ).to_return(
      status: 500,
      body: "Internal Server Error"
    )

    expect {
      provider.lookup("8.8.8.8")
    }.to raise_error(
      GeolocationService::ProviderError
    )
  end
end
