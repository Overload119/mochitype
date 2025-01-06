class WelcomeController < ActionController::Base
  def index
  end

  def show
    render json: Mochitypes::Users::Show.render
  end
end
