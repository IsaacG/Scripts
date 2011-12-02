package Bot::BasicBot::Pluggable::Module::Modes;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Mode peoples" }

sub said 
{
	my ($self, $args, $pri) = @_;
	my @words;
	my ($msg, $chan, $tmp, $who);

	return unless( $args->{'body'} );
	return unless ($pri == 2);

	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'mode');
	if (scalar(@words) and $words[1]) 
	{
		$chan = substr($words[0], 0, 1) eq '#' ? shift (@words) : $args->{'channel'};

		unless (Bot::BasicBot::Pluggable::Module::Utils::isChanOp($self, $args->{'who'}, $chan) or Bot::BasicBot::Pluggable::Module::Utils::isOwner($args)) {
			$self->reply($args, "You're not an op");
			return;
		}

		$msg = join(' ', @words);
		$self->bot()->mode($chan, $msg);
		return
	}

	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'kick');
	if (scalar(@words) and $words[1]) 
	{
		$chan = substr($words[0], 0, 1) eq '#' ? shift (@words) : $args->{'channel'};
		
		unless (Bot::BasicBot::Pluggable::Module::Utils::isChanOp($self, $args->{'who'}, $chan) or Bot::BasicBot::Pluggable::Module::Utils::isOwner($args)) {
			$self->reply($args, "You're not an op");
			return;
		}

		$msg = shift (@words);
		$self->bot()->kick($chan, $msg, @words);
		return
	}

	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'nick');
	if (0 and scalar(@words) and $words[0])
	{
		unless (Bot::BasicBot::Pluggable::Module::Utils::isOwner($args)) {
			$self->reply($args, "You're not an op");
			return;
		}

		$self->reply($args, "Nick $words[0]");
		$self->bot()->nick($words[0]);
		$self->reply($args, "identify $words[1]") if ($words[1]);
		$self->tell('nickserv', "identify $words[1]") if ($words[1]);
		return
	}

	return;
}

sub init
{
}

1;
