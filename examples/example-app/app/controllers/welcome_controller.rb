class WelcomeController < ActionController::Base
  def index
    # Example using Mochitype::View - the struct can be rendered directly
    render Mochitypes::Users::Index.from_data(page: params[:page]&.to_i || 1)
  end

  def show
    render json: Mochitypes::Users::Show.render
  end
end
