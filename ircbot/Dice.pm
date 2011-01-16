package Bot::BasicBot::Pluggable::Module::Dice;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Roll XdY dice" }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	my @words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'roll');
	if (scalar(@words) == 1 and $words[0])
	{
		if ($words[0] =~ /^(\d+)d(\d+)$/)
		{
			my ($num, $type) = ($1, $2);
			my $sum = 0;
			my $i = 0;
			$sum += int(rand($type)) + 1 for (1..$num);
			$self->reply($args, sprintf("%s rolled %d on a %dd%d", $args->{'who'}, $sum, $num, $type));
		}
		else
		{
			$self->reply($args, "Usage: ?roll XdY  eg ?roll 1d10  or ?roll 2d6");
		}
	}
	return;
}

sub init
{
	my ($self) = @_;
}

1;
