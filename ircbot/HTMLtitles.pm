package Bot::BasicBot::Pluggable::Module::HTMLtitles;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use LWP::UserAgent;
use HTTP::Headers;
use Image::Size;

our $VERSION = "0.3.1.5";


# --------- Bot::BasicBot callback methods we overwrite
sub help { "Prints the title of a URL"; }

sub emoted { said(@_) }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );

	return unless ($pri == 2);

	# Stop here on IGNOREUSER
	return if ( $::config{'titler_IGNOREUSER'} and grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'titler_IGNOREUSER'} } );
	return unless (grep {lc($args->{'channel'}) eq lc($_)} @{$::config{'titler_CHANS'}});

	my $count = 0;
	my $regex = $::config{'titler_REGEX'};
	for my $url ( $args->{'body'} =~ /$regex/g ) 
	{
		next if ( $self->isRecentUrl( $url ) );
		$count++;
		my $response = $self->getUrl($url);

		my $message;
		if ( $response->code() != 200 ) 
		{
			$message = "Failed to fetch document: " . $response->status_line();
		}
		elsif ( $response->header('content-type') =~ qr{^image/} )
		{
			my $content = $response->content;
			my ($x, $y, $type) = Image::Size::imgsize(\$content);
			if ($x and $y)
			{
				$message = "Image file (${x}x${y} - $type). Content Type: " . $response->header('content-type');
			}
			else
			{
				$message = "Unable to get sizing. Content Type: " . $response->header('content-type');
			}
		}
		elsif ( $response->header('content-type') !~ qr{^text/html} )
		{
			next if ($response->header('content-type') eq 'image/jpeg' and $url =~ /\.jpg$/);
			$message = "Not an HTML document. Content Type: " . $response->header('content-type');
		}	
		elsif ( not defined $response->title() ) {
			$message = "No title found.";
		}
		else
		{
			$message = "Title: " . $response->title();
		}

		$message = "$message (at " . $response->request->uri()->host() . ")";
		$self->reply($args, deNaughty($message));

		last if ( $count >= $::config{'titler_URL_LIMIT'} );
	}

	return;
}

# --------- Helper functions

sub isRecentUrl
{
	my ($self, $url) = @_;

	return unless( $::config{'titler_TIMETOLIVE'} );

	my @seen = grep { $_->{'when'} + $::config{'titler_TIMETOLIVE'} > time } @{$self->{'seen'}};
	return 1 if ( grep { $_->{'url'} eq $url } @seen );
	push ( @seen, { when => time, url => $url } );
	$self->{'seen'} = \@seen;
	return;
}

sub getUrl
{
	my ($self, $url) = @_;
	# Prepend http:// if needed
	$url = "http://$url" unless ( $url =~ qr(^http://) );
	my $response = $self->{'ua'}->get($url);
	return $response;
}

sub deNaughty
{
	my ($msg) = @_;
	return $msg unless ($::config{'titler_BADWORDS'} and $::config{'titler_CENSOR'});
	my $replace = $::config{'titler_CENSOR'};
	open my $FH, "<", $::config{'titler_BADWORDS'} || return $msg;
	while (my $line = <$FH>)
	{
		chomp $line;
		# Expand the mIRC '*' to the perl '.*'
		$line =~ s/[*]/.*/g;
		$msg =~ s/$line/$replace/ig;
	}
	close $FH;
	return $msg;
}


# --------- Create and start the Bot
sub init
{
	my ($self) = @_;
	$self->{'ua'} = LWP::UserAgent->new(
		agent    => $::config{'titler_USERAGENT' } || die 'UA',
		timeout  => $::config{'titler_UATIMEOUT' } || die 'UTO',
		max_size => $::config{'titler_MAXGETSIZE'} || die 'MGZ',
	);
	$self->{'ua'}->max_size($::config{'titler_MAXGETSIZE'} || die 'MGZ');
	$self->{'ua'}->timeout($::config{'titler_UATIMEOUT'} || die 'UTO');
	$self->{'ua'}->agent($::config{'titler_USERAGENT'} || die 'UA');

	$self->{'seen'} = [];
}

1;
