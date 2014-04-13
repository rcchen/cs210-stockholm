require 'chronic'

class DatasetProcessor

	@queue = :dataset

	def self.perform(dataset, attributes, hashes)

		# Get the correct dataset
		ds = Dataset.find_by_identifier(dataset['identifier'])

		# Rewrite the data types in the dataset
 		hashes.each_with_index do |hash, index|
 			
 			# Create a new Datadoc
 			datadoc = Datadoc.new
 			
 			# Iterate through attributes of the hash
 			hash.each do |attribute|

 				# Retrieve the name and value of each attribute
 				name = attribute[0]
 				value = attribute[1]

 				# Typecast if the attribute type is Numeric
 				if attributes[name] == 'Numeric'
 					value = value.to_f
 				elsif attributes[name] == 'Date'
 					value = Chronic.parse(value)
 				else
 					value = value
 				end

 				# Dynamically create the attribute in our Datadoc
 				datadoc["#{name}"] = value

 				datadoc.save

 			end

 			# Add the Datadoc into our Dataset
 			ds.datadocs.push(datadoc)

 		end

 		puts ds['identifier']
 		puts ds.datadocs.length

 		# Save the dataset
 		ds.save

	end

end
