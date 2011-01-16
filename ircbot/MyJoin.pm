package Bot::BasicBot::Pluggable::Module::MyJoin;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = "0.4.0.0";

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Let OPS join/leave on the fly"; }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless ($pri == 2 and $args->{'body'} );
	return if ( not grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'OPS'} } );

	my ($cmd, $what) = split(/\s+/, $args->{'body'}, 2);
	return unless ($what);

	$what = "#" . $what unless ($what =~ /^#/);

	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'join'))
	{
		$self->bot->join($what);
		return "OK.";
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'leave'))
	{
		$self->bot->part($what);
		return "OK.";
	}
	

	return;
}

my $missing = 0;
for my $key (qw/OPS/)
{
	next if (defined $::config{$key});
	print "Missing expected config value for [$key]\n";
	$missing++;
}

return 0 if ($missing);
1;
