package Bot::BasicBot::Pluggable::Module::Dice;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Roll XdY dice" }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	my $who = $args->{'who'};

	my @words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'roll');
	if (scalar(@words) and $words[0])
	{
		my @parts;
		for my $word (@words) 
		{
			$word = lc($word);
			if ($word =~ /^(\d+)d(\d+)/)
			{
				my ($num, $type) = ($1, $2);
				my @rolls;
				my $tmp;
				push @rolls, (int(rand($type)) + 1) for (1..$num);
				$tmp += $_ for (@rolls);
				push @parts, [ $tmp, sprintf("%d on a %dd%d: <%s>", $tmp, $num, $type, join(", ", @rolls)) ];
				#$self->tell("Bobby", sprintf("%d on a %dd%d: %s", $tmp, $num, $type, join(", ", @rolls)));
			}
			elsif ($word =~ /^d(\d+)/)
			{
				my $type = $1;
				my $roll = int(rand($type)) + 1;
				push @parts, [ $roll, sprintf("%d on a %dd%d", $roll, 1, $type) ];
				#$self->tell("Bobby", sprintf("%d on a %dd%d", $roll, 1, $type));
			}
			elsif (grep {$word eq $_} qw/dex str wis int con cha/)
			{
				unless (defined $self->bot()->{'dicestats'}->{$who} and defined $self->bot()->{'dicestats'}->{$who}->{$word})
				{
					$self->reply($args, sprintf("%s is not set for %s", $word, $who));
					return;
				}
				push @parts, [$self->bot()->{'dicestats'}->{$who}->{$word}, uc($word) . " bonus" ];
				#$self->tell("Bobby", uc($word) . " bonus");
			}
			elsif ($word =~ /^\d+$/)
			{
				push @parts, [$word, $word];
				#$self->tell("Bobby", "+" . $word);
			}
			else
			{
				$self->reply($args, "Usage: !roll XdY DEX|STR|WIS|INT|CHA|CON");
				return;
			}
		}
		my $sum = 0;
		my @desc;
		for my $part (@parts)
		{
			$sum += $part->[0];
			push @desc, $part->[1] . " (" . $part->[0] . ")";
		}
		$self->reply($args, sprintf("%s rolled %d: %s", $who, $sum, join(" + ", @desc)));
		return;
	}
	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'set');
	if (scalar(@words) == 2 and $words[0])
	{
		my $stat = lc($words[0]);
		unless (grep {$stat eq $_} qw/dex str wis int con cha/ and $words[1] =~ /^\d+$/) 
		{
			$self->reply($args, "Usage: !set DEX|STR|WIS|INT|CHA|CON num");
			return;
		}
		$self->bot()->{'dicestats'}->{$who} = {} unless (defined $self->bot()->{'dicestats'}->{$who});
		$self->bot()->{'dicestats'}->{$who}->{$stat} = $words[1];
		$self->reply($args, sprintf("%s has set their %s to %d", $who, $words[0], $words[1]));
		open my $FH, '>>', "/home/goodi/dnd.dice.stats" or die;
		print $FH join("\t", time, $who, $stat, $words[1]) . "\n";
		close $FH;
		return;
	}
}

sub init
{
	my ($self) = @_;
	$self->bot()->{'dicestats'} = {};
}

1;
