require "net/http"
require "json"
require "uri"

module GeolocationService
  class IpstackProvider < Provider
    BASE_URL = "http://api.ipstack.com"

    def initialize(api_key:)
      @api_key = api_key
    end

    def lookup(ip_address)
      response = make_request(ip_address)

      parse_response(response)
    end

    private

    def make_request(ip_address)
      uri = URI("#{BASE_URL}/#{ip_address}")

      params = {
        access_key: @api_key,
        format: 1
      }

      uri.query = URI.encode_www_form(params)

      Net::HTTP.get_response(uri)
    end

    def parse_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        raise ProviderError, "Ipstack returned HTTP #{response.code}"
      end

      body = JSON.parse(response.body)

      if body["success"] == false
        raise ProviderError, body["error"]&.fetch("info", "Ipstack request failed")
      end

      {
        country: body["country_name"],
        region: body["region_name"],
        city: body["city"],
        latitude: body["latitude"],
        longitude: body["longitude"]
      }
    rescue JSON::ParserError
      raise ProviderError, "Ipstack returned invalid JSON"
    end
  end
end