require "ipaddr"

module GeolocationService
  class IpValidator
    def self.valid?(ip_address)
      IPAddr.new(ip_address)
      true
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end