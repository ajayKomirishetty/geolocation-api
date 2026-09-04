require "rails_helper"

RSpec.describe "Geolocations API", type: :request do
  let(:headers) { { "Authorization" => "Bearer test-api-token" } }

  describe "authentication" do
    it "rejects missing credentials" do
      get "/api/v1/geolocations", params: { ip: "8.8.8.8" }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq("error" => "Unauthorized")
    end

    it "rejects invalid credentials" do
      get "/api/v1/geolocations",
          params: { ip: "8.8.8.8" },
          headers: { "Authorization" => "Bearer wrong-token" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

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
           as: :json,
           headers: headers

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)

      expect(body["ip_address"]).to eq("8.8.8.8")
      expect(body["country"]).to eq("United States")
    end

    it "rejects an empty request" do
      post "/api/v1/geolocations",
           params: {},
           as: :json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)

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
           as: :json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects an invalid IP address" do
      post "/api/v1/geolocations",
           params: {
             ip_address: "999.999.999.999"
           },
           as: :json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "creates a geolocation from a URL" do
      allow(GeolocationService::UrlResolver)
        .to receive(:resolve)
        .with("example.com")
        .and_return("8.8.4.4")
      allow(provider).to receive(:lookup).with("8.8.4.4").and_return(
        country: "United States", region: "California", city: "Mountain View",
        latitude: 37.386, longitude: -122.0838
      )

      post "/api/v1/geolocations",
           params: { url: "example.com" },
           as: :json,
           headers: headers

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["url"]).to eq("example.com")
    end

    it "returns 504 when the provider times out" do
      allow(provider)
        .to receive(:lookup)
        .with("9.9.9.9")
        .and_raise(
          GeolocationService::ProviderTimeout,
          "Ipstack request timed out"
        )

      post "/api/v1/geolocations",
           params: { ip_address: "9.9.9.9" },
           as: :json,
           headers: headers

      expect(response).to have_http_status(:gateway_timeout)
      expect(JSON.parse(response.body)["error"]).to eq("Ipstack request timed out")
    end
  end

  describe "GET /api/v1/geolocations" do
    it "retrieves a geolocation by IP" do
      record = create(:geolocation, ip_address: "8.8.8.8", url: nil)

      get "/api/v1/geolocations", params: { ip: record.ip_address }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(record.id)
    end

    it "rejects an ambiguous or empty lookup" do
      get "/api/v1/geolocations", headers: headers
      expect(response).to have_http_status(:unprocessable_content)

      get "/api/v1/geolocations",
          params: { ip: "8.8.8.8", url: "example.com" }, headers: headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /api/v1/geolocations/:id" do
    it "deletes a stored geolocation" do
      record = create(:geolocation, ip_address: "8.8.8.8", url: nil)

      delete "/api/v1/geolocations/#{record.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(Geolocation.find_by(id: record.id)).to be_nil
    end
  end
end
