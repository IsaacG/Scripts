package Bot::BasicBot::Pluggable::Module::Say;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = "0.4.0.0";

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Have the bot tell() WHO WHAT -> !say WHO WHAT. Use privmsg"; }

my $state = 0;
sub said 
{
	my ($self, $args, $pri) = @_;
	return unless ($pri == 2 and $args->{'body'} );
	#return if ( not grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'OPS'} } );

	my ($cmd, $who, $what) = split(/\s+/, $args->{'body'}, 3);
	return unless ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'say'));
	
	my $person = lc($args->{'who'});
	unless (grep {lc($_) eq $person} @{$::config{'OPS'}})
	{
		$self->tell($args->{'who'}, "You are not an op.");
		return;
	}
	if ($what =~ /^\/me/)
	{
		$what =~ s/^\/me *//;
		$self->bot()->emote(channel => $who, body => $what);
	}
	else
	{
		$self->tell($who, $what);
	}

	return;
}

1;
