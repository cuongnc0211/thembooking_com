FactoryBot.define do
  factory :gallery_photo do
    association :business
    caption { Faker::Lorem.sentence(word_count: 5) }
    position { 0 }

    after(:build) do |photo|
      # Attach a valid test image (JPEG) if not already attached
      unless photo.image.attached?
        photo.image.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test-image.jpg")),
          filename: "test-image.jpg",
          content_type: "image/jpeg"
        )
      end
    end

    trait :with_png do
      after(:build) do |photo|
        photo.image.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test-image.png")),
          filename: "test-image.png",
          content_type: "image/png"
        )
      end
    end

    trait :with_webp do
      after(:build) do |photo|
        photo.image.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test-image.webp")),
          filename: "test-image.webp",
          content_type: "image/webp"
        )
      end
    end

    trait :with_caption do
      caption { "Beautiful gallery photo" }
    end

    trait :positioned do
      sequence(:position) { |n| n }
    end
  end
end
