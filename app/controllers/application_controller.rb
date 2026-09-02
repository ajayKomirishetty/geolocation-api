class ApplicationController < ActionController::API
    before_action :authenticate_request

    private

    def authenticate_request
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")

      unless ActiveSupport::SecurityUtils.secure_compare(
        token.to_s,
        ENV.fetch("API_TOKEN", "")
      )
        render json: {
          error: "Unauthorized"
        }, status: :unauthorized
      end
    end
end
