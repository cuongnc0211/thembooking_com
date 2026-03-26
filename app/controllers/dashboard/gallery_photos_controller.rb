module Dashboard
  class GalleryPhotosController < BaseController
    before_action :set_business
    before_action :set_gallery_photo, only: [ :update, :destroy ]

    def index
      photos = @business.gallery_photos.ordered.with_attached_image
      render json: { gallery_photos: photos_json(photos) }
    end

    def create
      @photo = @business.gallery_photos.build(gallery_photo_params)
      if @photo.save
        render json: { gallery_photo: photo_json(@photo) }, status: :created
      else
        render json: { errors: @photo.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      # Image replacement not supported via update — upload a new photo instead
      if @photo.update(gallery_photo_params.except(:image))
        render json: { gallery_photo: photo_json(@photo) }
      else
        render json: { errors: @photo.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @photo.destroy!
      head :no_content
    end

    private

    def set_business
      @business = current_user.business
    end

    def set_gallery_photo
      @photo = @business.gallery_photos.find(params[:id])
    end

    def gallery_photo_params
      params.require(:gallery_photo).permit(:image, :caption, :position)
    end

    def photos_json(photos)
      photos.map { |p| photo_json(p) }
    end

    def photo_json(photo)
      {
        id: photo.id,
        caption: photo.caption,
        position: photo.position,
        image_url: photo.image.attached? ? url_for(photo.image) : nil,
        thumbnail_url: photo.image.attached? ? url_for(photo.image.variant(resize_to_fill: [ 300, 300 ])) : nil
      }
    end
  end
end
