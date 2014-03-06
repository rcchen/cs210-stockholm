require 'bcrypt'

# The User is the base authenticated profile
class User

	include Mongoid::Document
	include Mongoid::Timestamps
	include BCrypt

	field :email,			:type => String
	field :password_hash, 	:type => String

	# Validators on the email address
	validates_presence_of :email, :message => "Email address is required."
	validates_uniqueness_of :email, :message => "Email address is already registered. Check your password?"
	
	# Users can own multiple datasets
	has_and_belongs_to_many :worksheets
	has_and_belongs_to_many :datasets

	def self.find_by_email(email)
    	self.where(:email => email).first()
  	end

    def password
      @password ||= Password.new(password_hash)
    end

    def password=(new_password)
    	puts new_password
      	@password = Password.create(new_password)
      	self.password_hash = @password
    end

end