package Bot::BasicBot::Pluggable::Module::Commands;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = "0.4.0.0";

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Simple commands, eg !quit"; }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );

	return unless ($pri == 2);
	my $msg = lc($args->{'body'});
	
	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'reloadconfig'))
	{
		print "Reloading config\n";
		$self->reply($args, "Reloaded config file");
		::loadConfig();
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'quit'))
	{
		if (Bot::BasicBot::Pluggable::Module::Utils::isOwner($args))
		{
			exit;
		}
		else
		{
			#$self->bot()->emote(channel => $args->{'channel'}, body => 'runs to Anguissette "Stranger Danger!"');
			$self->reply($args, "Quit? Why should I? You ain't my boss!");
		}
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'ping'))
	{
		$self->reply($args, "pong");
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'pid'))
	{
		return unless ($args->{'channel'} eq 'msg');
		$self->reply($args, "PID: $$");
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'owner'))
	{
		$self->reply($args, $::config{'OWNER_DETAILS'}) if ($::config{'OWNER_DETAILS'});
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'sit'))
	{
		$self->bot()->emote(channel => $args->{'channel'}, body => 'sits obediently');
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'cookie'))
	{
		$self->bot()->emote(channel => $args->{'channel'}, body => 'eats a cookie');
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'eat'))
	{
		my $msg = $args->{'body'};
		$msg =~ s/.*eat //;
		$self->bot()->emote(channel => $args->{'channel'}, body => "eats $msg");
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'uptime'))
	{
		$self->reply($args, "I have been running since " . localtime($self->bot()->{'start_time'}));
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'conf'))
	{
		unless (Bot::BasicBot::Pluggable::Module::Utils::isOwner($args))
		{
			$self->reply($args, "You're not my owner!");
			return;
		}
		my ($key, @values) = ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'conf'));
		if (scalar(@values) == 0)
		{

			if (not defined $::config{$key})
			{
				$self->reply($args, "$key not defined.");
			}
			elsif (ref($::config{$key}) eq "ARRAY")
			{
				$self->reply($args, "$key = [" . join(", ", @{$::config{$key}}) . "]");
			}
			else
			{
				$self->reply($args, "$key = " . $::config{$key});
			}
		}
		elsif(scalar(@values) == 1)
		{
			$::config{$key} = $values[0];
		}
		else
		{
			$::config{$key} = [ @values ];
		}
	}


	return;
}

# --------- Helper functions

# --------- Create and start the Bot

1;
