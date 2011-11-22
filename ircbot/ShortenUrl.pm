package Bot::BasicBot::Pluggable::Module::ShortenUrl;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use WWW::Shorten::TinyURL;

my @seen = ();

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Prints a shortened version of long URLs"; }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	# Stop here on IGNOREUSER
	return if ( $::config{'titler_IGNOREUSER'} and grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'titler_IGNOREUSER'} } );
	return unless (grep {lc($args->{'channel'}) eq lc($_)} @{$::config{'short_CHANS'}});

	my $count = 0;
	my $regex = $::config{'titler_REGEX'};
	for my $url ( $args->{'body'} =~ /$regex/g ) 
	{
		next if ( $self->isRecentUrl( $url ) );
		next if (length($url) < $::config{'short_LENGTH'});
		$count++;

		my $short = makeashorterlink($url);
		my $msg = "ShortenUrl: ";
		$msg .= substr($url, 0, ($::config{'short_LENGTH'} - 3));
		$msg .= "... -> ";
		$msg .= $short;
		$self->reply($args, $msg);

		last if ( $count >= $::config{'titler_URL_LIMIT'} );
	}

	return;
}

# --------- Helper functions

sub isRecentUrl
{
	my ($self, $url) = @_;

	return unless( $::config{'titler_TIMETOLIVE'} );

	@seen = grep { $_->{'when'} + $::config{'titler_TIMETOLIVE'} > time } @seen;
	return 1 if ( grep { $_->{'url'} eq $url } @seen );
	push ( @seen, { when => time, url => $url } );
	return;
}


# --------- Create and start the Bot
my $missing = 0;
for my $key (qw/titler_TIMETOLIVE titler_IGNOREUSER titler_REGEX short_LENGTH titler_URL_LIMIT/)
{
	next if (defined $::config{$key});
	print "Missing expected config value for [$key]\n";
	$missing++;
}

return 0 if ($missing);
1;
