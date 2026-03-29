require "rails_helper"

RSpec.describe "Admin::PromotionCodes", type: :request do
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
  let(:super_admin) { create(:staff, :super_admin, password: "password123", password_confirmation: "password123") }
  let(:developer_staff) { create(:staff, :developer, password: "password123", password_confirmation: "password123") }

  def admin_login(s = super_admin)
    post admin_sign_in_path, params: { email_address: s.email_address, password: "password123" }, headers: browser_headers
  end

  let(:valid_params) do
    {
      promotion_code: {
        code: "TESTCODE",
        discount_type: "percentage",
        discount_value: 15,
        usage_limit: "",
        valid_from: "",
        valid_until: "",
        active: true,
        description: "Test promotion"
      }
    }
  end

  describe "unauthenticated access" do
    it "redirects to admin sign in" do
      get admin_promotion_codes_path, headers: browser_headers
      expect(response).to redirect_to(admin_sign_in_path)
    end
  end

  describe "non-super_admin access" do
    before { admin_login(developer_staff) }

    it "redirects with access denied for index" do
      get admin_promotion_codes_path, headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for new" do
      get new_admin_promotion_code_path, headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for create" do
      post admin_promotion_codes_path, params: valid_params, headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for show" do
      pc = create(:promotion_code)
      get admin_promotion_code_path(pc), headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for edit" do
      pc = create(:promotion_code)
      get edit_admin_promotion_code_path(pc), headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for update" do
      pc = create(:promotion_code)
      patch admin_promotion_code_path(pc), params: { promotion_code: { description: "Updated" } }, headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for toggle" do
      pc = create(:promotion_code)
      patch toggle_admin_promotion_code_path(pc), headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end
  end

  describe "authenticated access (super_admin)" do
    before { admin_login }

    describe "GET /admin/promotion_codes" do
      it "renders the promotion codes list" do
        create(:promotion_code)
        get admin_promotion_codes_path, headers: browser_headers
        expect(response).to have_http_status(:ok)
      end

      it "filters by code search query" do
        create(:promotion_code, code: "SUMMER2026")
        create(:promotion_code, code: "WINTER2026")
        get admin_promotion_codes_path, params: { q: "SUMMER" }, headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("SUMMER2026")
        expect(response.body).not_to include("WINTER2026")
      end

      it "filters by description search query" do
        create(:promotion_code, code: "CODE1", description: "Summer sale discount")
        create(:promotion_code, code: "CODE2", description: "Winter clearance")
        get admin_promotion_codes_path, params: { q: "Summer sale" }, headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("CODE1")
        expect(response.body).not_to include("CODE2")
      end

      it "paginates results" do
        get admin_promotion_codes_path, params: { page: 1 }, headers: browser_headers
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /admin/promotion_codes/new" do
      it "renders the new form" do
        get new_admin_promotion_code_path, headers: browser_headers
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/promotion_codes" do
      it "creates a promotion code with valid params and redirects to show" do
        expect {
          post admin_promotion_codes_path, params: valid_params, headers: browser_headers
        }.to change(PromotionCode, :count).by(1)

        pc = PromotionCode.last
        expect(response).to redirect_to(admin_promotion_code_path(pc))
        expect(flash[:notice]).to eq("Promotion code created.")
        expect(pc.code).to eq("TESTCODE")
        expect(pc.discount_value).to eq(15)
      end

      it "upcases code on create" do
        post admin_promotion_codes_path,
          params: { promotion_code: valid_params[:promotion_code].merge(code: "lowercase") },
          headers: browser_headers
        expect(PromotionCode.last.code).to eq("LOWERCASE")
      end

      it "renders new with unprocessable_entity on blank code" do
        expect {
          post admin_promotion_codes_path,
            params: { promotion_code: valid_params[:promotion_code].merge(code: "") },
            headers: browser_headers
        }.not_to change(PromotionCode, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders new with unprocessable_entity on invalid discount_value" do
        expect {
          post admin_promotion_codes_path,
            params: { promotion_code: valid_params[:promotion_code].merge(discount_value: -5) },
            headers: browser_headers
        }.not_to change(PromotionCode, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders new with unprocessable_entity when percentage > 100" do
        expect {
          post admin_promotion_codes_path,
            params: { promotion_code: valid_params[:promotion_code].merge(discount_type: "percentage", discount_value: 150) },
            headers: browser_headers
        }.not_to change(PromotionCode, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders new with unprocessable_entity on duplicate code" do
        create(:promotion_code, code: "TESTCODE")
        expect {
          post admin_promotion_codes_path, params: valid_params, headers: browser_headers
        }.not_to change(PromotionCode, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /admin/promotion_codes/:id" do
      it "shows promotion code details" do
        pc = create(:promotion_code, code: "SHOW10")
        get admin_promotion_code_path(pc), headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("SHOW10")
      end
    end

    describe "GET /admin/promotion_codes/:id/edit" do
      it "renders the edit form" do
        pc = create(:promotion_code)
        get edit_admin_promotion_code_path(pc), headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(pc.code)
      end
    end

    describe "PATCH /admin/promotion_codes/:id" do
      it "updates with valid params and redirects to show" do
        pc = create(:promotion_code, description: "Old description")
        patch admin_promotion_code_path(pc),
          params: { promotion_code: { description: "New description" } },
          headers: browser_headers
        expect(response).to redirect_to(admin_promotion_code_path(pc))
        expect(flash[:notice]).to eq("Promotion code updated.")
        expect(pc.reload.description).to eq("New description")
      end

      it "renders edit with unprocessable_entity on invalid params" do
        pc = create(:promotion_code)
        patch admin_promotion_code_path(pc),
          params: { promotion_code: { discount_value: -1 } },
          headers: browser_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH /admin/promotion_codes/:id/toggle" do
      it "deactivates an active promotion code and redirects to index" do
        pc = create(:promotion_code, active: true)
        patch toggle_admin_promotion_code_path(pc), headers: browser_headers
        expect(response).to redirect_to(admin_promotion_codes_path)
        expect(flash[:notice]).to eq("Promotion code deactivated.")
        expect(pc.reload.active).to be false
      end

      it "activates an inactive promotion code and redirects to index" do
        pc = create(:promotion_code, :inactive)
        patch toggle_admin_promotion_code_path(pc), headers: browser_headers
        expect(response).to redirect_to(admin_promotion_codes_path)
        expect(flash[:notice]).to eq("Promotion code activated.")
        expect(pc.reload.active).to be true
      end
    end
  end
end
