class CreateGalleryPhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :gallery_photos do |t|
      t.references :business, null: false, foreign_key: true
      t.string :caption, limit: 200
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :gallery_photos, [ :business_id, :position ]
  end
end
