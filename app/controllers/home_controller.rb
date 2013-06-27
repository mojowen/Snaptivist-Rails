class HomeController < ApplicationController
	def home
		@signups = Signup.all
	end
	def save
		signup = Signup.new( params[:signup] )
		render :json => {:success =>  signup.save }
	end
end
