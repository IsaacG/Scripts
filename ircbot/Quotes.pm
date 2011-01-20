package Bot::BasicBot::Pluggable::Module::Quotes;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Save quotes for a nick recall random quotes for that person" }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	# Stop here on IGNOREUSER
	return if ( $::config{'titler_IGNOREUSER'} and grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'titler_IGNOREUSER'} } );


	my @words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'quoteadd');
	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'addquote') unless(scalar(@words) > 1 and $words[0]);
	if (scalar(@words) > 1 and $words[0])
	{
		my $for = lc(shift(@words));
		open my $FH, ">>", $::config{'quote_FILE'} or die;
		print $FH join("\t", lc($args->{'who'}), $for, join(" ", @words)) . "\n";
		close $FH;

		$self->tell($args->{'who'}, "Quote added for $for");
	}


	my ($for, $showQuote, $number);
	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'quotecount');
	if (scalar(@words) > 0 and $words[0])
	{
		return unless (grep {lc($args->{'channel'}) eq lc($_)} @{$::config{'quote_CHANS'}});
		$for = lc(shift(@words));
		$showQuote = 2;
	}

	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'quote');
	if (scalar(@words) > 0 and $words[0])
	{
		return unless (grep {lc($args->{'channel'}) eq lc($_)} @{$::config{'quote_CHANS'}});
		$for = lc(shift(@words));
		$showQuote = 1;
		$number = shift(@words);
		$number = undef unless(length($number));
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'quote'))
	{
		return unless (grep {lc($args->{'channel'}) eq lc($_)} @{$::config{'quote_CHANS'}});
		$for = undef;
		$showQuote = 1;
	}

	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'quotedump');
	if (scalar(@words) > 0 and $words[0])
	{
		$for = lc(shift(@words));
		$showQuote = 3;
	}

	if($showQuote)
	{
		my @options;
		open my $FH, "<", $::config{'quote_FILE'} or die;
		while(my $line = <$FH>)
		{
			chomp $line;
			my ($by, $sfor, $sline) = split("\t", $line, 3);
			push(@options, sprintf("%s\t%s", $sfor, $sline)) if (not defined ($for) or $for eq $sfor);
		}
		close $FH;

		my $reply;
		if (@options)
		{
			if ($showQuote == 1)
			{
				if (defined $number)
				{
					$reply = $options[$number];
				} else {
					$reply = $options[int(rand(scalar(@options)))];
				}
				$reply =~ s/\t/: / if ($reply);
			} elsif ($showQuote == 2) # Quote count
			{
				$reply = sprintf("%s has %d quotes on file.", $for, scalar(@options)); 
			} elsif ($showQuote == 3) # Dump quotes to PM
			{
				$reply = undef;
				$self->tell($args->{'who'}, "All quotes for $for");
				my $i = 0;
				for my $quote (@options)
				{
					$self->tell($args->{'who'}, sprintf("%d: %s", $i++, $quote));
				}
			}
		}
		else
		{
			$reply = "No quotes on file for that person.";
		}

		$self->tell($args->{'channel'}, $reply) if ($reply);
	}


	return;
}

sub init
{
	my ($self) = @_;
	$self->Bot::BasicBot::Pluggable::Module::Utils::configKeyLoader(quote_FILE => "./quotes.txt");
}

1;
