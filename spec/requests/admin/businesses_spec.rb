require "rails_helper"

RSpec.describe "Admin::Businesses", type: :request do
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
  let(:staff) { create(:staff, password: "password123", password_confirmation: "password123") }

  def admin_login(s = staff)
    post admin_sign_in_path, params: { email_address: s.email_address, password: "password123" }, headers: browser_headers
  end

  describe "unauthenticated access" do
    it "redirects to admin sign in" do
      get admin_businesses_path, headers: browser_headers
      expect(response).to redirect_to(admin_sign_in_path)
    end
  end

  describe "authenticated access" do
    before { admin_login }

    describe "GET /admin/businesses" do
      it "renders the businesses list" do
        create(:business)
        get admin_businesses_path, headers: browser_headers
        expect(response).to have_http_status(:ok)
      end

      it "filters by search query" do
        create(:business, name: "Alpha Barbers")
        create(:business, name: "Beta Salon")
        get admin_businesses_path, params: { q: "Alpha" }, headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Alpha Barbers")
        expect(response.body).not_to include("Beta Salon")
      end

      it "paginates results" do
        get admin_businesses_path, params: { page: 1 }, headers: browser_headers
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /admin/businesses/:id" do
      it "shows business details" do
        business = create(:business)
        get admin_business_path(business), headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(business.name)
      end
    end

    describe "GET /admin/businesses/:id/edit" do
      it "renders edit form" do
        business = create(:business)
        get edit_admin_business_path(business), headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(business.name)
      end
    end

    describe "PATCH /admin/businesses/:id" do
      it "updates the business and redirects to show" do
        business = create(:business)
        patch admin_business_path(business), params: { business: { name: "Updated Biz" } }, headers: browser_headers
        expect(response).to redirect_to(admin_business_path(business))
        expect(business.reload.name).to eq("Updated Biz")
      end

      it "renders edit with unprocessable_entity on invalid data" do
        business = create(:business)
        patch admin_business_path(business), params: { business: { name: "" } }, headers: browser_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "DELETE /admin/businesses/:id" do
      it "deletes the business and redirects to index" do
        business = create(:business)
        expect {
          delete admin_business_path(business), headers: browser_headers
        }.to change(Business, :count).by(-1)
        expect(response).to redirect_to(admin_businesses_path)
      end
    end
  end
end
