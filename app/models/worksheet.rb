# The Worksheet is owned by a User and contains charts
class Worksheet

	include Mongoid::Document
	include Mongoid::Timestamps

	# Fields that are available within our Worksheet
	field :title,			:type => String
	field :description, 	:type => String
	field :identifier,		:type => String
	field :data,			:type => String

	# Many to many relationship with users
	has_and_belongs_to_many :users
	has_many :visualizations

	def self.find_by_identifier(identifier)
    	self.where(:identifier => identifier).first()
  	end

end
