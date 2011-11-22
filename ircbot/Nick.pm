package Bot::BasicBot::Pluggable::Module::Nick;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

sub help { "Change bot's nick"; }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );

	return unless ($pri == 2);

	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'nick'))
	{
		return unless (Bot::BasicBot::Pluggable::Module::Utils::isOwner($args));
		my ($nick) = ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'nick'));
		$self->reply($args, "Renick to $nick");
		$self->bot()->{'kernel'}->post($self->bot()->{'IRCNAME'}, 'nick', $nick);
		$self->bot()->nick($nick);
	}
	return;
}

sub init
{
}

1;
