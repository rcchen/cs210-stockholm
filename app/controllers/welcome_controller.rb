class WelcomeController < ApplicationController

  def index
  
  	collection = Collection.new
  	collection.name = 'Test collection'
  	collection.save

  end

end
