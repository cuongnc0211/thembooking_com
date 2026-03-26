require "rails_helper"

RSpec.describe "Admin::Staffs", type: :request do
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
  let(:staff) { create(:staff, :super_admin, password: "password123", password_confirmation: "password123") }
  let(:developer_staff) { create(:staff, :developer, password: "password123", password_confirmation: "password123") }

  def admin_login(s = staff)
    post admin_sign_in_path, params: { email_address: s.email_address, password: "password123" }, headers: browser_headers
  end

  describe "unauthenticated access" do
    it "redirects to admin sign in" do
      get admin_staffs_path, headers: browser_headers
      expect(response).to redirect_to(admin_sign_in_path)
    end
  end

  describe "non-super_admin access" do
    before { admin_login(developer_staff) }

    it "redirects with access denied for index" do
      get admin_staffs_path, headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for new" do
      get new_admin_staff_path, headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for create" do
      post admin_staffs_path, params: { staff: { name: "Test", email_address: "test@example.com", password: "password123", password_confirmation: "password123" } }, headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for show" do
      existing_staff = create(:staff)
      get admin_staff_path(existing_staff), headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for edit" do
      existing_staff = create(:staff)
      get edit_admin_staff_path(existing_staff), headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for update" do
      existing_staff = create(:staff)
      patch admin_staff_path(existing_staff), params: { staff: { name: "Updated" } }, headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end

    it "redirects with access denied for destroy" do
      existing_staff = create(:staff)
      delete admin_staff_path(existing_staff), headers: browser_headers
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied.")
    end
  end

  describe "authenticated access (super_admin)" do
    before { admin_login }

    describe "GET /admin/staffs" do
      it "renders the staffs list" do
        create(:staff)
        get admin_staffs_path, headers: browser_headers
        expect(response).to have_http_status(:ok)
      end

      it "filters by search query" do
        staff_alice = create(:staff, name: "Alice Developer")
        create(:staff, name: "Bob Manager")
        get admin_staffs_path, params: { q: "Alice" }, headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Alice Developer")
        expect(response.body).not_to include("Bob Manager")
      end

      it "filters by email search query" do
        staff_alice = create(:staff, email_address: "alice@example.com")
        create(:staff, email_address: "bob@other.com")
        get admin_staffs_path, params: { q: "alice" }, headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("alice@example.com")
        expect(response.body).not_to include("bob@other.com")
      end

      it "paginates results" do
        get admin_staffs_path, params: { page: 1 }, headers: browser_headers
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /admin/staffs/new" do
      it "renders new form" do
        get new_admin_staff_path, headers: browser_headers
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/staffs" do
      it "creates staff with valid params and redirects to show" do
        expect {
          post admin_staffs_path, params: { staff: { name: "New Staff", email_address: "newstaff@example.com", role: "developer", active: true, password: "password123", password_confirmation: "password123" } }, headers: browser_headers
        }.to change(Staff, :count).by(1)

        new_staff = Staff.last
        expect(response).to redirect_to(admin_staff_path(new_staff))
        expect(flash[:notice]).to eq("Staff created successfully.")
        expect(new_staff.name).to eq("New Staff")
        expect(new_staff.email_address).to eq("newstaff@example.com")
        expect(new_staff.role).to eq("developer")
      end

      it "renders new with unprocessable_entity on missing name" do
        expect {
          post admin_staffs_path, params: { staff: { name: "", email_address: "test@example.com", password: "password123", password_confirmation: "password123" } }, headers: browser_headers
        }.not_to change(Staff, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("error")
      end

      it "renders new with unprocessable_entity on missing email" do
        expect {
          post admin_staffs_path, params: { staff: { name: "Test Staff", email_address: "", password: "password123", password_confirmation: "password123" } }, headers: browser_headers
        }.not_to change(Staff, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders new with unprocessable_entity on duplicate email" do
        create(:staff, email_address: "duplicate@example.com")
        expect {
          post admin_staffs_path, params: { staff: { name: "Test Staff", email_address: "duplicate@example.com", password: "password123", password_confirmation: "password123" } }, headers: browser_headers
        }.not_to change(Staff, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders new with unprocessable_entity on password too short" do
        expect {
          post admin_staffs_path, params: { staff: { name: "Test Staff", email_address: "test@example.com", password: "short", password_confirmation: "short" } }, headers: browser_headers
        }.not_to change(Staff, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders new with unprocessable_entity on password mismatch" do
        expect {
          post admin_staffs_path, params: { staff: { name: "Test Staff", email_address: "test@example.com", password: "password123", password_confirmation: "different" } }, headers: browser_headers
        }.not_to change(Staff, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /admin/staffs/:id" do
      it "shows staff details" do
        test_staff = create(:staff, name: "John Doe")
        get admin_staff_path(test_staff), headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("John Doe")
      end
    end

    describe "GET /admin/staffs/:id/edit" do
      it "renders edit form" do
        test_staff = create(:staff)
        get edit_admin_staff_path(test_staff), headers: browser_headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(test_staff.email_address)
      end
    end

    describe "PATCH /admin/staffs/:id" do
      it "updates staff with valid params and redirects to show" do
        test_staff = create(:staff, name: "Original Name")
        patch admin_staff_path(test_staff), params: { staff: { name: "Updated Name" } }, headers: browser_headers
        expect(response).to redirect_to(admin_staff_path(test_staff))
        expect(flash[:notice]).to eq("Staff updated successfully.")
        expect(test_staff.reload.name).to eq("Updated Name")
      end

      it "does not change password_digest when password param is blank" do
        test_staff = create(:staff, password: "password123", password_confirmation: "password123")
        original_digest = test_staff.password_digest

        patch admin_staff_path(test_staff), params: { staff: { name: "Updated Name", password: "", password_confirmation: "" } }, headers: browser_headers
        expect(response).to redirect_to(admin_staff_path(test_staff))
        expect(test_staff.reload.password_digest).to eq(original_digest)
        expect(test_staff.name).to eq("Updated Name")
      end

      it "changes password when valid password params provided" do
        test_staff = create(:staff, password: "password123", password_confirmation: "password123")
        original_digest = test_staff.password_digest

        patch admin_staff_path(test_staff), params: { staff: { password: "newpassword123", password_confirmation: "newpassword123" } }, headers: browser_headers
        expect(response).to redirect_to(admin_staff_path(test_staff))
        expect(test_staff.reload.password_digest).not_to eq(original_digest)
      end

      it "renders edit with unprocessable_entity on invalid email" do
        test_staff = create(:staff)
        patch admin_staff_path(test_staff), params: { staff: { email_address: "" } }, headers: browser_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(test_staff.reload.email_address).not_to eq("")
      end

      it "renders edit with unprocessable_entity on password too short" do
        test_staff = create(:staff)
        patch admin_staff_path(test_staff), params: { staff: { password: "short", password_confirmation: "short" } }, headers: browser_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders edit with unprocessable_entity on password mismatch" do
        test_staff = create(:staff)
        patch admin_staff_path(test_staff), params: { staff: { password: "password123", password_confirmation: "different" } }, headers: browser_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "updates role when provided" do
        test_staff = create(:staff, :super_admin)
        patch admin_staff_path(test_staff), params: { staff: { role: "developer" } }, headers: browser_headers
        expect(response).to redirect_to(admin_staff_path(test_staff))
        expect(test_staff.reload.role).to eq("developer")
      end

      it "updates active status" do
        test_staff = create(:staff, active: true)
        patch admin_staff_path(test_staff), params: { staff: { active: false } }, headers: browser_headers
        expect(response).to redirect_to(admin_staff_path(test_staff))
        expect(test_staff.reload.active).to be_falsey
      end
    end

    describe "DELETE /admin/staffs/:id" do
      it "deletes staff and redirects to index" do
        test_staff = create(:staff)
        expect {
          delete admin_staff_path(test_staff), headers: browser_headers
        }.to change(Staff, :count).by(-1)

        expect(response).to redirect_to(admin_staffs_path)
        expect(flash[:notice]).to eq("Staff deleted.")
      end

      it "does not delete own account and shows alert" do
        expect {
          delete admin_staff_path(staff), headers: browser_headers
        }.not_to change(Staff, :count)

        expect(response).to redirect_to(admin_staffs_path)
        expect(flash[:alert]).to eq("You cannot delete your own account.")
      end
    end
  end
end
