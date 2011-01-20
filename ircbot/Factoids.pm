package Bot::BasicBot::Pluggable::Module::Factoids;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Factoid lookup" }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	# Stop here on IGNOREUSER
	#return if ( $::config{'titler_IGNOREUSER'} and grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'titler_IGNOREUSER'} } );


	my @words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'smilie');
	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'get') unless(scalar(@words) > 1 and $words[0]);
	if (scalar(@words) > 0 and $words[0])
	{
		if (scalar(@words) == 1 and $self->bot()->{'factoids'}->{$words[0]})
		{
			$self->reply($args, sprintf "%s -> %s", $words[0], $self->bot()->{'factoids'}->{$words[0]});
		}
		else
		{
			$self->reply($args, $words[0] . " not defined");
		}
		return;
	}

	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'define');
	if (scalar(@words) > 0 and $words[0])
	{
		my ($word, $def);
		$word = shift(@words);
		$def  = join(' ', @words);
		if ($word and not $def)
		{
			$self->reply($args, "To add a smilie do: ?define $word [definition]");
			return;
		}
		$self->bot()->{'factoids'}->{$word} = $def;
		open my $fh, ">>", $::config{'factoid_FILE'} or die;
		printf $fh "%s\t%s\t%s\t%s\n", time, $args->{'who'}, $word, $def;
		close $fh;
		return;
	}

	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'factoidload'))
	{
		$self->bot()->{'factoids'} = {};
		loadFactoids($self->bot()->{'factoids'});
		return;
	}

	return;
}

sub loadFactoids
{
	my ($hash) = (@_);
	my $file = $::config{'factoid_FILE'};
	return unless (-f $file);
	open my $fh, "<", $file;
	return unless $fh;
	while (my $line = <$fh>)
	{
		my ($time, $nick, $word, $def) = split(/\t/, $line, 4);
		next unless ($word and $def);
		$hash->{$word} = $def;
	}
}

sub init
{
	my ($self) = @_;
	$self->Bot::BasicBot::Pluggable::Module::Utils::configKeyLoader(factoid_FILE => "./factoids.txt");
	$self->bot()->{'factoids'} = {};
	loadFactoids($self->bot()->{'factoids'});
}

1;
