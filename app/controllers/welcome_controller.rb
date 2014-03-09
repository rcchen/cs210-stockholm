class WelcomeController < ApplicationController

  def index

  	@visualization = Visualization.first

  end

end
