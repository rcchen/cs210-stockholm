class Dataset
	include Mongoid::Document
	include Mongoid::Timestamps::Created
	include Mongoid::Timestamps::Updated
	has_many :datadocs
	field :name
	field :attrs
	field :base_url
end
