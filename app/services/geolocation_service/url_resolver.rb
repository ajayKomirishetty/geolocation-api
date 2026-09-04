require "uri"
require "resolv"
require "timeout"

module GeolocationService
  class UrlResolver
    RESOLUTION_TIMEOUT_SECONDS = 5

    def self.resolve(url)
      hostname = normalize(url)

      Timeout.timeout(RESOLUTION_TIMEOUT_SECONDS) { Resolv.getaddress(hostname) }
    rescue Resolv::ResolvError
      raise ValidationError, "Unable to resolve URL"
    rescue Timeout::Error
      raise ValidationError, "URL resolution timed out"
    end

    def self.normalize(url)
      value = url.strip

      value = "http://#{value}" unless value.match?(%r{\Ahttps?://}i)

      uri = URI.parse(value)

      raise ValidationError, "Invalid URL" if uri.host.blank?

      uri.host
    rescue URI::InvalidURIError
      raise ValidationError, "Invalid URL"
    end
  end
end
