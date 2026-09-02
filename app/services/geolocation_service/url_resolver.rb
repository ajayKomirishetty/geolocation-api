require "uri"
require "resolv"

module GeolocationService
  class UrlResolver
    def self.resolve(url)
      hostname = normalize(url)

      Resolv.getaddress(hostname)
    rescue Resolv::ResolvError
      raise ValidationError, "Unable to resolve URL"
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