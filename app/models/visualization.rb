# The Visualization belongs to a Worksheet
class Visualization

	include Mongoid::Document

	# Serialized data containing the information to rerender the graph
	field :dataset,			:type => String
	field :filters,			:type => String
	field :chart_type,		:type => String
	field :chart_options,	:type => String
	field :identifier, 		:type => String

	# One to many relationship with worksheets	
	belongs_to :worksheet

	def self.find_by_identifier(identifier)
    	self.where(:identifier => identifier).first()
  	end

end