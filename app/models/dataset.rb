# The Dataset is the base collection type in our data system
class Dataset

	include Mongoid::Document

	# Be sure to store timestamps
	include Mongoid::Timestamps::Created
	include Mongoid::Timestamps::Updated

	# Multiple users can own datasets
	has_and_belongs_to_many :users

	# Defines one to many with Datadocs
	has_many :datadocs

	# Name of the Dataset
	field :name

	# Attributes of the Dataset
	# Also specifies the type of the attribute
	field :attrs

	# Unique identifier for the base URL
	field :identifier

	# Expected count of datadocs
	# Used to determine if there are jobs in the queue
	field :expected_count

	def self.find_by_identifier(identifier)
    	self.where(:identifier => identifier).first()
	end

end
