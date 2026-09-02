FactoryBot.define do
  factory :geolocation do
    ip_address { "MyString" }
    url { "MyString" }
    country { "MyString" }
    region { "MyString" }
    city { "MyString" }
    latitude { "9.99" }
    longitude { "9.99" }
    provider { "MyString" }
  end
end
