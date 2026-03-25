require "rails_helper"

RSpec.describe Business, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:branches).dependent(:destroy) }
    it { is_expected.to have_many(:services).through(:branches) }
    it { is_expected.to have_many(:bookings).through(:branches) }
  end

  describe "validations" do
    subject { build(:business) }

    describe "name" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_length_of(:name).is_at_most(100) }
    end

    describe "business_type" do
      it { is_expected.to validate_presence_of(:business_type) }

      it "defines correct enum values" do
        expect(Business.business_types.keys).to contain_exactly("barber", "salon", "spa", "nail", "other")
      end
    end

    describe "slug" do
      it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }
      it { is_expected.to validate_length_of(:slug).is_at_least(3).is_at_most(50) }

      it "requires slug to be present after normalization" do
        business = build(:business, slug: nil, name: "")
        expect(business).not_to be_valid
        expect(business.errors[:slug]).to be_present
      end

      it "only allows lowercase letters, numbers, and hyphens" do
        business = build(:business, slug: "valid-slug-123")
        expect(business).to be_valid

        # Test with invalid chars - slug gets normalized to lowercase first,
        # then validated for format
        business.slug = "my@shop"
        expect(business).not_to be_valid
        expect(business.errors[:slug]).to be_present
      end

      it "normalizes slug to lowercase and strips whitespace" do
        business = build(:business, slug: "  MY-SHOP  ")
        expect(business.slug).to eq("my-shop")
      end

      it "auto-generates slug from name if blank" do
        business = build(:business, name: "Johns Barbershop", slug: "")
        expect(business.slug).to be_blank
        business.valid?
        # Rails parameterize converts "Johns Barbershop" to "johns-barbershop"
        expect(business.slug).to eq("johns-barbershop")
      end

      it "auto-generates slug from name using parameterize" do
        business = build(:business, name: "My Coffee Shop", slug: "")
        business.valid?
        expect(business.slug).to eq("my-coffee-shop")
      end

      it "does not auto-generate slug if name is blank" do
        business = build(:business, name: "", slug: "")
        business.valid?
        expect(business.slug).to be_blank
      end

      it "does not auto-generate slug if slug already provided" do
        business = build(:business, name: "Johns Barbershop", slug: "custom-slug")
        business.valid?
        expect(business.slug).to eq("custom-slug")
      end

      it "truncates auto-generated slug to 50 chars" do
        business = build(:business, name: "A" * 60, slug: "")
        business.valid?
        expect(business.slug.length).to eq(50)
      end

      it "rejects slug shorter than 3 characters" do
        business = build(:business, slug: "ab")
        expect(business).not_to be_valid
        expect(business.errors[:slug]).to be_present
      end

      it "allows spaces in original slug which will be invalid after validation" do
        business = build(:business, slug: "my shop")
        expect(business).not_to be_valid
      end

      it "rejects slug with special characters except hyphens" do
        business = build(:business, slug: "my@shop")
        expect(business).not_to be_valid
        expect(business.errors[:slug]).to be_present
      end

      it "accepts slug with hyphens and numbers" do
        business = build(:business, slug: "my-shop-123")
        expect(business).to be_valid
      end
    end

    describe "slug cross-table uniqueness" do
      it "rejects business slug that matches an existing branch slug" do
        branch = create(:branch, slug: "main-branch")
        business = build(:business, slug: "main-branch")
        expect(business).not_to be_valid
        expect(business.errors[:slug]).to include("is already taken by a branch")
      end

      it "allows business slug when no matching branch slug exists" do
        business = build(:business, slug: "unique-slug")
        expect(business).to be_valid
      end

      it "ignores case when checking cross-table uniqueness" do
        create(:branch, slug: "main-branch")
        business = build(:business, slug: "MAIN-BRANCH")
        expect(business).not_to be_valid
        expect(business.errors[:slug]).to include("is already taken by a branch")
      end
    end

    describe "headline" do
      it { is_expected.to validate_length_of(:headline).is_at_most(200) }

      it "allows blank headline" do
        business = build(:business, headline: "")
        expect(business).to be_valid
      end

      it "allows nil headline" do
        business = build(:business, headline: nil)
        expect(business).to be_valid
      end

      it "allows headlines up to 200 characters" do
        business = build(:business, headline: "A" * 200)
        expect(business).to be_valid
      end

      it "rejects headlines longer than 200 characters" do
        business = build(:business, headline: "A" * 201)
        expect(business).not_to be_valid
        expect(business.errors[:headline]).to be_present
      end
    end

    describe "theme_color" do
      it "allows valid hex color with 6 digits" do
        business = build(:business, theme_color: "#abc123")
        expect(business).to be_valid
      end

      it "allows uppercase hex color" do
        business = build(:business, theme_color: "#ABC123")
        expect(business).to be_valid
      end

      it "allows mixed case hex color" do
        business = build(:business, theme_color: "#AbC123")
        expect(business).to be_valid
      end

      it "allows numeric hex color" do
        business = build(:business, theme_color: "#000000")
        expect(business).to be_valid
      end

      it "allows all-f hex color" do
        business = build(:business, theme_color: "#ffffff")
        expect(business).to be_valid
      end

      it "allows blank theme_color" do
        business = build(:business, theme_color: "")
        expect(business).to be_valid
      end

      it "allows nil theme_color" do
        business = build(:business, theme_color: nil)
        expect(business).to be_valid
      end

      it "rejects color name instead of hex" do
        business = build(:business, theme_color: "red")
        expect(business).not_to be_valid
        expect(business.errors[:theme_color]).to be_present
      end

      it "rejects hex color with invalid characters" do
        business = build(:business, theme_color: "#gg0000")
        expect(business).not_to be_valid
        expect(business.errors[:theme_color]).to be_present
      end

      it "rejects hex color without hash" do
        business = build(:business, theme_color: "abc123")
        expect(business).not_to be_valid
      end

      it "rejects hex color with wrong length (3 digits)" do
        business = build(:business, theme_color: "#abc")
        expect(business).not_to be_valid
      end

      it "rejects hex color with wrong length (8 digits)" do
        business = build(:business, theme_color: "#abcdef00")
        expect(business).not_to be_valid
      end
    end

    describe "cover_photo" do
      it "allows valid JPEG image" do
        business = build(:business)
        business.cover_photo.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test-image.jpg")),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
        expect(business).to be_valid
      end

      it "allows valid PNG image" do
        business = build(:business)
        business.cover_photo.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test-image.png")),
          filename: "test.png",
          content_type: "image/png"
        )
        expect(business).to be_valid
      end

      it "allows valid WebP image" do
        business = build(:business)
        business.cover_photo.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test-image.webp")),
          filename: "test.webp",
          content_type: "image/webp"
        )
        expect(business).to be_valid
      end

      it "rejects GIF image" do
        business = build(:business)
        business.cover_photo.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test-image.gif")),
          filename: "test.gif",
          content_type: "image/gif"
        )
        expect(business).not_to be_valid
        expect(business.errors[:cover_photo]).to include("must be a JPEG, PNG, or WebP")
      end

      it "rejects PDF file" do
        business = build(:business)
        business.cover_photo.attach(
          io: StringIO.new("PDF content"),
          filename: "test.pdf",
          content_type: "application/pdf"
        )
        expect(business).not_to be_valid
        expect(business.errors[:cover_photo]).to include("must be a JPEG, PNG, or WebP")
      end

      it "rejects cover_photo larger than 10MB" do
        business = build(:business)
        business.cover_photo.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test-image.jpg")),
          filename: "large.jpg",
          content_type: "image/jpeg"
        )
        # Mock byte_size on the blob
        allow(business.cover_photo.blob).to receive(:byte_size).and_return(11.megabytes)
        expect(business).not_to be_valid
        expect(business.errors[:cover_photo]).to include("size must be less than 10MB")
      end

      it "allows cover_photo up to 10MB" do
        business = build(:business)
        business.cover_photo.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test-image.jpg")),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
        # Mock byte_size on the blob to be 9.99MB
        allow(business.cover_photo.blob).to receive(:byte_size).and_return(9_990_000)
        expect(business).to be_valid
      end

      it "allows business without cover_photo" do
        business = build(:business)
        expect(business).to be_valid
      end
    end
  end

  describe "user association" do
    it "enforces one business per user" do
      user = create(:user)
      create(:business, user: user)

      second_business = build(:business, user: user)
      expect(second_business).not_to be_valid
    end
  end
end
