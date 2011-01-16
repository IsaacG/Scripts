package Bot::BasicBot::Pluggable::Module::QueueHandler;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);
use Bot::BasicBot::Pluggable::Module::Utils qw(matchesCommand isOp);

our $VERSION = "0.4.0.0";

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Handle the queue."; }

sub processItem
{
	my ($self, $item) = @_;
	return 0 unless (defined $item);
	$self->{'lastTick'} = time;

	for my $chan ( @{$item->{'channels'} || die } )
	{
		$self->tell($chan, $item->{'line'});
	}

	return 1;
}

sub said
{
	my ($self, $args, $pri) = @_;
	return unless($args->{'body'} and $pri == 2);

	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'queue'))
	{
		$self->dumpQueue($args, ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'queue'))[0]);
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'clear'))
	{
		$self->clearQueue($args, ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'clear'))[0]);
	}
}

sub tick
{
	my ($self) = @_;
	die unless (defined $self);

	my $queues = $self->Bot::BasicBot::Pluggable::Module::Utils::queues();
	my $item;

	$self->{'lastTick'} = time unless ($self->{'lastTick'});

	die if (not defined $self->{'lastTick'});
	for (qw/queue_1DELAY queue_2DELAY queue_3DELAY/) { die if (not defined $::config{$_}) }

	# Check the 3 queues in priority order
	return if ($self->{'lastTick'} + $::config{'queue_1DELAY'} > time);
	return if ($self->processItem(shift @{$queues->{'1'}}));

	return if ($self->{'lastTick'} + $::config{'queue_2DELAY'} > time);
	return if ($self->processItem(shift @{$queues->{'2'}}));

	return if ($self->{'lastTick'} + $::config{'queue_3DELAY'} > time);
	return if ($self->processItem(shift @{$queues->{'3'}}));
}

sub clearQueue
{
	my ($self, $args, $priority) = @_;
	return unless $self->Bot::BasicBot::Pluggable::Module::Utils::isOp($args);
	my $chan = $args->{'channel'};
	$chan = $args->{'who'} if ($chan eq 'msg');

	if (not $priority)
	{
		$self->clearQueue($args, $_) for (1..3);
		return;
	}

	my $queues = $self->Bot::BasicBot::Pluggable::Module::Utils::queues();

	# Ensure the priority is valid
	die if (not exists $queues->{$priority});

	my @new;
	for my $item (@{$queues->{$priority}})
	{
		$item->{'channels'} = [ grep { $_ ne $chan } @{$item->{'channels'}} ];
		push @new, $item if (scalar(@{$item->{'channels'}}));
	}

	$queues->{$priority} = [@new];
}

sub dumpQueue
{
	my ($self, $args, $priority) = @_;

	if (not $priority)
	{
		$self->dumpQueue($args, $_) for (1..3);
		return;
	}

	my $queues = $self->Bot::BasicBot::Pluggable::Module::Utils::queues();
	my $chan = $args->{'channel'};
	$chan = $args->{'who'} if ($chan eq 'msg');

	# Ensure the priority is valid
	die if (not exists $queues->{$priority});

	my $count = 0;
	for my $item (@{$queues->{$priority}})
	{
		next unless (grep {$_ eq $chan} @{$item->{'channels'}});
		$count++;
	}
	print "Queue $priority: $count\n";
	$self->Bot::BasicBot::Pluggable::Module::Utils::queueSay("Items in queue $priority: $count", [$chan], 1);
}

sub init
{
	my $self = shift;
	$self->bot()->{'queues'} = {1 => [], 2 => [], 3 => []};
	$self->{'lastTick'} = 0;

	$self->Bot::BasicBot::Pluggable::Module::Utils::configKeyLoader( queue_1DELAY => 5, queue_2DELAY => 10, queue_3DELAY => 30 );
	die unless (defined $::config{'queue_1DELAY'});
	die unless (defined $::config{'queue_2DELAY'});
	die unless (defined $::config{'queue_3DELAY'});
}

1;
