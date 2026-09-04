module Api
  module V1
    class GeolocationsController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound,
                  with: :render_not_found

      rescue_from GeolocationService::ValidationError,
                  with: :render_validation_error

      rescue_from GeolocationService::ProviderError,
                  with: :render_provider_error

      rescue_from GeolocationService::ProviderTimeout,
                  with: :render_provider_timeout

      rescue_from ActiveRecord::RecordInvalid,
                  with: :render_record_invalid

      def index
        validate_lookup_query!
        geolocation = find_geolocation

        if geolocation
          render json: geolocation
        else
          render json: {
            error: "Geolocation not found"
          }, status: :not_found
        end
      end

      def show
        geolocation = Geolocation.find(params[:id])

        render json: geolocation
      end

      def create
        geolocation = GeolocationService::Lookup.new(
          provider: provider
        ).call(
          ip_address: params[:ip_address],
          url: params[:url]
        )

        render json: geolocation, status: :created
      end

      def destroy
        geolocation = Geolocation.find(params[:id])

        geolocation.destroy!

        head :no_content
      end

      private

      def provider
        GeolocationService::IpstackProvider.new(
          api_key: ENV.fetch("IPSTACK_API_KEY")
        )
      end

      def find_geolocation
        if params[:ip].present?
          Geolocation.find_by(ip_address: params[:ip])
        elsif params[:url].present?
          Geolocation.find_by(url: params[:url])
        end
      end

      def validate_lookup_query!
        if params[:ip].blank? && params[:url].blank?
          raise GeolocationService::ValidationError,
                "Provide either ip or url"
        end

        return unless params[:ip].present? && params[:url].present?

        raise GeolocationService::ValidationError,
              "Provide either ip or url, not both"
      end

      def render_not_found
        render json: {
          error: "Geolocation not found"
        }, status: :not_found
      end

      def render_validation_error(error)
        render json: {
          error: error.message
        }, status: :unprocessable_entity
      end

      def render_provider_error(error)
        render json: {
          error: error.message
        }, status: :bad_gateway
      end

      def render_provider_timeout(error)
        render json: {
          error: error.message
        }, status: :gateway_timeout
      end

      def render_record_invalid(error)
        render json: {
          error: error.record.errors.full_messages.to_sentence
        }, status: :unprocessable_entity
      end
    end
  end
end
