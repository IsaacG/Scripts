package Bot::BasicBot::Pluggable::Module::WeatherCom;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Weather::Com::Finder;

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Interface to Weather::Com." }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless( $args->{'body'} );
	return unless ($pri == 2);

	# Stop here on IGNOREUSER
	return if ( $::config{'titler_IGNOREUSER'} and grep { lc($_) eq lc($args->{'who'}) } @{ $::config{'titler_IGNOREUSER'} } );

	return unless ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'wz'));
	unless (grep {lc($args->{'channel'}) eq lc($_)} @{$::config{'weatherCom_CHAN'}})
	{
		$self->tell('yitz', 'wz request dropped from chan ' . lc($args->{'channel'}) . ' not in ' . join(" ", @{$::config{'weatherCom_CHAN'}}));
		return;
	}

	my @words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'wz');
	@words = $self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'wz') unless(scalar(@words) and $words[0]);

	my $location;
	if (scalar(@words) and $words[0])
	{
		$location = join(" ", @words);
		$self->{'last'}->{$args->{'who'}} = $location;
	}
	elsif(defined $self->{'last'}->{$args->{'who'}})
	{
		$location = $self->{'last'}->{$args->{'who'}};
	}
	else
	{
		$self->reply($args, "You need to specify a location.");
		return;
	}


	my @replies = $self->wzLookup($location);
	if (scalar(@replies) == 2)
	{
		$self->reply($args, $_) for @replies;
	} 
	elsif (scalar(@replies) > 2)
	{
		$self->reply($args, "Found multiple locations that match $location");
	}
	else
	{
		$self->reply($args, "Found zero locations that match $location");
	}

	return;
}

sub wzLookup
{
	my ($self, $location) = @_;
	return unless $location;
	print "Doing weather lookup on $location\n";
	my @locations = $self->{'wz'}->find($location);

	my @output = ();
	if (scalar(@locations) == 1)
	{
		for $location (@locations) {
			return unless (defined $location);
			push(
				@output, 
				sprintf(
					" %s -- %s GMT %s | Updated %s on %s", 
					$location->name(), 
					$location->localtime()->time_ampm(), 
					$location->timezone(), 
					$location->current_conditions()->last_updated()->time_ampm(),
					$location->current_conditions()->last_updated()->date()
				)
			);
			if ($location->current_conditions()->temperature() != $location->current_conditions()->windchill())
			{
				push(
					@output, 
					sprintf(
						" Conditions: %dC/%.1fF | WC: %dC/%.1fF | %s | Humidity: %d%%", 
						$location->current_conditions()->temperature(),
						($location->current_conditions()->temperature() * 1.8 + 32),
						$location->current_conditions()->windchill(),
						($location->current_conditions()->windchill() * 1.8 + 32),
						$location->current_conditions()->description(),
						$location->current_conditions()->humidity()
					)
				);
			}
			else
			{
				push(
					@output, 
					sprintf(
						" Conditions: %dC/%.1fF | %s | Humidity: %d%%", 
						$location->current_conditions()->temperature(),
						($location->current_conditions()->temperature() * 1.8 + 32),
						$location->current_conditions()->description(),
						$location->current_conditions()->humidity()
					)
				);
			}
		}
	}
	elsif (scalar(@locations) > 1)
	{
		push(@output, "Places that match $location:");
		my @tmp;
		for $location (@locations)
		{
			#push(@tmp, sprintf("%s: %+dGMT [%s]", $location->name(), $location->timezone(), $location->id()));
			push(@tmp, sprintf("%s: %+dGMT", $location->name(), $location->timezone()));
		}
		push(@output, join(" | ", @tmp));
	}

	return @output;
}

sub init
{
	my ($self) = @_;

	my $weather_finder = Weather::Com::Finder->new(
		partner_id => $::config{'weatherCom_ID'},
		license    => $::config{'weatherCom_KEY'},
		language   => 'en',
	);

	$self->{'wz'} = $weather_finder;
	$self->{'last'} = {};
}

1;
