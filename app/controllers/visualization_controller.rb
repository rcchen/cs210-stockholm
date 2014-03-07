class VisualizationController < ApplicationController

	def create

		# Get the current user
		@user = User.find(session[:id])

	end

	def save

		# Create a new Visualization object
		visualization = Visualization.new

		# Now set the various things to our POST params
		visualization.dataset = params[:dataset]
		visualization.filters = params[:filters]
		visualization.chart_type = params[:chart_type]
		visualization.chart_options = params[:chart_options]
		visualization.identifier = params[:identifier]

		# Find the corresponding worksheet
		worksheet_identifier = params[:w]
		worksheet = Worksheet.get_by_identifier(worksheet_identifier)

		# Save the visualization to the worksheet
		worksheet.visualizations << visualization

		# Save the worksheet
		worksheet.save

		# Redirect to the worksheet page
		redirect_to '/worksheet/' + worksheet_identifier

	end

	def edit

		# Retrieve the correct visualization
		@visualization = Visualization.get_by_identifier(params[:id])

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
		@visualization = Visualization.get_by_identifier(params[:id])

	end

end
