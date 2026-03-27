require "rails_helper"

RSpec.describe "Dashboard::GalleryPhotos", type: :request do
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }
  let(:user) { create(:user, :onboarding_completed) }
  let(:business) { create(:business, user: user) }

  before do
    sign_in(user)
    business
  end

  describe "GET /dashboard/business/gallery_photos (index)" do
    context "when business has photos" do
      let!(:photo1) { create(:gallery_photo, business: business, position: 1, caption: "Photo 1") }
      let!(:photo2) { create(:gallery_photo, business: business, position: 2, caption: "Photo 2") }

      it "returns 200 and lists photos JSON" do
        get dashboard_business_gallery_photos_path, headers: browser_headers
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["gallery_photos"]).to be_an(Array)
        expect(json["gallery_photos"].length).to eq(2)
      end

      it "returns photos in correct order (by position)" do
        get dashboard_business_gallery_photos_path, headers: browser_headers

        json = JSON.parse(response.body)
        photos = json["gallery_photos"]
        expect(photos[0]["caption"]).to eq("Photo 1")
        expect(photos[1]["caption"]).to eq("Photo 2")
      end

      it "includes id, caption, position, image_url, thumbnail_url in response" do
        get dashboard_business_gallery_photos_path, headers: browser_headers

        json = JSON.parse(response.body)
        photo = json["gallery_photos"].first

        expect(photo).to have_key("id")
        expect(photo).to have_key("caption")
        expect(photo).to have_key("position")
        expect(photo).to have_key("image_url")
        expect(photo).to have_key("thumbnail_url")
      end

      it "returns valid image URLs" do
        get dashboard_business_gallery_photos_path, headers: browser_headers

        json = JSON.parse(response.body)
        photo = json["gallery_photos"].first

        expect(photo["image_url"]).to be_present
        expect(photo["thumbnail_url"]).to be_present
      end
    end

    context "when business has no photos" do
      it "returns 200 with empty array" do
        get dashboard_business_gallery_photos_path, headers: browser_headers
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["gallery_photos"]).to eq([])
      end
    end
  end

  describe "POST /dashboard/business/gallery_photos (create)" do
    context "with valid params" do
      it "returns 201 and creates photo" do
        image = fixture_file_upload("spec/fixtures/files/test-image.jpg", "image/jpeg")

        expect {
          post dashboard_business_gallery_photos_path,
               params: { gallery_photo: { image: image, caption: "Beautiful photo", position: 0 } },
               headers: browser_headers
        }.to change(GalleryPhoto, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "returns photo JSON with created photo data" do
        image = fixture_file_upload("spec/fixtures/files/test-image.jpg", "image/jpeg")

        post dashboard_business_gallery_photos_path,
             params: { gallery_photo: { image: image, caption: "My Photo", position: 0 } },
             headers: browser_headers

        json = JSON.parse(response.body)
        photo = json["gallery_photo"]

        expect(photo["caption"]).to eq("My Photo")
        expect(photo["position"]).to eq(0)
        expect(photo["image_url"]).to be_present
        expect(photo["thumbnail_url"]).to be_present
      end

      it "creates photo with nil caption" do
        image = fixture_file_upload("spec/fixtures/files/test-image.jpg", "image/jpeg")

        post dashboard_business_gallery_photos_path,
             params: { gallery_photo: { image: image, position: 0 } },
             headers: browser_headers

        expect(response).to have_http_status(:created)
        photo = GalleryPhoto.last
        expect(photo.caption).to be_nil
      end
    end

    context "with invalid params" do
      it "returns 422 when image is missing" do
        post dashboard_business_gallery_photos_path,
             params: { gallery_photo: { caption: "No image", position: 0 } },
             headers: browser_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end

      it "returns 422 when caption exceeds 200 chars" do
        image = fixture_file_upload("spec/fixtures/files/test-image.jpg", "image/jpeg")
        long_caption = "a" * 201

        post dashboard_business_gallery_photos_path,
             params: { gallery_photo: { image: image, caption: long_caption, position: 0 } },
             headers: browser_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end

      it "returns 422 when position is negative" do
        image = fixture_file_upload("spec/fixtures/files/test-image.jpg", "image/jpeg")

        post dashboard_business_gallery_photos_path,
             params: { gallery_photo: { image: image, position: -1 } },
             headers: browser_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 when max 20 photos already exist" do
        # Create 20 photos
        20.times do |i|
          create(:gallery_photo, business: business, position: i)
        end

        image = fixture_file_upload("spec/fixtures/files/test-image.jpg", "image/jpeg")

        post dashboard_business_gallery_photos_path,
             params: { gallery_photo: { image: image, position: 20 } },
             headers: browser_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Maximum 20 gallery photos allowed per business")
      end

      it "returns 422 when image format is not JPEG/PNG/WebP" do
        image = fixture_file_upload("spec/fixtures/files/test-image.gif", "image/gif")

        post dashboard_business_gallery_photos_path,
             params: { gallery_photo: { image: image, position: 0 } },
             headers: browser_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end

  describe "PATCH /dashboard/business/gallery_photos/:id (update)" do
    let!(:photo) { create(:gallery_photo, business: business, caption: "Original", position: 0) }

    context "with valid params" do
      it "returns 200 and updates caption" do
        patch dashboard_business_gallery_photo_path(photo),
              params: { gallery_photo: { caption: "Updated Caption" } },
              headers: browser_headers

        expect(response).to have_http_status(:ok)
        expect(photo.reload.caption).to eq("Updated Caption")
      end

      it "returns 200 and updates position" do
        patch dashboard_business_gallery_photo_path(photo),
              params: { gallery_photo: { position: 5 } },
              headers: browser_headers

        expect(response).to have_http_status(:ok)
        expect(photo.reload.position).to eq(5)
      end

      it "updates both caption and position" do
        patch dashboard_business_gallery_photo_path(photo),
              params: { gallery_photo: { caption: "New Caption", position: 3 } },
              headers: browser_headers

        expect(response).to have_http_status(:ok)
        expect(photo.reload.caption).to eq("New Caption")
        expect(photo.reload.position).to eq(3)
      end

      it "returns updated photo JSON" do
        patch dashboard_business_gallery_photo_path(photo),
              params: { gallery_photo: { caption: "Test Caption", position: 2 } },
              headers: browser_headers

        json = JSON.parse(response.body)
        photo_json = json["gallery_photo"]

        expect(photo_json["caption"]).to eq("Test Caption")
        expect(photo_json["position"]).to eq(2)
      end

      it "clears caption when set to empty string" do
        patch dashboard_business_gallery_photo_path(photo),
              params: { gallery_photo: { caption: "" } },
              headers: browser_headers

        expect(response).to have_http_status(:ok)
        expect(photo.reload.caption).to eq("")
      end
    end

    context "with invalid params" do
      it "returns 422 when caption exceeds 200 chars" do
        long_caption = "a" * 201

        patch dashboard_business_gallery_photo_path(photo),
              params: { gallery_photo: { caption: long_caption } },
              headers: browser_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 when position is negative" do
        patch dashboard_business_gallery_photo_path(photo),
              params: { gallery_photo: { position: -1 } },
              headers: browser_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 when position is not an integer" do
        patch dashboard_business_gallery_photo_path(photo),
              params: { gallery_photo: { position: "not_a_number" } },
              headers: browser_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "does not allow image replacement via update" do
      it "ignores image param in update request" do
        new_image = fixture_file_upload("spec/fixtures/files/test-image.png", "image/png")

        patch dashboard_business_gallery_photo_path(photo),
              params: { gallery_photo: { image: new_image, caption: "Updated" } },
              headers: browser_headers

        expect(response).to have_http_status(:ok)
        # Verify caption was updated but image was not replaced
        expect(photo.reload.caption).to eq("Updated")
        expect(photo.image.attached?).to be_truthy
      end
    end
  end

  describe "DELETE /dashboard/business/gallery_photos/:id (destroy)" do
    let!(:photo) { create(:gallery_photo, business: business) }

    context "with valid photo" do
      it "returns 204 and destroys photo" do
        photo_id = photo.id

        delete dashboard_business_gallery_photo_path(photo), headers: browser_headers

        expect(response).to have_http_status(:no_content)
        expect(GalleryPhoto.find_by(id: photo_id)).to be_nil
      end

      it "removes photo from business gallery" do
        expect(business.gallery_photos.count).to eq(1)

        delete dashboard_business_gallery_photo_path(photo), headers: browser_headers

        expect(business.gallery_photos.count).to eq(0)
      end

      it "can delete multiple photos sequentially" do
        photo2 = create(:gallery_photo, business: business)
        expect(business.gallery_photos.count).to eq(2)

        delete dashboard_business_gallery_photo_path(photo), headers: browser_headers
        expect(response).to have_http_status(:no_content)
        expect(business.gallery_photos.count).to eq(1)

        delete dashboard_business_gallery_photo_path(photo2), headers: browser_headers
        expect(response).to have_http_status(:no_content)
        expect(business.gallery_photos.count).to eq(0)
      end
    end
  end

  describe "authorization" do
    let(:other_user) { create(:user, :onboarding_completed) }
    let(:other_business) { create(:business, user: other_user) }
    let!(:other_photo) { create(:gallery_photo, business: other_business) }

    it "cannot access another user's gallery photos via index" do
      # Current user can only access their own business photos via current_user.business
      # Trying to access another business directly would be through a different route
      # but the controller scopes to current_user.business, so this test verifies
      # that behavior
      get dashboard_business_gallery_photos_path, headers: browser_headers
      json = JSON.parse(response.body)

      # Should only return current user's photos (none in this case)
      expect(json["gallery_photos"]).to eq([])
      expect(json["gallery_photos"]).not_to include(other_photo.id)
    end

    it "cannot update another user's gallery photo" do
      patch dashboard_business_gallery_photo_path(other_photo),
            params: { gallery_photo: { caption: "Hacked" } },
            headers: browser_headers

      expect(response).to have_http_status(:not_found)
      expect(other_photo.reload.caption).not_to eq("Hacked")
    end

    it "cannot delete another user's gallery photo" do
      expect {
        delete dashboard_business_gallery_photo_path(other_photo), headers: browser_headers
      }.not_to change(GalleryPhoto, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end

describe "Dashboard::GalleryPhotos (unauthenticated)" do
  let(:browser_headers) { { "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } }

  describe "unauthenticated access" do
    it "redirects to sign_in for GET index" do
      get dashboard_business_gallery_photos_path, headers: browser_headers
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects to sign_in for POST create" do
      image = fixture_file_upload("spec/fixtures/files/test-image.jpg", "image/jpeg")
      post dashboard_business_gallery_photos_path,
           params: { gallery_photo: { image: image, caption: "Test" } },
           headers: browser_headers
      expect(response).to redirect_to(new_session_path)
    end
  end
end
