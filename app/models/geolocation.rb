class Geolocation < ApplicationRecord
    validates :ip_address, uniqueness: true, allow_blank: true
    validates :url, uniqueness: true, allow_blank: true

    validate :ip_address_or_url_present

    private

    def ip_address_or_url_present
      return if ip_address.present? || url.present?

      errors.add(:base, "Either ip_address or url must be provided")
    end
end
