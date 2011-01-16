package Bot::BasicBot::Pluggable::Module::Translate;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Lingua::Translate;

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Interface to Lingua::Translate" }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	my @words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'translate');
	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'tr') unless (scalar(@words) and $words[0]);
	return unless (scalar(@words) and $words[0] and $words[1]);

	my $lang = shift (@words);
	my ($from, $to);
	if ($lang =~ /:/) 
	{
		($from,$to) = split(':', $lang);
	}
	else
	{
		($from,$to) = ($lang,'en');
	}

	my $term = join(" ", @words);

	my $xl8r = Lingua::Translate->new(src => $from, dest => $to);
	my $result = $xl8r->translate($term);

	#open my $FH, ">> /home/goodi/debug.log";
	#print $FH "$from to $to : $term = $result\n";

	if ($result)
	{ 
		$self->reply($args, $result);
	}
	return;
}

sub init
{
	my ($self) = @_;
}

1;
