if Rails.env.production?
  %w[API_TOKEN IPSTACK_API_KEY SECRET_KEY_BASE].each do |name|
    raise "#{name} must be configured" if ENV[name].blank?
  end
end
