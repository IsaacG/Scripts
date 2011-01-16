package Bot::BasicBot::Pluggable::Module::MyIP;

use warnings;
use strict;

use LWP::UserAgent;
use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help {"Give out my IP address"}

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'yourip'))
	{
		my $ua = LWP::UserAgent->new();
		$ua->timeout(10);
		my $response = $ua->get('http://checkip.dyndns.org/');
		$self->reply($args, $response->content());
		
	}
	return;
}

sub init
{
	my ($self) = @_;
}

1;
