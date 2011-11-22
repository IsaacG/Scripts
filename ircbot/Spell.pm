package Bot::BasicBot::Pluggable::Module::Spell;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Lingua::Ispell;

Lingua::Ispell::use_dictionary('/usr/lib/ispell/english');
$Lingua::Ispell::path = '/usr/bin/ispell';

sub help { "Interface to Lingua::Ispell" }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	my @words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'spell');
	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'check') unless (scalar(@words) and $words[0]);
	return unless (@words and $words[0]);
	my $result = check_line(@words);

	$self->tell($args->{'who'}, $result);

	return;
}

sub min
{
	my ($va, $vb) = @_;
	return ($va < $vb) ? $va : $vb;
}

sub check_line {
	my ($inputline) = join(' ', @_);

	my $error_start = '_';
	my $error_end = '_';

	# ISpell has a limit of 99 characters in a word
	if ( $inputline =~ /\w{99}/ ) {
		return "unable to spellcheck";
	}

	# Reads in a list of hashes for each error with the keys term, type, and offset
	my @errs = Lingua::Ispell::spellcheck( $inputline );
	
	if( scalar(@errs) > 0 ) {
		# Reconstruct the line with suggestions built in
		my $outputline;
		my $last_end = 0;
		foreach(@errs) {
			my $off=$_->{'offset'}-1; # ispell counts from 1
			my $before = substr($inputline, $last_end, $off - $last_end);
			
			$last_end = $off + length($_->{'term'});

			# Give speling [spelling, spelunking?] suggestions
			my $extra_info = "";

			if( $_->{'type'} eq 'miss' ) {
				# Show near-misses, there will be 1..n of them
				my @misses = @{$_->{'misses'}};

				my $miss_len = @misses;
				my $shown_guesses = min( $miss_len, $3);

				my @shown = @misses[0..$shown_guesses - 1];

				$extra_info = " (" . join(", ", @shown ) . "?)";
			}
			
 			$outputline .= $before . $error_start . $_->{'term'} . $error_end . $extra_info;
		}
		$outputline .= substr($inputline, $last_end);
	
		return $outputline;
	}
	else {
		return "Looks fine.";
	}
}

sub init
{
	my ($self) = @_;
}

1;
