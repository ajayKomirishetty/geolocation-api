module GeolocationService
  class LookupService
    def initialize(provider:)
      @provider = provider
    end

    def call(ip_address: nil, url: nil)
      validate_input!(ip_address, url)

      ip_address = resolve_ip(ip_address, url)

      existing = GeolocationRecord.find_by(ip_address: ip_address)

      return existing if existing

      data = @provider.lookup(ip_address)

      GeolocationRecord.create!(
        ip_address: ip_address,
        url: url,
        country: data[:country],
        region: data[:region],
        city: data[:city],
        latitude: data[:latitude],
        longitude: data[:longitude],
        provider: @provider.class.name.demodulize.underscore
      )
    end

    private

    def validate_input!(ip_address, url)
      if ip_address.blank? && url.blank?
        raise ValidationError, "Either ip_address or url must be provided"
      end

      if ip_address.present? && url.present?
        raise ValidationError, "Provide either ip_address or url, not both"
      end
    end

    def resolve_ip(ip_address, url)
      return ip_address if ip_address.present?

      UrlResolver.resolve(url)
    end
  end
end