jQuery(document).ready(function($) {

	var search = document.location.search.toString().replace(/\?/,'').split("&"),
		config = {},
		base_url = 'http://snap-tivist.com'

	for (var i = search.length - 1; i >= 0; i--) {
		var param = search[i].split('=')
		config[ param[0] ] = unescape( param[1] );
		$('input[name='+param[0]+']').val( unescape( param[1] ) );
	};
	if( typeof config.firstName != 'undefined' && typeof config.email != 'undefined' && typeof config.zip != 'undefined' ) {
		var $known_user = $('.previous-user').show();
		$('.welcome .user-info',$known_user).text(config.firstName)
		$('.zipcode .user-info',$known_user).text(config.zip)

		$('.new-user-1').hide()
		if( typeof config.reps != 'undefined' ) setReps();
		else getReps(config.zip)
		openSoundOff({top: '200', message: 'please cosponsor Safe Schools: HR1652/HR1199 & S403/S1088 cc @allycoalition', zip: config.zip, email: config.email, campaign: 59 })
	}


	// Sticky header
	$(document).scroll(function(){
		var scrollpos = $(window).scrollTop();

		if (scrollpos >= 150) {
			$('header').addClass('fixed-header');
			$('#page').css('margin-top',256);
		} else if (scrollpos < 150) {
			$('header').removeClass('fixed-header');
			$('#page').css('margin-top',0);
		};
	});


	$(document).scroll(function(){
		var scrollpos = $(window).scrollTop();
		var step1 = $('nav ul li:nth-child(1)');
		var step2 = $('nav ul li:nth-child(2)');
		var step3 = $('nav ul li:nth-child(3)');
		var step4 = $('nav ul li:nth-child(4)');

		if (scrollpos < 150) {
			$('.active').removeClass('active');
		}

		if (150 < scrollpos) {
			step1.addClass('active');

			step2.removeClass('active');
		}

		if ( 600 < scrollpos ) {
			step2.addClass('active');

			step1.removeClass('active');
			step3.removeClass('active');
		}

		if (1400 < scrollpos ) {
			step3.addClass('active');

			step2.removeClass('active');
			step4.removeClass('active');
		}

		if (1700 < scrollpos) {
			step4.addClass('active');

			step3.removeClass('active');
		}

	});


	function slideToReps() {
		$(window).scrollTo(700,'slow');
	}
	$('#start').click(function(){
		$(window).scrollTo(150, 'slow', {
			axis: 'y',
		});
		$('.new-user-1').fadeOut();
		$('#info').css('height',600);
		$('.new-user-2').delay(500).fadeIn();
	});
	$('.go').click(function(e){
		var $this = $(this);
		if( $this.hasClass('new-user-3') ) {
			var errors = [],
				params = {}
			$this.parent().find('input[type=text]').each( function() {
				var $input = $(this).removeClass('oops')
				if( $input.attr('name') == 'zip' ) {
					if ($input.val().length != 5 ) {
						$input.addClass('oops')
						errors.push( $input )
					} else params.zip = $input.val()
				} else {
					if( $input.val().length < 1 ) {
						$input.addClass('oops')
						errors.push( $input )
					} else params[ $input.attr('name') ] = $input.val();
				}
			})
			if( errors.length > 1 ) {
				$('#info .wrapper').append('<span class="oops-msg"><i class="icon-warning-sign"></i>  Oops! Looks like you missed something.</span>');
				return false;
			}
			else {
				saveSignup( params );
				getReps( params.zip);
				$('.oops-msg').fadeOut();
			}
		} else {
			saveSignup( config )
		}
		$('#share').delay(0).slideDown('slow');
		$('#soundoff').delay(100).slideDown('slow');
		$('#reps').delay(200).slideDown('slow',slideToReps);
		$this.fadeOut();
	});
	$('.zipcode .edit').click( function(e) {
		$('input[name=zip]').val('')
		config.reps = '';
		$('.previous-user').fadeOut( function(){ $('.new-user-2').fadeIn();})
		e.preventDefault();
	})
	$('.soundoff').click(function(e) {
		var config = {campaign: 59}
		config.zip = $('input[name=zip]').val()
		config.email = $('input[name=email]').val()
		config.page_url = 'http://theallycoalition.org/soundoff'
		config.top = '200'
		openSoundOff(config)

		return false;
	})
	//$('.card img').error(function(e) { $(this).remove(); });
	$('.social.facebook').click( function(){
		window.open('https://www.facebook.com/sharer/sharer.php?u=http://theallycoalition.org/soundoff','fbsharer','toolbar=0,status=0,width=300,height=200');
		return false
	})
	$('.social.tumblr').click( function(){
		window.open('http://www.tumblr.com/share/link?url=www.theallycoalition.org/soundoff/&name=I+told+my+Congressional+Reps+to+support+safe+schools,+you+should+too&tags=mostnightstac,soundoff','tumbsharer','toolbar=0,status=0,width=300,height=200');
		return false
	})
	$('.social.twitter').click( function(){
		window.open("https://twitter.com/intent/tweet?&text=I+told+my+Congressional+Reps+to+support+safe+schools,+you+should+too:&url=http://theallycoalition.org/soundoff&related=allycoalition&via=allycoalition&hashtags=soundoff,mostnights",'twittershare','toolbar=0,status=0,width=300,height=200');
		return false
	})

	function getReps(zip) {
		$.ajax({
				url: 'http://congress.api.sunlightfoundation.com/legislators/locate?callback=?',
				dataType: 'jsonp',
				data: { apikey: '8fb5671bbea849e0b8f34d622a93b05a', zip: zip },
				success: function(r) {
					setReps(r.results);
				}
			})
	}
	function setReps(reps) {
		if( typeof reps != 'undefined' ) {
			for (var i = reps.length - 1; i >= 0; i--) {
				var rep = reps[i],
					rep_number = i +1,
					$rep_div = $('.rep_'+rep_number).show()
				$('img',$rep_div).attr('src',base_url + '/photos/'+rep.bioguide_id+'.jpg');
				$('h3:first',$rep_div).text( [rep.title,rep.firs_name, rep.last_name].join(' ') )
				var twitter_id  = rep.twitter_id ? ' | @'+rep.twitter_id : ''
				$('h3:last',$rep_div).text( rep.party+twitter_id )
			};
			if( reps.length > 3 ) $('.people').css({ left: ( 120 - ( reps.length - 3 ) * 125 ), width: (reps.length * 250) })
		}
	}
	function saveSignup(params) {
		params['source'] = 'webform'
		$.post( '/save', { signup: params} )
	}

});