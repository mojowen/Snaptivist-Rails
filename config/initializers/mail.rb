if ENV['MANDRILL_APIKEY']
	#  If Mandril is set up - use Mandril
	ActionMailer::Base.smtp_settings = {
	    :port =>           '587',
	    :address =>        'smtp.mandrillapp.com',
	    :user_name =>      ENV['MANDRILL_USERNAME'],
	    :password =>       ENV['MANDRILL_APIKEY'],
	    :domain =>         'snap-tivist.com',
	    :authentication => :plain
	}
	ActionMailer::Base.delivery_method = :smtp
end
Rails.application.routes.default_url_options[:host] =  ( ENV['BASE_DOMAIN'].gsub(/(https|http|\:|\/\/)/,'') rescue 'localhost:3000' )