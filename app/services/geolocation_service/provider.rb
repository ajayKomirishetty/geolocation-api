module GeolocationService
  class Provider
    def lookup(_query)
      raise NotImplementedError
    end
  end
end