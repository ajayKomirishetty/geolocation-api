class ApplicationController < ActionController::API
    before_action :authenticate_request

    private

    def authenticate_request
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")
      expected_token = ENV["API_TOKEN"].to_s

      if expected_token.blank? || token.blank? || !ActiveSupport::SecurityUtils.secure_compare(token, expected_token)
        render json: {
          error: "Unauthorized"
        }, status: :unauthorized
      end
    end
end
