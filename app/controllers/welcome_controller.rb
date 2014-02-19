class WelcomeController < ApplicationController

  def index

    dm = DataModel.new
    dm.name = 'Testing'
    dm.save()
  
  end

end
