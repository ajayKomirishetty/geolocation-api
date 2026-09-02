class CreateGeolocations < ActiveRecord::Migration[8.1]
  def change
    create_table :geolocations do |t|
      t.string :ip_address
      t.string :url
      t.string :country
      t.string :region
      t.string :city
      t.decimal :latitude
      t.decimal :longitude
      t.string :provider

      t.timestamps
    end

    add_index :geolocations, :ip_address, unique: true
    add_index :geolocations, :url, unique: true
  end
end
