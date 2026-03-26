require "rails_helper"

RSpec.describe GalleryPhoto, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to have_one_attached(:image) }
  end

  describe "validations" do
    let(:business) { create(:business) }
    subject { build(:gallery_photo, business: business) }

    describe "image" do
      it { is_expected.to validate_presence_of(:image) }

      it "rejects photo without image" do
        photo = GalleryPhoto.new(business: business, caption: "Test")
        expect(photo).not_to be_valid
        expect(photo.errors[:image]).to include("can't be blank")
      end
    end

    describe "caption" do
      it { is_expected.to validate_length_of(:caption).is_at_most(200) }

      it "allows blank caption" do
        photo = build(:gallery_photo, business: business, caption: "")
        expect(photo).to be_valid
      end

      it "allows nil caption" do
        photo = build(:gallery_photo, business: business, caption: nil)
        expect(photo).to be_valid
      end

      it "rejects caption longer than 200 chars" do
        long_caption = "a" * 201
        photo = build(:gallery_photo, business: business, caption: long_caption)
        expect(photo).not_to be_valid
        expect(photo.errors[:caption]).to be_present
      end

      it "allows caption exactly 200 chars" do
        exact_caption = "a" * 200
        photo = build(:gallery_photo, business: business, caption: exact_caption)
        expect(photo).to be_valid
      end
    end

    describe "position" do
      it { is_expected.to validate_numericality_of(:position).only_integer }

      it "requires position >= 0" do
        photo = build(:gallery_photo, business: business, position: -1)
        expect(photo).not_to be_valid
        expect(photo.errors[:position]).to be_present
      end

      it "allows position = 0" do
        photo = build(:gallery_photo, business: business, position: 0)
        expect(photo).to be_valid
      end

      it "allows positive integer positions" do
        photo = build(:gallery_photo, business: business, position: 100)
        expect(photo).to be_valid
      end

      it "rejects non-integer positions" do
        photo = build(:gallery_photo, business: business, position: 1.5)
        expect(photo).not_to be_valid
        expect(photo.errors[:position]).to be_present
      end
    end

    describe "image format validation" do
      it "accepts JPEG images" do
        photo = build(:gallery_photo, business: business)
        expect(photo).to be_valid
      end

      it "accepts PNG images" do
        photo = build(:gallery_photo, :with_png, business: business)
        expect(photo).to be_valid
      end

      it "accepts WebP images" do
        photo = build(:gallery_photo, :with_webp, business: business)
        expect(photo).to be_valid
      end

      it "rejects GIF images" do
        photo = build(:gallery_photo, business: business)
        photo.image.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test-image.gif")),
          filename: "test-image.gif",
          content_type: "image/gif"
        )
        expect(photo).not_to be_valid
        expect(photo.errors[:image]).to include("must be JPEG, PNG, or WebP")
      end

      it "rejects images larger than 10MB" do
        photo = build(:gallery_photo, business: business)
        # Mock a large image
        mock_file = StringIO.new("x" * (10.megabytes + 1))
        photo.image.attach(
          io: mock_file,
          filename: "large-image.jpg",
          content_type: "image/jpeg"
        )
        expect(photo).not_to be_valid
        expect(photo.errors[:image]).to include("must be less than 10MB")
      end

      it "allows images exactly 10MB" do
        photo = build(:gallery_photo, business: business)
        # Create a file exactly 10MB
        mock_file = StringIO.new("x" * (10.megabytes))
        photo.image.attach(
          io: mock_file,
          filename: "ten-mb-image.jpg",
          content_type: "image/jpeg"
        )
        expect(photo).to be_valid
      end
    end

    describe "max_photos_per_business validation" do
      it "allows creation of up to 20 photos" do
        20.times do |i|
          photo = build(:gallery_photo, business: business, position: i)
          photo.image.attach(
            io: File.open(Rails.root.join("spec/fixtures/files/test-image.jpg")),
            filename: "test-#{i}.jpg",
            content_type: "image/jpeg"
          )
          expect(photo).to be_valid
          photo.save!
        end
        expect(business.gallery_photos.count).to eq(20)
      end

      it "rejects creation of 21st photo" do
        # Create 20 photos
        20.times do |i|
          photo = create(:gallery_photo, business: business, position: i)
        end

        # Try to create 21st photo
        new_photo = build(:gallery_photo, business: business, position: 20)
        expect(new_photo).not_to be_valid
        expect(new_photo.errors[:base]).to include("Maximum 20 gallery photos allowed per business")
      end

      it "does not apply max limit on update" do
        # Create 20 photos
        20.times do |i|
          create(:gallery_photo, business: business, position: i)
        end

        # Update an existing photo should succeed even though we're at limit
        photo = business.gallery_photos.first
        photo.caption = "Updated caption"
        expect(photo).to be_valid
        photo.save!
        expect(photo.caption).to eq("Updated caption")
      end
    end
  end

  describe "scopes" do
    let(:business) { create(:business) }

    describe ".ordered" do
      it "orders photos by position ascending" do
        photo3 = create(:gallery_photo, business: business, position: 3)
        photo1 = create(:gallery_photo, business: business, position: 1)
        photo2 = create(:gallery_photo, business: business, position: 2)

        ordered = business.gallery_photos.ordered
        expect(ordered.pluck(:id)).to eq([photo1.id, photo2.id, photo3.id])
      end

      it "orders by created_at when positions are equal" do
        photo_a = create(:gallery_photo, business: business, position: 1, created_at: 2.hours.ago)
        photo_b = create(:gallery_photo, business: business, position: 1, created_at: 1.hour.ago)

        ordered = business.gallery_photos.ordered
        expect(ordered.pluck(:id)).to eq([photo_a.id, photo_b.id])
      end

      it "returns all photos in correct order with mixed positions" do
        pos2_first = create(:gallery_photo, business: business, position: 2, created_at: 2.hours.ago)
        pos1 = create(:gallery_photo, business: business, position: 1)
        pos2_second = create(:gallery_photo, business: business, position: 2, created_at: 1.hour.ago)

        ordered = business.gallery_photos.ordered
        expect(ordered.pluck(:id)).to eq([pos1.id, pos2_first.id, pos2_second.id])
      end
    end
  end

  describe "dependencies" do
    it "destroys gallery_photos when business is destroyed" do
      business = create(:business)
      photo = create(:gallery_photo, business: business)

      expect {
        business.destroy
      }.to change(GalleryPhoto, :count).by(-1)

      expect(GalleryPhoto.find_by(id: photo.id)).to be_nil
    end
  end
end
