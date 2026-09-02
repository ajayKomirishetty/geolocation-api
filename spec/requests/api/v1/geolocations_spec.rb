require "rails_helper"

RSpec.describe "Geolocations API", type: :request do
  describe "POST /api/v1/geolocations" do
    let(:provider) { instance_double(GeolocationService::IpstackProvider) }

    before do
      allow(GeolocationService::IpstackProvider)
        .to receive(:new)
        .and_return(provider)
    end

    it "creates a geolocation from an IP address" do
      allow(provider)
        .to receive(:lookup)
        .with("8.8.8.8")
        .and_return(
          country: "United States",
          region: "California",
          city: "Mountain View",
          latitude: 37.386,
          longitude: -122.0838
        )

      post "/api/v1/geolocations",
           params: { ip_address: "8.8.8.8" },
           as: :json

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)

      expect(body["ip_address"]).to eq("8.8.8.8")
      expect(body["country"]).to eq("United States")
    end

    it "rejects an empty request" do
      post "/api/v1/geolocations",
           params: {},
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)

      body = JSON.parse(response.body)

      expect(body["error"])
        .to eq("Either ip_address or url must be provided")
    end

    it "rejects both ip and url" do
      post "/api/v1/geolocations",
           params: {
             ip_address: "8.8.8.8",
             url: "example.com"
           },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an invalid IP address" do
      post "/api/v1/geolocations",
           params: {
             ip_address: "999.999.999.999"
           },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end