class ApplicationController < ActionController::API
  # If sign-in is successful, no other authentication method will be run, but if it
  # doesn't (the authentication params were missing, or incorrect) then Devise takes
  # control and tries to authenticate_user! with its own modules. That behaviour can
  # however be modified for any controller through the fallback option (which defaults
  # to fallback: :devise).
  #
  # When fallback: :exception is set, then an exception is raised on token authentication
  # failure. The resulting controller behaviour is very similar to the behaviour induced
  # by using the Devise authenticate_user! callback instead of authenticate_user. That
  # setting allows, for example, to prevent unauthenticated users to accede API
  # controllers while disabling the default fallback to Devise.
  #
  # Important: Please do notice that controller actions without CSRF protection must
  # disable the Devise fallback for security reasons (both fallback: :exception and
  # fallback: :none will disable the Devise fallback). Since Rails enables CSRF
  # protection by default, this configuration requirement should only affect controllers
  # where you have disabled it specifically, which may be the case of API controllers.
  acts_as_token_authentication_handler_for User, fallback: :exception, unless: lambda { |controller| ['PublicController'].include?(controller.class.to_s) }
end
