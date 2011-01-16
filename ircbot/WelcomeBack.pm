package Bot::BasicBot::Pluggable::Module::WelcomeBack;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help { "wb script" }

sub loadWelcomeBacks
{
	my ($self) = @_;
	$self->{'wb'} = {};
	my $FH;
	open $FH, "<", $::config{'wb_DATA'};
	
	if (not $FH)
	{
		print "Can not open WelcomeBack data file. Making empty one. [wb_DATA => " . $::config{'wb_DATA'} . "\n";
		open $FH, ">", $::config{'wb_DATA'} or die "Error creating wb file";
		close $FH;
		return;
	}

	while (my $line = <$FH>)
	{
		chomp $line;
		# time set, who set it, channel it is for, nick it is for, message
		my ($time, $setBy, $channel, $nick, $wb) = split(/\t/, $line, 5);
		next unless ($nick and $wb);
		next if ($::config{'wb_EXPIRY'} and ($time + $::config{'wb_EXPIRY'} * 60 * 60 * 24) < time);
		($channel, $nick) = (lc($channel), lc($nick));
		$self->{'wb'}->{$channel} = {};
		$self->{'wb'}->{$channel}->{$nick} = {};
		$self->{'wb'}->{$channel}->{$nick}->{'msg'} = $wb;
		$self->{'wb'}->{$channel}->{$nick}->{'time'} = $time;
	}
}

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	# Stop here on IGNOREUSER
	return if ( $::config{'titler_IGNOREUSER'} and grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'titler_IGNOREUSER'} } );

	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'reloadwb'))
	{
		loadWelcomeBacks();
		$self->reply($args, "Loaded");
		return;
	}

	# Setting WB - only let in WB channels
	return unless (grep {lc($args->{'channel'}) eq lc($_)} @{$::config{'wb_CHANS'}});
	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'setwb'))
	{
		my ($nick, @words) = ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'setwb'));
		if (@words)
		{
			$nick = lc($nick);
			if ($nick eq lc($args->{'who'}))
			{
				$self->reply($args, "You can't set the WB for yourself.");
				return;
			}

			$self->setWelcomeBack($args->{'who'}, $args->{'channel'}, $nick, join(' ', @words));
			$self->reply($args, "Done.");
		}
		elsif ($nick)
		{
			$self->reply($args, "WB for $nick is: " . $self->getWb($args->{'channel'}, $nick));
		}
	}
}

sub getWb
{
	my ($self, $channel, $nick) = @_;
	$nick = lc($nick);
	$channel = lc($channel);
	return "<undefined>" unless ($self->{'wb'}->{$channel} and $self->{'wb'}->{$channel}->{$nick} and $self->{'wb'}->{$channel}->{$nick}->{'msg'});
	if ($::config{'wb_EXPIRY'} and $self->{'wb'}->{$channel}->{$nick}->{'time'})
	{
		my $endTime = $self->{'wb'}->{$channel}->{$nick}->{'time'} + $::config{'wb_EXPIRY'} * 60 * 60 * 24;
		return "<expired>" if ($endTime < time);
	}
	return $self->{'wb'}->{$channel}->{$nick}->{'msg'};
}

sub setWelcomeBack
{
	my ($self, $setBy, $channel, $setFor, $msg) = @_;
	$setBy = lc($setBy);
	$setFor = lc($setFor);
	$channel = lc($channel);
	open my $FH, '>>', $::config{'wb_DATA'} or die "Can not open file: " . $::config{'wb_DATA'};
	# time set, who set it, channel it is for, nick it is for, message
	print $FH join("\t", time, $setBy, $channel, $setFor, $msg) . "\n";
	close $FH;
	$self->{'wb'}->{$channel}->{$setFor}->{'msg'} = $msg;
	$self->{'wb'}->{$channel}->{$setFor}->{'time'} = time;
}

sub chanjoin {
	my ($self, $args) = @_;
	return unless ($args->{'body'} eq 'chanjoin');
	return unless (grep {lc($args->{'channel'}) eq lc($_)} @{$::config{'wb_CHANS'}});
	#$self->tell('yitz', $args->{'who'} . " joined " . $args->{'channel'});
	my $reply = $self->getWb($args->{'channel'}, $args->{'who'});
	return unless ($reply and $reply ne '<expired>' and $reply ne '<undefined>');

	# When was this wb last said in this channel
	my $lastUsed = $self->{'wb'}->{lc($args->{'channel'})}->{lc($args->{'who'})}->{lc($args->{'channel'})};
	return if ($lastUsed and $lastUsed + $::config{'wb_MINWAIT'} > time);
	$self->{'wb'}->{lc($args->{'channel'})}->{lc($args->{'who'})}->{lc($args->{'channel'})} = time;

	if ($reply =~ /^\/me/)
	{
		$reply =~ s/^\/me *//;
		$self->bot()->emote(channel => $args->{'channel'}, body => $reply);
	}
	else
	{
		$self->tell($args->{'channel'}, $reply);
	}
}

sub init
{
	my ($self) = @_;
	$self->Bot::BasicBot::Pluggable::Module::Utils::configKeyLoader( 
		wb_CHANS => undef, 
		wb_DATA => "welcomeBac.txt", 
		wb_EXPIRY => 0,
		wb_MINWAIT => 150,
	);
	$self->loadWelcomeBacks();
}

1;
