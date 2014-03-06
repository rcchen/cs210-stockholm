# The Visualization belongs to a Worksheet
class Visualization

	include Mongoid::Document

	# Serialized data containing the information to rerender the graph
	field :data,			:type => String

	# Many to many relationship with users	
	belongs_to :worksheet

end