class LandingPagesController < ApplicationController
  allow_unauthenticated_access
  layout "booking"

  def show
    @business = Business.find_by!(slug: params[:slug])

    # Load active branches with their services and categories in one query
    @branches = @business.branches
                         .where(active: true)
                         .includes(services: :service_category)
                         .order(:position)

    # Load gallery photos with attached images (avoids N+1)
    @gallery_photos = @business.gallery_photos
                               .ordered
                               .with_attached_image
                               .limit(20)
  end
end
