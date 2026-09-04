# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
unless Rails.env.test?
  Geolocation.find_or_create_by!(ip_address: "8.8.8.8") do |geolocation|
    geolocation.country = "United States"
    geolocation.region = "California"
    geolocation.city = "Mountain View"
    geolocation.latitude = 37.386
    geolocation.longitude = -122.0838
    geolocation.provider = "seed"
  end
end
