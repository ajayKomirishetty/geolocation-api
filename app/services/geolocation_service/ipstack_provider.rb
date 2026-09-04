require "net/http"
require "json"
require "uri"

module GeolocationService
  class IpstackProvider < Provider
    BASE_URL = "http://api.ipstack.com"
    OPEN_TIMEOUT_SECONDS = 5
    READ_TIMEOUT_SECONDS = 10

    def initialize(api_key:)
      @api_key = api_key
    end

    def lookup(ip_address)
      response = make_request(ip_address)

      parse_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Timeout::Error
      raise ProviderTimeout, "Ipstack request timed out"
    rescue SocketError, EOFError, Errno::ECONNREFUSED, Errno::ECONNRESET,
           Errno::EHOSTUNREACH, Errno::ENETUNREACH
      raise ProviderError, "Unable to reach Ipstack"
    end

    private

    def make_request(ip_address)
      uri = URI("#{BASE_URL}/#{ip_address}")

      params = {
        access_key: @api_key,
        format: 1
      }

      uri.query = URI.encode_www_form(params)

      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: OPEN_TIMEOUT_SECONDS,
        read_timeout: READ_TIMEOUT_SECONDS,
        write_timeout: READ_TIMEOUT_SECONDS
      ) { |http| http.request(Net::HTTP::Get.new(uri)) }
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
