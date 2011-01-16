package Bot::BasicBot::Pluggable::Module::Remind;

#TODO 
# Save/Load

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);
use Bot::BasicBot::Pluggable::Module::Utils;

our $VERSION = "0.4.0.0";

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Reminder bot. !remind time thing. time can take [0-9]+[mhd]. Defaults to m"; }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless ($pri == 2 and $args->{'body'} );

	if (Bot::BasicBot::Pluggable::Module::Utils::isOwner($args) and $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'reminddump'))
	{
		$self->tell($args->{'who'}, join("; ", @$_{qw/who when what/})) for (@{$self->{'reminders'}});
		return;
	}

	my ($rwho, $when, @what);
	($rwho, $when, @what) = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'remind');
	($rwho, $when) = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'snooze') unless ($rwho);
	return unless ($rwho);

	if ($rwho =~ /^\d+[smhd]?$/)
	{
		unshift @what, $when;
		$when = $rwho;
		$rwho = $args->{'who'};
	}

	$rwho = $args->{'who'} if ($rwho eq 'me');

	unless ($when =~ /^\d+[smhd]?$/)
	{
		$self->bot()->notice($args->{'who'}, "Invalid time stamp used: $when");
		return;
	}

	my $what = scalar(@what) ? join(' ', @what) : "";

	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'snooze'))
	{
		if ($self->{'last_told'}->{$rwho})
		{
			$what = $self->{'last_told'}->{$rwho};
		}
		else
		{
			$self->bot()->notice($args->{'who'}, "Nothing to snooze!");
			return;
		}
	}

	my $delay = $1 if ($when =~ /(\d+)/);
	$delay *= 60       if ($when =~ /m/ or $when =~ /^\d+$/);
	$delay *= 60*60    if ($when =~ /h/);
	$delay *= 60*60*24 if ($when =~ /d/);
	push @{$self->{'reminders'}}, { when => time + $delay, who => $rwho, what => $what };
	$self->saveReminders();

	$self->bot()->notice($args->{'who'}, "Reminder set");

	return;
}

my $nextTick = 0;
sub tick
{
	return unless time >= $nextTick;

	my ($self) = @_;
	my @new = ();
	my $changed = 0;
	for my $item (@{$self->{'reminders'}})
	{
		if ( $item->{'when'} < time )
		{
			$self->tell($item->{'who'}, "Reminder: " . $item->{'what'});
			$self->{'last_told'}->{$item->{'who'}} = $item->{'what'};
			$changed++;
		} else {
			push @new, $item;
		}
	}
	$self->{'reminders'} = [@new];
	$self->saveReminders() if ($changed);
	$nextTick = time + ( $::config{'remind_INTERVAL'} || 30 );
}

# --------- helper functions

sub loadReminders
{
	my ($self) = @_;
	return unless $::config{'remind_FILE'};
	return unless -f $::config{'remind_FILE'};

	open my $FH, "<", $::config{'remind_FILE'} or die "Can't open remind file [" . $::config{'remind_FILE'} . "]";
	while (my $line = <$FH>)
	{
		chomp $line;
		my ($when, $who, $what) = split(/\t/, $line, 3);
		push @{$self->{'reminders'}}, { when => $when, who => $who, what => $what };
	}
	close $FH;
}

sub saveReminders
{
	my ($self) = @_;
	return unless $::config{'remind_FILE'};

	open my $FH, ">", $::config{'remind_FILE'} or die "Can't open for write remind file [" . $::config{'remind_FILE'} . "]";
	for my $item ( @{$self->{'reminders'}} )
	{
		print $FH join("\t", $item->{'when'}, $item->{'who'}, $item->{'what'}) . "\n";
	}
	close $FH;
}

sub init
{
	my $self = shift;
	$self->{'reminders'} = [];
	$self->{'last_told'} = {};

	print "No remind_FILE config set!\n" if ( not $::config{'remind_FILE'} );
	print "No remind_INTERVAL config set!\n" if ( not $::config{'remind_INTERVAL'} );
	$self->loadReminders();
}

1;
