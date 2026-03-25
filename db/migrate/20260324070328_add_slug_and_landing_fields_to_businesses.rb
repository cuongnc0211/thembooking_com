class AddSlugAndLandingFieldsToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :slug, :string, limit: 50
    add_column :businesses, :headline, :string, limit: 200
    add_column :businesses, :theme_color, :string, limit: 7, default: "#000000"

    add_index :businesses, :slug, unique: true

    reversible do |dir|
      dir.up do
        # Backfill slugs from business name, avoiding collisions with branch slugs
        Business.reset_column_information
        Business.find_each do |biz|
          base_slug = biz.name.parameterize.first(50)
          slug = base_slug
          counter = 1
          while Business.where(slug: slug).where.not(id: biz.id).exists? ||
                Branch.where(slug: slug).exists?
            slug = "#{base_slug.first(46)}-#{counter}"
            counter += 1
          end
          biz.update_column(:slug, slug)
        end

        change_column_null :businesses, :slug, false
      end
    end
  end
end
