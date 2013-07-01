jQuery(document).ready(function($) { 	
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
		console.log(scrollpos);	
		if (150 < scrollpos < 200) {
			$('nav ul li:first-child').addClass('active');
		} else if ( 199 < scrollpos < 250) {
			console.log('here');
		};	
		
	});
	
	
});