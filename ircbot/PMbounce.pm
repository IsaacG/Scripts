package Bot::BasicBot::Pluggable::Module::PMbounce;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = "0.4.0.0";

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Bounce PMs to the OWNER"; }

my $state = 0;
sub said 
{
	my ($self, $args, $pri) = @_;
	return unless ($pri == 2 and $args->{'body'} and $args->{'channel'} eq 'msg' );
	return if ( lc($args->{'who'}) eq lc($::config{'OWNER'}) );

	$self->tell($::config{'OWNER'}, $args->{'who'} . " told me: " . $args->{'body'});

	return;
}

1;
