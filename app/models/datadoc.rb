# The Datadoc is the base document type in our data system
class Datadoc

	include Mongoid::Document

	# Defines the one to many relationship with Datasets	
	belongs_to :dataset

	# There are no attributes explicitly defined here
	# Attributes are dynamically generated from the parser
	# See http://mongoid.org/en/mongoid/docs/documents.html#dynamic_fields

end
