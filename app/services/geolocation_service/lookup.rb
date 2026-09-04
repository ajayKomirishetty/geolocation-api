module GeolocationService
    class Lookup
      def initialize(provider:)
        @provider = provider
      end

      def call(ip_address: nil, url: nil)
        validate_input!(ip_address, url)

        ip_address = resolve_ip(ip_address, url)

        existing = Geolocation.find_by(ip_address: ip_address)

        if existing
          existing.update!(url: url) if url.present? && existing.url.blank?
          return existing
        end

        location = @provider.lookup(ip_address)

        Geolocation.create!(
          ip_address: ip_address,
          url: url,
          country: location[:country],
          region: location[:region],
          city: location[:city],
          latitude: location[:latitude],
          longitude: location[:longitude],
          provider: provider_name
        )
      rescue ActiveRecord::RecordNotUnique
        Geolocation.find_by!(ip_address: ip_address)
      end

      private

      def validate_input!(ip_address, url)
        if ip_address.blank? && url.blank?
          raise ValidationError,
                "Either ip_address or url must be provided"
        end

        if ip_address.present? && url.present?
          raise ValidationError,
                "Provide either ip_address or url, not both"
        end

        if ip_address.present? &&
           !IpValidator.valid?(ip_address)
          raise ValidationError,
                "Invalid IP address"
        end
      end

      def resolve_ip(ip_address, url)
        return ip_address if ip_address.present?

        UrlResolver.resolve(url)
      end

      def provider_name
        @provider.class.name.demodulize.underscore
      end
    end
end
