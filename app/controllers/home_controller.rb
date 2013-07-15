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
		@by_show = Signup.all.sort_by(&:photo_date).reverse.group_by( &:source)
	end
	def list
		if ! params[:export]
			limit = { :limit => 30, :offset => params[:offset], :order => 'created_at DESC' }
		else
			limit = {}
		end

		case params[:type]
			when 'tweets'
				@type = 'tweet'
				@diclaimer = 'only includes sent tweets.'

				limit[:conditions] = 'sent IS TRUE'
				@items = Status.all(limit).reverse

				@mapping = ['target','sender','message','photo_path','updated_at']
				@title_row = ['target','sender','messsage','photo','sent date']

			when 'emails'
				@type = 'email'
				@diclaimer = 'also includes friends'

				@title_row = ['email','first name','last name','zip','source','signed up at']
				@mapping = ['email','firstName','lastName','zip_code','source','photo_date']

				@items = Signup.all(limit)
				friends = []
				@items.each{ |s| (s.friends || '' ).split(',').each{ |email| friends.push( { :email => email, :source => s.source, :photo_date => s.photo_date } ) } }
				@items.concat friends


			else
				@type = 'signup'
				@items = Signup.all(limit)

				@mapping = ['firstName','lastName','email','source','photo_date','facebook_photo','photo_path','twitter','zip','tweet_count','friend_count']
				@title_row = ['first name','last name','email','source','date taken','facebook photo link','raw photo link','twitter name','zip','number of tweets','number of friends']
		end
		render :template => 'home/export', :layout => false if params[:export]
		render :template => 'home/list', :layout => false if params[:partial]
	end

end
