# The Visualization belongs to a Worksheet
class Visualization

	include Mongoid::Document

	# Serialized data containing the information to rerender the graph
	field :data,			:type => String
	field :identifier, 		:type => String

	# One to many relationship with worksheets	
	belongs_to :worksheet

	def self.find_by_identifier(identifier)
    	self.where(:identifier => identifier).first()
  	end

end