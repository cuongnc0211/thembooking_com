require "rails_helper"

RSpec.describe "Dashboard::Branches", type: :request do
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
  let(:user) { create(:user, :onboarding_completed) }
  let(:business) { create(:business, user: user) }
  let!(:branch) { create(:branch, business: business) }

  let(:valid_params) do
    {
      branch: {
        name: "New Branch",
        slug: "new-branch",
        address: "123 Test St",
        phone: "+84 123 456 789",
        capacity: 3
      }
    }
  end

  before do
    sign_in(user)
    business # ensure business exists
  end

  describe "GET /dashboard/branches" do
    it "returns 200 and lists branches" do
      get dashboard_branches_path, headers: browser_headers
      expect(response).to have_http_status(:ok)
    end

    it "redirects to sign_in when unauthenticated" do
      delete session_path, headers: browser_headers
      get dashboard_branches_path, headers: browser_headers
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /dashboard/branches/new" do
    it "renders the new branch form" do
      get new_dashboard_branch_path, headers: browser_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /dashboard/branches" do
    context "with valid params" do
      it "creates a branch and redirects" do
        expect {
          post dashboard_branches_path, params: valid_params, headers: browser_headers
        }.to change(Branch, :count).by(1)
        expect(response).to redirect_to(dashboard_branch_path(Branch.last))
      end
    end

    context "with invalid params" do
      it "re-renders the form with unprocessable_entity status" do
        post dashboard_branches_path, params: { branch: { name: "" } }, headers: browser_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /dashboard/branches/:id" do
    it "renders the branch show page" do
      get dashboard_branch_path(branch), headers: browser_headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for another user's branch" do
      other_branch = create(:branch)
      get dashboard_branch_path(other_branch), headers: browser_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /dashboard/branches/:id/edit" do
    it "renders the edit form" do
      get edit_dashboard_branch_path(branch), headers: browser_headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for another user's branch" do
      other_branch = create(:branch)
      get edit_dashboard_branch_path(other_branch), headers: browser_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /dashboard/branches/:id" do
    it "updates the branch and redirects" do
      patch dashboard_branch_path(branch), params: { branch: { name: "Updated Name" } }, headers: browser_headers
      expect(response).to redirect_to(dashboard_branch_path(branch))
      expect(branch.reload.name).to eq("Updated Name")
    end

    it "re-renders form on invalid params" do
      patch dashboard_branch_path(branch), params: { branch: { name: "" } }, headers: browser_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 404 for another user's branch" do
      other_branch = create(:branch)
      patch dashboard_branch_path(other_branch), params: { branch: { name: "Hack" } }, headers: browser_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /dashboard/branches/:id" do
    it "deactivates the branch when another active branch exists" do
      # Need a second active branch so the guard allows deactivation
      create(:branch, business: business, active: true)
      delete dashboard_branch_path(branch), headers: browser_headers
      expect(response).to redirect_to(dashboard_branches_path)
      expect(branch.reload.active).to be false
    end

    it "prevents deactivating the last active branch" do
      delete dashboard_branch_path(branch), headers: browser_headers
      expect(response).to redirect_to(dashboard_branches_path)
      expect(branch.reload.active).to be true
    end

    it "returns 404 for another user's branch" do
      other_branch = create(:branch)
      delete dashboard_branch_path(other_branch), headers: browser_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
