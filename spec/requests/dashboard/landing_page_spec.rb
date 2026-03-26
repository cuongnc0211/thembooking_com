require "rails_helper"

RSpec.describe "Dashboard::LandingPage", type: :request do
  let(:user) { create(:user, :onboarding_completed) }
  let!(:business) { create(:business, user: user, slug: "my-shop", headline: "Welcome", theme_color: "#4f46e5") }

  before { sign_in(user) }

  describe "GET /dashboard/business/landing_page/edit" do
    it "returns 200 and renders the edit form" do
      get edit_dashboard_business_landing_page_path
      expect(response).to have_http_status(:ok)
    end

    it "pre-fills business values in the form" do
      get edit_dashboard_business_landing_page_path
      expect(response.body).to include("my-shop")
      expect(response.body).to include("Welcome")
    end
  end

  describe "PATCH /dashboard/business/landing_page" do
    context "with valid params" do
      it "updates slug and redirects with notice" do
        patch dashboard_business_landing_page_path,
              params: { business: { slug: "new-slug", headline: "Hello", description: "", theme_color: "#ff0000" } }

        expect(response).to redirect_to(edit_dashboard_business_landing_page_path)
        follow_redirect!
        expect(response.body).to include("Landing page updated successfully!")
        expect(business.reload.slug).to eq("new-slug")
      end

      it "updates headline and theme_color" do
        patch dashboard_business_landing_page_path,
              params: { business: { slug: business.slug, headline: "New Headline", description: "", theme_color: "#123456" } }

        expect(response).to redirect_to(edit_dashboard_business_landing_page_path)
        expect(business.reload.headline).to eq("New Headline")
        expect(business.reload.theme_color).to eq("#123456")
      end

      it "persists landing_page_config toggles" do
        patch dashboard_business_landing_page_path,
              params: {
                business: { slug: business.slug, headline: "", description: "", theme_color: "#4f46e5" },
                landing_page_config: { show_services: "1", show_gallery: "0", show_hours: "1", show_contact: "0", custom_cta_text: "Reserve Now" }
              }

        expect(response).to redirect_to(edit_dashboard_business_landing_page_path)
        config = business.reload.landing_page_config
        expect(config["show_services"]).to eq(true)
        expect(config["show_gallery"]).to eq(false)
        expect(config["custom_cta_text"]).to eq("Reserve Now")
      end

      it "merges landing_page_config without wiping unrelated keys" do
        business.update!(landing_page_config: { "existing_key" => "preserved" })

        patch dashboard_business_landing_page_path,
              params: {
                business: { slug: business.slug, headline: "", description: "", theme_color: "#4f46e5" },
                landing_page_config: { show_services: "1" }
              }

        config = business.reload.landing_page_config
        expect(config["existing_key"]).to eq("preserved")
        expect(config["show_services"]).to eq(true)
      end
    end

    context "with invalid params" do
      it "re-renders edit with 422 when slug format is invalid" do
        patch dashboard_business_landing_page_path,
              params: { business: { slug: "INVALID SLUG!", headline: "", description: "", theme_color: "#4f46e5" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders edit with 422 when theme_color format is invalid" do
        patch dashboard_business_landing_page_path,
              params: { business: { slug: business.slug, headline: "", description: "", theme_color: "notacolor" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "unauthenticated access" do
    before { sign_out }

    it "redirects GET edit to sign in" do
      get edit_dashboard_business_landing_page_path
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects PATCH update to sign in" do
      patch dashboard_business_landing_page_path,
            params: { business: { slug: "x" } }
      expect(response).to redirect_to(new_session_path)
    end
  end
end
