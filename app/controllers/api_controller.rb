class ApiController < ApplicationController

	# Gets a connection to the MongoHQ server
	def get_connection
	  return @db_connection if @db_connection
	  db = URI.parse(ENV['MONGOHQ_URL'])
	  db_name = db.path.gsub(/^\//, '')
	  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
	  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
	  @db_connection
	end

	def index

		@dms = DataModel.all

	end

	def get_records

		# First get the data model from Postgres
		id = params[:id]
		@dm = DataModel.find_by(base_url: id)

		# Attempt to connect to MongoDB
 		db = get_connection
 		@collection = db[@dm.base_url]

 		# If there is a JSON option, process as JSON
 		type = params[:type]
 		page = params[:p]
 		puts type
 		if type == 'json' then
 			render json: @collection.find({}, {:limit => 10, :skip => 10 * page.to_i })
 		end

	end


end
