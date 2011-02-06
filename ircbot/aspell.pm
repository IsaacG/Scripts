package Bot::BasicBot::Pluggable::Module::aspell;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

sub help { "Interface to CLI aspell" }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	my @words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'spell');
	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'check') unless (scalar(@words) and $words[0]);
	return unless (@words and $words[0]);
	my $cmd = 'aspell -a <<< "' . join(" ", @words) . '"';
	my @results = split(/\n/, `$cmd`);
	shift @results;
	
	for my $i (0..scalar(@words)-1)
	{
		$self->tell($args->{'who'}, $results[$i] eq "*" ? "$words[$i]: Good" : "$words[$i]: $results[$i]");
	}

	return;
}

sub init
{
	my ($self) = @_;
}

1;
