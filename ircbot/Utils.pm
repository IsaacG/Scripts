package Bot::BasicBot::Pluggable::Module::Utils;

sub queues
{
	my ($self) = @_;
	return $self->bot()->{'queues'};
}

sub queueSize
{
	my ($self, $priority) = @_;
	my $queues = $self->{'queues'};
	my $queues = $self->Bot::BasicBot::Pluggable::Module::Utils::queues();

	# Ensure the priority is valid
	die "No such queue [$priority]" if ($priority and not exists $queues->{$priority});

	# Return if a specific queue has items
	return scalar(@{$queues{$priority}}) if ($priority);

	# For no priority, check all queues
	return $self->queueSize(1) || $self->queueSize(2) || $self->queueSize(3);
}

# Add a line to be queued to be said on $channels (array ref) with $priority
sub queueSay
{
	my ($bot, $line, $channels, $priority) = @_;
	die join(', ', caller()) unless ($line);
	die join(', ', caller()) unless ($channels);
	die join(', ', caller()) unless (scalar(@$channels));
	$priority ||= 3;

	push @{$bot->bot()->{'queues'}->{$priority}}, {line => $line, channels => $channels};
}


# Compare the who to the OWNER in the config
sub isOwner
{
	my ($args) = @_;
	return 0 if (not defined $::config{'OWNER'});
	return (lc($args->{'who'}) eq lc($::config{'OWNER'}));
}

# Compare the who to the OPs in the config
sub isOp
{
	my ($bot, $args) = @_;
	return 0 if (not defined $::config{'OPS'});
	return 1 if (grep {lc($_) eq lc($args->{'who'})} @{$::config{'OPS'}});
	return 0;
	
}

# Check to see if the keys are set in the config. If not warn and, if supplied, use default
sub configKeyLoader
{
	my ($bot, %hash) = @_;
	for my $k (keys %hash)
	{
		next if(defined $::config{$k});
		print "Key [$k] was not set in the config file.";
		if (defined $hash{$k})
		{
			print " Using default value [$hash{$k}].";
			$::config{$k} = $hash{$k};
		}
		print "\n";
	}
}

# See if the arg->body starts with an addressed command checking various layouts
# Return 0/1 or an array of the rest
sub matchesCommand 
{
	my ($bot, $args, $cmd) = @_;

	my @words = split(/\s+/, $args->{'body'});
	$cmd = lc($cmd);
	my $nick = lc($bot->bot()->{'nick'});
	my $prefix = lc($::config{'T_PREFIX'}) || '!';

	if (lc($words[0]) eq $prefix . $cmd)
	{ 
		shift @words;
	}
	elsif ($args->{'address'} and lc($words[0]) eq $cmd)
	{
		shift @words;
	}
	elsif (lc($words[0]) =~ qr/$nick.?/ and lc($words[1]) eq $cmd)
	{
		shift @words;
		shift @words;
	}
	else
	{
		return undef;
	}

	if (wantarray)
	{
		return @words;
	}
	else
	{
		return 1;
	}
}

sub isChanOp
{
	my ($self, $nick, $chan) = @_;

	$chan = lc($chan);
	$nick = lc($nick);
	my $person;
	
	my $channel_data = $self->bot()->{'channel_data'};
	for my $channel_name (keys %$channel_data)
	{
		if ($chan eq lc($channel_name) and defined $channel_data->{$channel_name})
		{
			for my $cnick (keys %{$channel_data->{$channel_name}})
			{
				my $dnick = lc($cnick);
				$dnick =~ s/^[%#!]//;
				if ($nick eq $dnick and defined $channel_data->{$channel_name}->{$cnick})
				{
					$person = $channel_data->{$channel_name}->{$cnick};
					$person->{'hop'} = "%" . $dnick eq lc($cnick) ? 1 : 0;
					$person->{'admin'} = "!" . $dnick eq lc($cnick) ? 1 : 0;
					last;
				}
			}
		}
	}
	return unless ($person);
	return $person->{'op'} || $person->{'hop'} || $person->{'admin'};
}

@EXPORT = qw(matchesCommand isOwner isOp isChanOp configKeyLoader);
1;
