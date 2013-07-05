class WelcomeMailer < ActionMailer::Base
  default from: "info@theallycoalition.org"

  def canadian(email,event,facebook_photo=nil)
  	@facebook_photo = facebook_photo
    @event = event
  	mail(:to => email, :subject => "We loved meeting you, did you see your picture?")
  end
  def us_no_tweet(email,event,facebook_photo=nil,zip=nil)

    @facebook_photo = facebook_photo
    @email= email
  	@zip = zip
    @event = event

    form_url

    mail(:to => @email, :subject => "We loved meeting you - one small ask, just press a button")
  end

  def us_tweet(signup,event,facebook_photo=nil)

    @rep_list = signup.reps.map{ |r| [r['title'],r['firstName'],r['lastName'] ].join(' ') }.to_sentence
  	@event_name = event
  	@facebook_photo = facebook_photo
    @zip = signup.zip
    @email = signup.email

    form_url

  	mail(:to => @email, :subject => "We loved meeting you - one small ask, just press a button")
  end

  def form_url
    @form_url = "http://theallycoalition.org/soundoff"
  end
end
