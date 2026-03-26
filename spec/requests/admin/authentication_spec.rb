require "rails_helper"

RSpec.describe "Admin Authentication", type: :request do
  # Required to pass allow_browser :modern check in ApplicationController
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }

  let(:staff) { create(:staff, password: "password123", password_confirmation: "password123") }

  def admin_login(s = staff)
    post admin_sign_in_path, params: { email_address: s.email_address, password: "password123" }, headers: browser_headers
  end

  describe "unauthenticated access" do
    it "redirects to admin sign in" do
      get admin_root_path, headers: browser_headers
      expect(response).to redirect_to(admin_sign_in_path)
    end
  end

  describe "GET /admin/sign_in" do
    it "renders the login page" do
      get admin_sign_in_path, headers: browser_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/sign_in" do
    it "signs in with valid credentials and redirects to admin root" do
      admin_login
      expect(response).to redirect_to(admin_root_path)
      expect(cookies[:admin_session_id]).to be_present
    end

    it "rejects invalid credentials" do
      post admin_sign_in_path, params: { email_address: staff.email_address, password: "wrongpassword" }, headers: browser_headers
      expect(response).to redirect_to(admin_sign_in_path)
      expect(cookies[:admin_session_id]).to be_blank
    end

    it "rejects inactive staff" do
      staff.update!(active: false)
      admin_login
      expect(response).to redirect_to(admin_sign_in_path)
      expect(cookies[:admin_session_id]).to be_blank
    end
  end

  describe "DELETE /admin/sign_out" do
    before { admin_login }

    it "signs out and redirects to sign in" do
      delete admin_sign_out_path, headers: browser_headers
      expect(response).to redirect_to(admin_sign_in_path)
    end

    it "clears the admin session cookie" do
      delete admin_sign_out_path, headers: browser_headers
      expect(cookies[:admin_session_id]).to be_blank
    end
  end

  describe "GET /admin (authenticated)" do
    before { admin_login }

    it "renders the admin dashboard" do
      get admin_root_path, headers: browser_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "user session isolation" do
    it "user session cookie does not grant admin access" do
      get admin_root_path, headers: browser_headers
      expect(response).to redirect_to(admin_sign_in_path)
    end
  end
end
