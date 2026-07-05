module Paginatable
  extend ActiveSupport::Concern

  included do
    include Pagy::Method
  end

  private

  def paginate(scope)
    limit = (params[:per_page] || 20).to_i.clamp(1, 100)
    pagy(:offset, scope, limit: limit)
  end

  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      page_size: pagy.limit,
      total_pages: pagy.pages,
      total_count: pagy.count
    }
  end
end
