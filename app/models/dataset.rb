# The Dataset is the base collection type in our data system
class Dataset

	include Mongoid::Document

	# Be sure to store timestamps
	include Mongoid::Timestamps::Created
	include Mongoid::Timestamps::Updated

	# Defines one to many with Datadocs
	has_many :datadocs

	# Name of the Dataset
	field :name

	# Attributes of the Dataset
	# Also specifies the type of the attribute
	field :attrs

	# Unique identifier for the base URL
	field :base_url

end
