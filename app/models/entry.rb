class Entry < ActiveRecord::Base
	belongs_to :collection
	has_many :properties
end
