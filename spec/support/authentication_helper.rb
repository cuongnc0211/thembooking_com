module AuthenticationHelper
  MODERN_BROWSER_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  def sign_in(user)
    post session_path, params: {
      email_address: user.email_address,
      password: "password123" # Default password from factory
    }, headers: { "User-Agent" => MODERN_BROWSER_USER_AGENT }
  end

  def sign_out
    delete session_path, headers: { "User-Agent" => MODERN_BROWSER_USER_AGENT }
  end

  def sign_in_admin(staff)
    post admin_sign_in_path, params: {
      email_address: staff.email_address,
      password: "password123"
    }, headers: { "User-Agent" => MODERN_BROWSER_USER_AGENT }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request

  # No global header injection needed — use browser_headers helper in request specs
end
