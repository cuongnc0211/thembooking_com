require "rails_helper"

RSpec.describe "Dashboard::Businesses", type: :request do
  let(:user) { create(:user) }

  # Helper to simulate logged in user
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "authentication" do
    it "redirects to login when not authenticated" do
      get new_dashboard_business_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /user/business/new" do
    before { sign_in(user) }

    context "when user has no business" do
      it "renders the new business form" do
        get new_dashboard_business_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user already has a business" do
      before { create(:business, user: user) }

      it "redirects to edit page" do
        get new_dashboard_business_path
        expect(response).to redirect_to(edit_dashboard_business_path)
      end
    end
  end

  describe "POST /user/business" do
    before { sign_in(user) }

    context "with valid params" do
      let(:valid_params) do
        {
          business: {
            name: "John's Barbershop",
            slug: "johns-barbershop",
            business_type: "barber",
            description: "Best barbershop in town",
            address: "123 Main St, Ho Chi Minh City",
            phone: "+84 123 456 789",
            capacity: 3
          }
        }
      end

      it "creates a new business" do
        expect {
          post dashboard_business_path, params: valid_params
        }.to change(Business, :count).by(1)
      end

      it "associates business with current user" do
        post dashboard_business_path, params: valid_params
        expect(Business.last.user).to eq(user)
      end

      it "redirects to business show page with success message" do
        post dashboard_business_path, params: valid_params
        expect(response).to redirect_to(dashboard_business_path)
        follow_redirect!
        expect(response.body).to include("Business created successfully")
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          business: {
            name: "",
            slug: "",
            business_type: "barber"
          }
        }
      end

      it "does not create a business" do
        expect {
          post dashboard_business_path, params: invalid_params
        }.not_to change(Business, :count)
      end

      it "renders the new form with errors" do
        post dashboard_business_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when user already has a business" do
      before { create(:business, user: user) }

      it "does not create another business" do
        expect {
          post dashboard_business_path, params: {
            business: { name: "Another Shop", slug: "another-shop", business_type: "salon" }
          }
        }.not_to change(Business, :count)
      end

      it "redirects to edit page" do
        post dashboard_business_path, params: {
          business: { name: "Another Shop", slug: "another-shop", business_type: "salon" }
        }
        expect(response).to redirect_to(edit_dashboard_business_path)
      end
    end
  end

  describe "GET /user/business" do
    before { sign_in(user) }

    context "when user has a business" do
      let!(:business) { create(:business, user: user, name: "My Shop") }

      it "renders the business show page" do
        get dashboard_business_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("My Shop")
      end
    end

    context "when user has no business" do
      it "redirects to new business page" do
        get dashboard_business_path
        expect(response).to redirect_to(new_dashboard_business_path)
      end
    end
  end

  describe "GET /user/business/edit" do
    before { sign_in(user) }

    context "when user has a business" do
      let!(:business) { create(:business, user: user) }

      it "renders the edit form" do
        get edit_dashboard_business_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user has no business" do
      it "redirects to new business page" do
        get edit_dashboard_business_path
        expect(response).to redirect_to(new_dashboard_business_path)
      end
    end
  end

  describe "PATCH /user/business" do
    before { sign_in(user) }

    context "when user has a business" do
      let!(:business) { create(:business, user: user, name: "Old Name") }

      context "with valid params" do
        it "updates the business" do
          patch dashboard_business_path, params: { business: { name: "New Name" } }
          expect(business.reload.name).to eq("New Name")
        end

        it "updates capacity" do
          patch dashboard_business_path, params: { business: { capacity: 5 } }
          expect(business.reload.capacity).to eq(5)
        end

        it "redirects to show page with success message" do
          patch dashboard_business_path, params: { business: { name: "New Name" } }
          expect(response).to redirect_to(dashboard_business_path)
        end
      end

      context "with invalid params" do
        it "does not update the business" do
          patch dashboard_business_path, params: { business: { name: "" } }
          expect(business.reload.name).to eq("Old Name")
        end

        it "renders edit form with errors" do
          patch dashboard_business_path, params: { business: { name: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user has no business" do
      it "redirects to new business page" do
        patch dashboard_business_path, params: { business: { name: "Test" } }
        expect(response).to redirect_to(new_dashboard_business_path)
      end
    end
  end

  describe "slug validation" do
    before { sign_in(user) }

    it "rejects duplicate slugs" do
      create(:business, slug: "taken-slug")

      post dashboard_business_path, params: {
        business: { name: "My Shop", slug: "taken-slug", business_type: "barber" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "normalizes slug to lowercase" do
      post dashboard_business_path, params: {
        business: { name: "My Shop", slug: "MY-SHOP", business_type: "barber" }
      }

      expect(Business.last.slug).to eq("my-shop")
    end
  end

  describe "operating hours updates" do
    before { sign_in(user) }

    let!(:business) { create(:business, user: user) }

    describe "updating with valid operating hours" do
      it "updates operating hours successfully" do
        operating_hours_params = {
          monday: { open: "10:00", close: "18:00", closed: false, breaks: [] },
          tuesday: { open: "10:00", close: "18:00", closed: false, breaks: [] },
          wednesday: { open: "10:00", close: "18:00", closed: false, breaks: [] },
          thursday: { open: "10:00", close: "18:00", closed: false, breaks: [] },
          friday: { open: "10:00", close: "18:00", closed: false, breaks: [] },
          saturday: { open: "10:00", close: "16:00", closed: false, breaks: [] },
          sunday: { open: nil, close: nil, closed: true, breaks: [] }
        }

        patch dashboard_business_path, params: {
          business: { operating_hours: operating_hours_params }
        }

        expect(response).to redirect_to(dashboard_business_path)
        expect(business.reload.operating_hours["monday"]["open"]).to eq("10:00")
        expect(business.reload.operating_hours["monday"]["close"]).to eq("18:00")
      end

      it "updates with break times successfully" do
        operating_hours_params = {
          monday: {
            open: "09:00",
            close: "19:00",
            closed: false,
            breaks: [
              { start: "12:00", end: "13:00" },
              { start: "17:00", end: "17:30" }
            ]
          },
          tuesday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          wednesday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          thursday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          friday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          saturday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          sunday: { open: nil, close: nil, closed: true, breaks: [] }
        }

        patch dashboard_business_path, params: {
          business: { operating_hours: operating_hours_params }
        }

        expect(response).to redirect_to(dashboard_business_path)

        monday_hours = business.reload.operating_hours["monday"]
        expect(monday_hours["breaks"].size).to eq(2)
        expect(monday_hours["breaks"][0]["start"]).to eq("12:00")
        expect(monday_hours["breaks"][0]["end"]).to eq("13:00")
        expect(monday_hours["breaks"][1]["start"]).to eq("17:00")
        expect(monday_hours["breaks"][1]["end"]).to eq("17:30")
      end

      it "preserves times when marking day as closed" do
        operating_hours_params = {
          monday: { open: "09:00", close: "17:00", closed: true, breaks: [] },
          tuesday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          wednesday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          thursday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          friday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          saturday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          sunday: { open: nil, close: nil, closed: true, breaks: [] }
        }

        patch dashboard_business_path, params: {
          business: { operating_hours: operating_hours_params }
        }

        expect(response).to redirect_to(dashboard_business_path)

        monday = business.reload.operating_hours["monday"]
        expect(monday["closed"]).to be true
        expect(monday["open"]).to eq("09:00")
        expect(monday["close"]).to eq("17:00")
      end
    end

    describe "updating with invalid operating hours" do
      it "rejects when close time is before open time" do
        operating_hours_params = {
          monday: { open: "17:00", close: "09:00", closed: false, breaks: [] },
          tuesday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          wednesday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          thursday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          friday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          saturday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          sunday: { open: nil, close: nil, closed: true, breaks: [] }
        }

        patch dashboard_business_path, params: {
          business: { operating_hours: operating_hours_params }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("closing time must be after opening time")
      end

      it "rejects breaks outside operating hours" do
        operating_hours_params = {
          monday: {
            open: "09:00",
            close: "17:00",
            closed: false,
            breaks: [
              { start: "08:00", end: "09:00" }
            ]
          },
          tuesday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          wednesday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          thursday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          friday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          saturday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          sunday: { open: nil, close: nil, closed: true, breaks: [] }
        }

        patch dashboard_business_path, params: {
          business: { operating_hours: operating_hours_params }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("break must be within operating hours")
      end

      it "rejects overlapping breaks" do
        operating_hours_params = {
          monday: {
            open: "09:00",
            close: "17:00",
            closed: false,
            breaks: [
              { start: "12:00", end: "13:30" },
              { start: "13:00", end: "14:00" }
            ]
          },
          tuesday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          wednesday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          thursday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          friday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          saturday: { open: "09:00", close: "17:00", closed: false, breaks: [] },
          sunday: { open: nil, close: nil, closed: true, breaks: [] }
        }

        patch dashboard_business_path, params: {
          business: { operating_hours: operating_hours_params }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("overlapping break times")
      end
    end
  end
end
