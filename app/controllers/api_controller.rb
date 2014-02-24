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

		@collections = Collection.all

	end

	def get_records

		# First get the data model from Postgres
		id = params[:id]
		@collection = Collection.find_by(base_url: id)

		# Attempt to connect to MongoDB
 		#db = get_connection
 		#@collection = db[@dm.base_url]

 		if request.post?

 			# Figure out what sort of chart it is
 			chart = params[:chart]

 			# Now split based on the chart
 			if chart == 'pie'

 				# Get the key and the aggregate
				key = params[:key]
	 			aggregate = params[:aggregate]

	 			# Essentially MapReduce
	 			data = Hash.new
	 			@collection.entries.each do |entry|
	 				key_value = ""
	 				aggregate_value = 0
	 				entry.properties.each do |property|
	 					if property.name == key
	 						key_value = property.value
	 					end
	 					if property.name == aggregate
	 						aggregate_value = property.value.to_i
	 					end
	 				end
	 				if not data.key?(key_value)
	 					data[key_value] = 0
	 				end
	 				data[key_value] = data[key_value] + aggregate_value
	 			end

	 			# Compile data into format expected of pie charts
	 			json_data = Array.new
	 			data.each do |key, value|
	 				json_data_object = Hash.new
	 				json_data_object["label"] = key
	 				json_data_object["value"] = value
	 				json_data << json_data_object
	 			end

	 			# Render as JSON data
	 			render json: json_data


 			end
 			
 		end

 		# If there is a JSON option, process as JSON
 		type = params[:type]
 		page = params[:p]
 		if type == 'json' then
 			render json: @collection.entries.as_json(
 				:include => [:properties])
 		end

	end


end
