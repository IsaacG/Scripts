package Bot::BasicBot::Pluggable::Module::Combat;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Combat Manager" }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	# stopped -> setup: !combat
	# setup: !join [initiative bonus] [name]
	# setup -> combat: !begin
	# combat: !turn [name]
	# combat: !die [name]
	# combat -> stopped: !end
	
	#return unless (lc($args->{'channel'}) eq '#test');
	my $who = $args->{'who'};
	my $state = $self->{'state'};
	my @words;
	my $players = $self->{'players'};
	my $turn = $self->{'order'}->[$self->{'turn'}];
	my $count = scalar(keys %{$players});

	if($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'combat'))
	{
		return "Can't start a combat while in middle of a combat. Use !end to finish first." unless ($state eq 'stopped');

		# Change state
		$self->{'state'} = 'setup';
		# Reset the player list
		$self->{'players'} = {};
		return "Initializing combat. Join now! Use: !join [initiative bonus] [name]";
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'join'))
	{
		
		return $self->reply($args, "Can't join the battle at this point.") unless ($state eq 'setup');
		
		my $bonus = 0;
		my (undef, @args) = split(/\s+/, $args->{'body'});
		for my $arg (@args)
		{
			if ($arg =~ /^\d+$/) { $bonus = $arg; }
			else { $who = $arg; }
		}
		my $initiative = (int(rand(20)) + 1 + $bonus);
		$players->{$who} = { initiative => $initiative };
		return sprintf("%s joined battle with initiative %d. Combat count: %d.", $who, $initiative, $count + 1);
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'begin'))
	{
		return "Combat needs to be initiated with !combat before it can begin." unless ($state eq 'setup');
		return "Can't begin combat with less than two players." unless ($count > 1);
		$self->{'state'} = 'combat';
		$self->{'order'} = [ sort { $players->{$b}->{'initiative'} <=> $players->{$a}->{'initiative'} } keys %{$players} ];
		$self->{'turn'}  = 0;
		return "Combat is joined. It's your turn, " . $self->{'order'}->[0];
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'turn'))
	{
		return "Can't end a turn unless a combat is in progress." unless ($state eq 'combat');

		my (undef, $arg) = split(/\s+/, $args->{'body'});
		$who = $arg if ($arg);

		return sprintf("It's not your turn, %s. %s is in middle of their turn.", $who, $turn) unless ($who eq $turn);
		$self->{'turn'} = ($self->{'turn'} + 1) % $count;
		return sprintf("%s is done their turn. Now it is your turn, %s.", $who, $self->{'order'}->[$self->{'turn'}]);
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'die'))
	{
		return "!die is not yet implemented." unless ($state eq 'combat');
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'end'))
	{
		return "Can't end combat; there is no combat in progress." if ($state eq 'stopped');
		$self->{'state'} = 'stopped';
		return "Combat ended.";
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'state'))
	{
		return "Combat state is " . $state;
	}

	return;
}

sub init
{
	my ($self) = @_;
	$self->{'state'} = "stopped";
	$self->{'turn'} = 0;
	$self->{'players'} = {};
}

1;
