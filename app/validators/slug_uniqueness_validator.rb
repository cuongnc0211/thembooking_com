# Validates that a slug is unique across both the businesses and branches tables.
# Prevents URL collisions where /:slug could resolve to two different records.
#
# NOTE: This only checks cross-table uniqueness (Business vs Branch).
# Same-table uniqueness is intentionally handled by `validates :slug, uniqueness:`
# in each model — do not remove that validation thinking it is redundant.
class SlugUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    other_model = record.is_a?(Business) ? Branch : Business
    if other_model.where(slug: value).exists?
      record.errors.add(attribute, "is already taken by a #{other_model.name.downcase}")
    end
  end
end
