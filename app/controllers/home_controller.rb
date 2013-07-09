class HomeController < ApplicationController
	protect_from_forgery :except => :save
	before_filter :require_login, :only => [:list,:analytics]

	def home
		@body_class = 'home'
	end
	def save
		signup = Signup.new( params[:signup] )
		if  signup.save
			render :json => {:success => true, :signup => params[:signup] }, :template => false
		else
			render :json => {:success => false, :signup => params[:signup] }, :template => false, :status => 500
		end
	end


	def analytics
		@title = 'ANALYTICS'
		@signups = Signup.all
		@by_show = Signup.all.group_by(&:source)
	end
	def list

		case params[:type]
			when 'tweets'
				@type = 'tweet'
				@diclaimer = 'only includes sent tweets.'
				@items = Status.find_all_by_sent(true).reverse

				@mapping = ['target','sender','message','photo_path','updated_at']
				@title_row = ['target','sender','messsage','photo','sent date']

			when 'emails'
				@type = 'email'
				@diclaimer = 'also includes friends'

				@title_row = ['email','first name','last name','zip','source','signed up at']
				@mapping = ['email','firstName','lastName','zip_code','source','photo_date']

				@items = Signup.all
				friends = []
				@items.each{ |s| (s.friends || '' ).split(',').each{ |email| friends.push( { :email => email, :source => s.source, :photo_date => s.photo_date } ) } }
				@items.concat friends


			else
				@type = 'signup'
				@items = Signup.all.reverse

				@mapping = ['firstName','lastName','email','source','photo_date','facebook_photo','photo_path','twitter','zip','tweet_count','friend_count']
				@title_row = ['first name','last name','email','source','date taken','facebook photo link','raw photo link','twitter name','zip','number of tweets','number of friends']
		end
		render :template => 'home/export', :layout => false if params[:export]
	end

end
