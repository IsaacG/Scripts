package Bot::BasicBot::Pluggable::Module::Words;

use warnings;
use strict;

use Data::Dumper;
use Time::Local;
use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Gather line count words."; }

sub emoted
{
	my ($self, $args, $pri) = @_;
	return unless ($pri == 2);
	return unless ($::config{'word_ACTIONS'});
	$self->count($args);
	return;
}

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );

	return unless ($pri == 2);

	return if ( $::config{'word_IGNORE'} and grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'word_IGNORE'} } );

	$self->count($args);

	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'words'))
	{
		my (@chans) = ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'words'));
		if (not defined $self->{'lastStat'}->{$args->{'channel'}})
		{
			$self->{'lastStat'}->{$args->{'channel'}} = 0;
		}

		my $nextAllowed = $self->{'lastStat'}->{$args->{'channel'}} + $::config{'word_WAIT'} * 60;

		if ($nextAllowed > time)
		{
			$self->tell($args->{'who'}, sprintf("Sorry. Stats were done too recently. Try in %d seconds.", ($nextAllowed - time)));
		}
		else
		{
			$self->{'lastStat'}->{$args->{'channel'}} = time;
			$self->showWordsForChan($args->{'channel'}, hostmask($args), @chans);
		}
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'word_dump'))
	{
		unless ($self->Bot::BasicBot::Pluggable::Module::Utils::isOp($args))
		{
			$self->reply($args, "You're not an op");
			return;
		}
		open my $FH, ">", $ENV{"HOME"} . "/WordDump";
		unless ($FH)
		{
			$self->reply($args, "Failed to open file");
			return;
		}
		print $FH Dumper($self->bot()->{'words'});
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'remove_user'))
	{
		my ($nick) = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'remove_user');
		unless ($self->Bot::BasicBot::Pluggable::Module::Utils::isOp($args))
		{
			$self->reply($args, "You're not an op");
			return;
		}
		return unless ($nick);

		for my $hostmask (keys %{$self->bot()->{'words'}->{'id'}})
		{
			if (lc($nick) eq $self->bot()->{'words'}->{'id'}->{lc($hostmask)})
			{
				for my $chan (keys %{$self->bot()->{'words'}})
				{
					delete $self->bot()->{'words'}->{$chan}->{$hostmask};
				}
			}
		}
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'reset_words'))
	{
		return unless ($self->Bot::BasicBot::Pluggable::Module::Utils::isOp($args));
		$self->bot()->{'words'} = {};
		$self->reply($args, "Words reset");
	}
	elsif (1 and $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'words_add'))
	{
		my ($nick, $number) = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'words_add');
		unless ($self->Bot::BasicBot::Pluggable::Module::Utils::isOp($args))
		{
			$self->reply($args, "You're not an op");
			return;
		}
		if ($nick and $number)
		{
			my $chan = lc($args->{'channel'});
			my $hostmask = (grep {lc($nick) eq $self->bot()->{'words'}->{'id'}->{lc($_)}} keys %{$self->bot()->{'words'}->{'id'}})[0];
			if (not $hostmask)
			{
				$self->reply($args, "Couldn't find that nick");
			}
			else
			{
				$self->bot()->{'words'}->{$chan}->{$hostmask} += $number;
				#$self->reply($args, "Added $number words to $hostmask");
			}
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

	return if ( $::config{'word_IGNORE'} and grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'word_IGNORE'} } );

	my $chan = lc($args->{'channel'});
	my $nick = lc($args->{'who'});
	my $raw  = hostmask($args);
	$self->bot()->{'words'}->{'id'}->{$raw} = $nick;

	return unless (grep {$chan eq lc($_)} @{$::config{'word_CHANS'}});

	$self->bot()->{'words'}->{$chan} = {} unless (defined $self->bot()->{'words'}->{$chan});
	$self->bot()->{'words'}->{$chan}->{$raw} += scalar(split(/\s/, $args->{'body'}));
}

sub tick
{
	my ($self) = @_;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	return unless (time > $self->{'nextShow'});
	$self->showWordsForChan($_) for (@{$::config{'word_CHANS'}});

	# Set the next showing to next midnight
	$self->setShowToMidnight();

	# Clear words
	#$self->bot()->{'words'} = {};
}

sub removeUser
{
	my ($self, $args) = @_;
}

sub showWordsForChan
{
	my ($self, $chan, $hostmask, @chans) = @_;
	$chan = lc($chan);

	return unless ($self->bot()->{'words'}->{$chan});

	my @nicks = sort {$self->bot()->{'words'}->{$chan}->{$b} <=> $self->bot()->{'words'}->{$chan}->{$a}} keys %{$self->bot()->{'words'}->{$chan}};
	my $count = 0;
	my $msg = "Words: ";
	my @data = ();
	my $largest = $self->bot()->{'words'}->{$chan}->{$nicks[0]};
	for my $nick (@nicks)
	{
		last unless ($self->bot()->{'words'}->{$chan}->{$nick});
		last if (++$count >= ($::config{'word_COUNT'} || 10));
		#last if ($self->bot()->{'words'}->{$chan}->{$nick} < $largest / 10);
		push @data, join(" = ", $self->bot()->{'words'}->{'id'}->{$nick}, $self->bot()->{'words'}->{$chan}->{$nick});
	}
	$msg .= join(', ', @data);
	$msg .= " (you got " . $self->bot()->{'words'}->{$chan}->{$hostmask} . ")" if($hostmask);
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
		word_CHANS => undef, 
		word_COUNT => 10,
	);
	$self->bot()->{'words'} = {} unless (defined $self->bot()->{'words'});

	$self->setShowToMidnight();
}

1;
