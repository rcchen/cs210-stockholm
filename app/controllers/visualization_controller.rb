class VisualizationController < ApplicationController

	def create

		# Get the current user
		@user = User.find(session[:id])

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
