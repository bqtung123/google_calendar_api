class ExampleController < ApplicationController
  require 'google/apis/calendar_v3'
  require 'google/api_client/client_secrets'

  def get_google_calendar_client
    client = Google::Apis::CalendarV3::CalendarService.new
    return unless current_user.present? && current_user.oauth_token.present? && current_user.refresh_token.present?

    secrets = Google::APIClient::ClientSecrets.new({
                                                     'web' => {
                                                       'access_token' => current_user.oauth_token,
                                                       'refresh_token' => current_user.refresh_token,
                                                       'client_id' => ENV['GOOGLE_CLIENT_ID'],
                                                       'client_secret' => ENV['GOOGLE_SECRET']
                                                     }
                                                   })

    begin
      client.authorization = secrets.to_authorization
      client.authorization.grant_type = 'refresh_token'

      if current_user.expired?
        client.authorization.refresh!
        binding.pry
        current_user.update(
          oauth_token: client.authorization.access_token,
          refresh_token: client.authorization.refresh_token,
          oauth_expires_at: Time.at(auth.credentials.expires_at)
        )
      end
    rescue StandardError => e
      puts e.message
    end
    binding.pry
    render json: { success: true }
  end
end
