package Bot::BasicBot::Pluggable::Module::Stats;

use warnings;
use strict;

use Time::Local;
use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Gather line count stats."; }

sub emoted
{
	my ($self, $args, $pri) = @_;
	return unless ($pri == 2);
	return unless ($::config{'stat_ACTIONS'});
	$self->count($args);
	return;
}

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );

	return unless ($pri == 2);

	return if ( $::config{'titler_IGNOREUSER'} and grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'titler_IGNOREUSER'} } );

	$self->count($args);

	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'stats'))
	{
		my @chans = ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'stats'));

		if (not defined $self->{'lastStat'}->{$args->{'channel'}})
		{
			$self->{'lastStat'}->{$args->{'channel'}} = 0;
		}

		my $nextAllowed = $self->{'lastStat'}->{$args->{'channel'}} + $::config{'stat_WAIT'} * 60;

		if ($nextAllowed > time)
		{
			$self->tell($args->{'who'}, sprintf("Sorry. Stats were done too recently. Try in %d seconds.", ($nextAllowed - time)));
		}
		else
		{
			$self->{'lastStat'}->{$args->{'channel'}} = time;
			$self->showStatsForChan($args->{'channel'}, hostmask($args), @chans);
		}
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'reset_stats'))
	{
		return unless ($self->Bot::BasicBot::Pluggable::Module::Utils::isOp($args));
		$self->bot()->{'stats'} = {};
		$self->reply($args, "Stats reset");
	}
	elsif (0 and $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'stats_add'))
	{
		my ($nick, $number) = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'stats_add');
		return unless ($self->Bot::BasicBot::Pluggable::Module::Utils::isOp($args));
		if ($nick and $number)
		{
			my $chan = lc($args->{'channel'});
			$self->bot()->{'stats'}->{$chan}->{$nick} += $number;
		}

	}
	return;
}

sub hostmask
{
	my ($args) = @_;
	my $host  = lc($args->{'raw_nick'});
	$host =~ s/^[^!]*!~?//;
	return $host;
}

sub count
{
	my ($self, $args) = @_;

	return if ( $::config{'stat_IGNORE'} and grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'titler_IGNOREUSER'} } );

	my $chan = lc($args->{'channel'});
	my $nick = lc($args->{'who'});
	my $raw  = hostmask($args);
	$self->bot()->{'stats'}->{'id'}->{$raw} = $nick;

	return unless (grep {$chan eq lc($_)} @{$::config{'stat_CHANS'}});

	$self->bot()->{'stats'}->{$chan} = {} unless (defined $self->bot()->{'stats'}->{$chan});
	$self->bot()->{'stats'}->{$chan}->{$raw}++;
}

sub tick
{
	my ($self) = @_;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	return unless (time > $self->{'nextShow'});
	$self->showStatsForChan($_) for (@{$::config{'stat_auto_CHANS'}});

	# Set the next showing to next midnight
	$self->setShowToMidnight();

	# Clear stats
	$self->bot()->{'stats'} = {};
}

sub showStatsForChan
{
	my ($self, $chan, $hostmask, @chans) = @_;
	$chan = lc($chan);

	return unless ($self->bot()->{'stats'}->{$chan});

	my @nicks = sort {$self->bot()->{'stats'}->{$chan}->{$b} <=> $self->bot()->{'stats'}->{$chan}->{$a}} keys %{$self->bot()->{'stats'}->{$chan}};
	my $count = 0;
	my $msg = "Stats: ";
	my @data = ();
	my $largest = $self->bot()->{'stats'}->{$chan}->{$nicks[0]};
	
	for my $nick (@nicks)
	{
		last unless ($self->bot()->{'stats'}->{$chan}->{$nick});
		last if (++$count >= ($::config{'stat_COUNT'} || 10));
		last if ($self->bot()->{'stats'}->{$chan}->{$nick} < $largest / 10);
		my $nickToUse = $self->bot()->{'stats'}->{'id'}->{$nick};
		my $nickCount = $self->bot()->{'stats'}->{$chan}->{$nick};
		unless( grep {$nickToUse eq lc($_)} @{$::config{'stat_FULLNAME'}} )
		{
			$nickToUse = substr($nickToUse, 0,-1) . "_" 
		}

		push @data, "$nickToUse = $nickCount";
		$hostmask = undef if ($hostmask and $hostmask eq $nick); # Prevent "you got" when nick already listed.
	}
	$msg .= join(', ', @data);
	$msg .= " (you got " . $self->bot()->{'stats'}->{$chan}->{$hostmask} . ")" if($hostmask);
	$self->tell($chan, $msg);
}

sub setShowToMidnight
{
	my ($self) = @_;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	my $next = timelocal(0,0,0,$mday,$mon,$year);
	$next += 60 * 60 * 24;
	$self->{'nextShow'} = $next;
}

sub init
{
	my ($self) = @_;
	$self->Bot::BasicBot::Pluggable::Module::Utils::configKeyLoader( 
		stat_CHANS => undef, 
		stat_COUNT => 10,
	);
	$self->bot()->{'stats'} = {} unless (defined $self->bot()->{'stats'});
	$self->{'lastStat'} = {};

	$self->setShowToMidnight();
}

1;
