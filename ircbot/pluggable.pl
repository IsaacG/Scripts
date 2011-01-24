#!/usr/bin/perl

use Bot::BasicBot::Pluggable;
use lib '/home/goodi/play/codes/keep/bot';
use Bot::BasicBot::Pluggable::Module;

use warnings;
use strict;
use Data::Dumper;
use POSIX;

my %about = (
	Author     => 'Isaac Good',
	License    => 'MIT/X11',
	Version    => 'PluggerBot - 2009-06-23 - Beta 0.3.1.5',
);

our %config;
my $CONFIG_FILE = $ARGV[0] || 'config.pl';

# --------- Helper functions

sub loadConfig 
{
	my ($self, $args) = @_;
	return if ( defined $args and exists $args->{'who'} and $args->{'who'} ne $config{'OWNER'} );
	open my $FH, "<", $CONFIG_FILE;
	my $file = join(" ", <$FH>); 
	%config = eval ( $file );
	$config{'T_PREFIX'} |= '!';
}

# --------- Create and start the Bot
loadConfig();

my $bot = Bot::BasicBot::Pluggable->new(
	server    => $config{'SERVER'}  || die,
	channels  => $config{'CHAN'}    || die,
	nick      => $config{'NICK'}    || die,
	alt_nicks => $config{'ANICK'}   || undef,
	username  => $config{'NAME'}    || die,
	name      => $config{'RNAME'}   || $config{'NICK'} . " bot",
	port      => $config{'PORT'}    || die,
);

$bot->{'start_time'} = time;
for my $m (@{$config{'LOAD_PLUGINS'}})
{
	print "Loading $m...\n";
	$bot->load($m);
}

#$bot->load("GoogleNAPI");
#$bot->load("RSS");

POSIX::nice(20);

$bot->run();

