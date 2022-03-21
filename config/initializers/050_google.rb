Rails.application.config.after_initialize do
  require 'googleauth'
  require 'google/apis/sheets_v4'

  Google::Apis::RequestOptions.default.retries = 3
  Google::Apis.logger.level = ['development', 'backtest'].include?(Rails.env) ? Logger::DEBUG : Logger::WARN

  $google_authorizer    = Google::Auth::ServiceAccountCredentials.make_creds(scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS)
  $sheets               = Google::Apis::SheetsV4::SheetsService.new
  $sheets.authorization = $google_authorizer
end
