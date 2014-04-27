class VisualizationController < ApplicationController

	def create

		# Create a new Visualization object
		visualization = Visualization.new

		# Generate an identifier for it
		visualization.identifier = SecureRandom.uuid
		while Visualization.find_by_identifier(visualization.identifier)
			visualization.identifier = SecureRandom.uuid
		end

		# Save the visualization
		visualization.save

		# Return the identifier
		render json: visualization

	end

	def get

		# Retrieve the correct visualization
		visualization = Visualization.find_by_identifier(params[:id])

		visualization.chart_options = visualization.chart_options.to_s.html_safe

		# Return the JSON data
		render json: visualization

	end

	def put

		# Retrieve the correct visualization
		visualization = Visualization.find_by_identifier(params[:id])

		# Replace the attributes that are passed in
		visualization.worksheet_id = params[:worksheet_id]
		visualization.object = params[:object]
		visualization.dataset = params[:dataset]
		visualization.chart_type = params[:chart_type]

		# Now set the chart options
		visualization.chart_options = params[:chart_options].to_json

		# Save the visualization
		visualization.save

		# Add it to the worksheet
		worksheet = Worksheet.find_by_identifier(params[:worksheet_id])
		worksheet.visualizations << visualization
		worksheet.save

		# Return success
		render json: ''

	end

	def delete

		# Retrieve the correct visualization
		visualization = Visualization.find_by_identifier(params[:id])
		visualization.destroy

		# Return a success
		render json: ''

	end

	def save

		# Create a new Visualization object
		visualization = Visualization.new

		# Now set the various things to our POST params

		puts params[:dataset]
		puts params[:filters]
		puts params[:chart_type]
		puts params[:chart_options]

		visualization.dataset = params[:dataset]
		visualization.filters = params[:filters]
		visualization.chart_type = params[:chart_type]
		visualization.chart_options = params[:chart_options]
		visualization.identifier = SecureRandom.uuid
		while Visualization.find_by_identifier(visualization.identifier)
			visualization.identifier = SecureRandom.uuid
		end

		# Find the corresponding worksheet
		worksheet_identifier = params[:worksheet]
		worksheet = Worksheet.find_by_identifier(worksheet_identifier)

		# Save the visualization to the worksheet
		worksheet.visualizations << visualization

		# Save the worksheet
		worksheet.save

		# Return null json
		jhash = Hash.new
		jhash["status"] = "ok"
		render json: jhash

	end

	def edit

		# Retrieve the correct visualization
		@visualization = Visualization.find_by_identifier(params[:id])

		# Get the current user
		@user = User.find(session[:id])

		# Check that the current user can access the encapsulating worksheet
		if not visualization.worksheet.users.include?(user)

			# Redirect to view (allowed by default)
			flash.now[:error] = "You do not have permissions to edit that visualization."
			redirect_to '/visualization/' + visualization.identifier

		end

	end

	def view

		# Retrieve the correct visualization
		@visualization = Visualization.find_by_identifier(params[:id])

		render layout: "sparse"

	end

	def destroy

		@visualization = Visualization.find_by_identifier(params[:id])
		worksheet = @visualization.worksheet.identifier
		@visualization.destroy

		redirect_to '/worksheet/' + worksheet + '/edit'

	end


end
