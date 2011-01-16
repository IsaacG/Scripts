package Bot::BasicBot::Pluggable::Module::WordOfTheDay;

use LWP::UserAgent;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help { "WordoftheDay" }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	if ( $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'wotd-clear') )
	{
		$self->{'last'} = 0;
	}
	if ( $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'wotd') )
	{
			my $response = $self->{'ua'}->get('http://dictionary.reference.com/wordoftheday')->content();
			my $word = (map /"me">([^<]+)</, split(/\n/, $response))[0];
			$word .= ": " . join(" | ", map /"defn">([^<]+)</, split(/\n/, $response));
			return $word;
	}
	return;
}

sub init
{
	my ($self) = @_;

	$self->{'ua'} = LWP::UserAgent->new(
		agent    => $::config{'titler_USERAGENT' } || die 'UA',
		timeout  => $::config{'titler_UATIMEOUT' } || die 'UTO',
		max_size => 81920,
	);
	$self->{'ua'}->max_size(81920);
	$self->{'ua'}->timeout($::config{'titler_UATIMEOUT'} || die 'UTO');
	$self->{'ua'}->agent($::config{'titler_USERAGENT'} || die 'UA');
}

1;
