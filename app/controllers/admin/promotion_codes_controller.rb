module Admin
  class PromotionCodesController < Admin::BaseController
    before_action :require_super_admin!
    before_action :set_promotion_code, only: %i[show edit update toggle]

    def index
      @promotion_codes = PromotionCode.order(created_at: :desc)
      @promotion_codes = @promotion_codes.where("code ILIKE :q OR description ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
      @page = [ params.fetch(:page, 1).to_i, 1 ].max
      @per_page = 25
      @total = @promotion_codes.count
      @promotion_codes = @promotion_codes.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show; end

    def new
      @promotion_code = PromotionCode.new
    end

    def edit; end

    def create
      @promotion_code = PromotionCode.new(promotion_code_params)
      if @promotion_code.save
        redirect_to admin_promotion_code_path(@promotion_code), notice: "Promotion code created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @promotion_code.update(promotion_code_params)
        redirect_to admin_promotion_code_path(@promotion_code), notice: "Promotion code updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle
      @promotion_code.update!(active: !@promotion_code.active?)
      status = @promotion_code.active? ? "activated" : "deactivated"
      redirect_to admin_promotion_codes_path, notice: "Promotion code #{status}."
    end

    private

    def set_promotion_code
      @promotion_code = PromotionCode.find(params[:id])
    end

    def promotion_code_params
      params.require(:promotion_code).permit(
        :code, :discount_type, :discount_value,
        :usage_limit, :valid_from, :valid_until,
        :active, :description
      )
    end

  end
end
