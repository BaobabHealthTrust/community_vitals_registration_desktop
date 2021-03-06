class GenericSessionsController < ApplicationController
	skip_before_filter :authenticate_user!, :except => [:location, :update]
	skip_before_filter :location_required

	def new
	end


	def create
		user = User.authenticate(params[:login], params[:password])
		sign_in(:user, user) if user
		authenticate_user! if user

		session[:return_uri] = nil
		session[:datetime] = nil

		if user_signed_in?
			current_user.reset_authentication_token
			#my_token = current_user.authentication_token
			#User.find_for_authentication_token()
			#self.current_user = user      
			redirect_to '/clinic'
		else
			note_failed_signin
			@login = params[:login]
			render :action => 'new'
		end
	end

	# Form for entering the location information
	def location
		@login_wards = (CoreService.get_global_property_value('facility.login_wards')).split(',') rescue []
		if (CoreService.get_global_property_value('select_login_location').to_s == "true" rescue false)
			render :template => 'sessions/select_location'
		end
	end

	# Update the session with the location information
	def update    
		# First try by id, then by name
		location = Location.find(params[:location]) rescue nil
		location ||= Location.find_by_name(params[:location]) rescue nil

		valid_location = (generic_locations.include?(location.name)) rescue false

		unless location and valid_location
			flash[:error] = "Mwalowesa dzina lolakwika"
      render :action => 'location'
			return    
		end
		  
    self.current_location = location  
		redirect_to '/clinic'
	end

  def select_location
    
  end

	def destroy
		sign_out(current_user) if !current_user.blank?
		self.current_location = nil
		flash[:notice] = "Mwatuluka."
		redirect_back_or_default('/')
	end

	protected
		# Track failed login attempts
		def note_failed_signin
			flash[:error] = "Mwalakwisa dzina lolowera kapena dzina la chinsinsi"
			logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
		end
end
