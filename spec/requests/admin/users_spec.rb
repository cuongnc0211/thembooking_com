require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
  let(:staff) { create(:staff, password: "password123", password_confirmation: "password123") }

  def admin_login(s = staff)
    post admin_sign_in_path, params: { email_address: s.email_address, password: "password123" }, headers: browser_headers
  end

  describe "unauthenticated access" do
    it "redirects to admin sign in" do
      get admin_users_path, headers: browser_headers
      expect(response).to redirect_to(admin_sign_in_path)
    end
  end

  describe "authenticated access" do
    before { admin_login }

    describe "GET /admin/users" do
      it "renders the users list" do
        create(:user)
        get admin_users_path, headers: browser_headers
        expect(response).to have_http_status(:ok)
      end

      it "filters by search query" do
        user_alice = create(:user, name: "Alice Test")
        create(:user, name: "Bob Other")
        get admin_users_path, params: { q: "Alice" }, headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Alice Test")
        expect(response.body).not_to include("Bob Other")
      end

      it "paginates results" do
        get admin_users_path, params: { page: 1 }, headers: browser_headers
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /admin/users/:id" do
      it "shows user details" do
        user = create(:user, :with_business)
        get admin_user_path(user), headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(user.name)
      end

      it "shows user without business" do
        user = create(:user)
        get admin_user_path(user), headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(user.name)
      end
    end

    describe "GET /admin/users/:id/edit" do
      it "renders edit form" do
        user = create(:user)
        get edit_admin_user_path(user), headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(user.email_address)
      end
    end

    describe "PATCH /admin/users/:id" do
      it "updates the user and redirects to show" do
        user = create(:user)
        patch admin_user_path(user), params: { user: { name: "Updated Name" } }, headers: browser_headers
        expect(response).to redirect_to(admin_user_path(user))
        expect(user.reload.name).to eq("Updated Name")
      end

      it "renders edit with unprocessable_entity on invalid data" do
        user = create(:user)
        patch admin_user_path(user), params: { user: { email_address: "" } }, headers: browser_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "DELETE /admin/users/:id" do
      it "deletes the user and redirects to index" do
        user = create(:user)
        expect {
          delete admin_user_path(user), headers: browser_headers
        }.to change(User, :count).by(-1)
        expect(response).to redirect_to(admin_users_path)
      end
    end
  end
end
