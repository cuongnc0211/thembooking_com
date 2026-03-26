require "rails_helper"

RSpec.describe "Dashboard::ServiceCategories", type: :request do
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
  let(:user) { create(:user, :onboarding_completed) }
  let(:business) { create(:business, user: user) }
  let!(:branch) { create(:branch, business: business) }
  let!(:category) { create(:service_category, branch: branch, name: "Hair") }

  before do
    sign_in(user)
    business
  end

  describe "GET /dashboard/branches/:branch_id/service_categories" do
    it "returns 200 and lists categories" do
      get dashboard_branch_service_categories_path(branch), headers: browser_headers
      expect(response).to have_http_status(:ok)
    end

    it "redirects to sign_in when unauthenticated" do
      delete session_path, headers: browser_headers
      get dashboard_branch_service_categories_path(branch), headers: browser_headers
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /dashboard/branches/:branch_id/service_categories/new" do
    it "renders the new category form" do
      get new_dashboard_branch_service_category_path(branch), headers: browser_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /dashboard/branches/:branch_id/service_categories" do
    context "with valid params (HTML)" do
      it "creates a category and redirects" do
        expect {
          post dashboard_branch_service_categories_path(branch),
               params: { service_category: { name: "Nails" } },
               headers: browser_headers
        }.to change(ServiceCategory, :count).by(1)
        expect(response).to redirect_to(dashboard_branch_service_categories_path(branch))
      end
    end

    context "with valid params (JSON quick-create)" do
      it "returns JSON with id and name" do
        post dashboard_branch_service_categories_path(branch),
             params: { service_category: { name: "Massage" } }.to_json,
             headers: browser_headers.merge(
               "Content-Type" => "application/json",
               "Accept" => "application/json"
             )
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Massage")
        expect(json["id"]).to be_present
      end
    end

    context "with invalid params" do
      it "re-renders form with unprocessable_entity" do
        post dashboard_branch_service_categories_path(branch),
             params: { service_category: { name: "" } },
             headers: browser_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /dashboard/branches/:branch_id/service_categories/:id/edit" do
    it "renders the edit form" do
      get edit_dashboard_branch_service_category_path(branch, category), headers: browser_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /dashboard/branches/:branch_id/service_categories/:id" do
    context "with valid params" do
      it "updates category and redirects" do
        patch dashboard_branch_service_category_path(branch, category),
              params: { service_category: { name: "Updated Hair" } },
              headers: browser_headers
        expect(response).to redirect_to(dashboard_branch_service_categories_path(branch))
        expect(category.reload.name).to eq("Updated Hair")
      end
    end

    context "with invalid params" do
      it "re-renders edit with unprocessable_entity" do
        patch dashboard_branch_service_category_path(branch, category),
              params: { service_category: { name: "" } },
              headers: browser_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /dashboard/branches/:branch_id/service_categories/:id" do
    it "destroys category, nullifies services, and redirects" do
      service = create(:service, branch: branch, service_category: category)

      expect {
        delete dashboard_branch_service_category_path(branch, category), headers: browser_headers
      }.to change(ServiceCategory, :count).by(-1)

      expect(service.reload.service_category_id).to be_nil
      expect(response).to redirect_to(dashboard_branch_service_categories_path(branch))
    end
  end

  describe "service assignment" do
    it "assigns selected services to category on create" do
      service = create(:service, branch: branch)
      post dashboard_branch_service_categories_path(branch),
           params: { service_category: { name: "Spa", service_ids: [ service.id ] } },
           headers: browser_headers

      expect(service.reload.service_category_id).to eq(ServiceCategory.last.id)
    end

    it "reassigns services on update" do
      service1 = create(:service, branch: branch, service_category: category)
      service2 = create(:service, branch: branch, name: "Service B")

      patch dashboard_branch_service_category_path(branch, category),
            params: { service_category: { name: "Hair", service_ids: [ service2.id ] } },
            headers: browser_headers

      expect(service1.reload.service_category_id).to be_nil
      expect(service2.reload.service_category_id).to eq(category.id)
    end
  end

  describe "cross-branch isolation" do
    it "returns not_found for a category belonging to another business's branch" do
      other_branch = create(:branch)
      other_category = create(:service_category, branch: other_branch)

      get edit_dashboard_branch_service_category_path(other_branch, other_category),
          headers: browser_headers
      # set_branch redirects when the branch doesn't belong to current user's business
      expect(response).to redirect_to(dashboard_branches_path)
    end
  end
end
