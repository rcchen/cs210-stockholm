require 'csv'
require 'json'

class ParserController < ApplicationController

 	def index

    	

 	end

 	def upload

 		# The file data is stored in CSV
 		file_data = params[:csv]
 		
 		# Check that we are able to read the data
 		if file_data.respond_to?(:read)

 			# Create an array to store CSV rows
 			rows = Array.new
 			
 			# Parse apart our CSV file and read the rows into our array
 			CSV.parse(file_data.read) do |csv_obj|
 				rows.push(csv_obj)
 			end

 			# Headers are stored in the first row
 			@attributes = rows[0]
 			rows.delete_at(0)

 			# Now create a representation of the model we want
 			@dm = DataModel.new
 			@dm.name = params[:name]
 			@dm.attrs = @attributes.to_json
 			@dm.base_url = SecureRandom.hex(10)
 			# @dm.name = params[:name]
 			# @dm.attributes = @attributes.join(',')
 			# @dm.base_url = SecureRandom.uuid
 			@dm.save()

 			# TODO: Use metaprogramming to dynamically generate class
 			@hashes = Array.new
 			rows.each do |row|

 				# Parse into hashes
 				h = Hash.new
 				@attributes.each_with_index do |attribute, index|
 					h[attribute] = row[index]
 				end

 				@hashes.push(h)

 			end

 		end

 	end

end
