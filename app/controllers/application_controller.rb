class ApplicationController < ActionController::Base
	protect_from_forgery
	layout 'application.html'

	def require_login
		unless logged_in?
			flash[:error] = "You must be logged in to access this section"
			session[:return_to] = request.fullpath
			redirect_to new_user_session_path # halts request cycle
		end
	end
	def logged_in?
		!!current_user
	end
	def after_sign_in_path_for(resource)
    	request.env['omniauth.origin'] || stored_location_for(resource) || analytics_path
  	end
end
