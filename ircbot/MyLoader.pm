package Bot::BasicBot::Pluggable::Module::MyLoader;

use warnings;
use strict;

use Bot::BasicBot::Pluggable::Module; 
use Bot::BasicBot::Pluggable::Module::Utils; 
use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = "0.4.0.0";

# --------- Bot::BasicBot callback methods we overwrite
sub help { "Let OWNER load/unload modules on the fly"; }

sub said 
{
	my ($self, $args, $pri) = @_;
	return unless ($pri == 2 and $args->{'body'} );
	return unless (lc($args->{'who'}) eq lc($::config{'OWNER'}));

	my ($cmd, $what) = split(/\s+/, $args->{'body'}, 2);
	return unless ($what);
	if ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'load'))
	{
		#eval { $self->bot->load($what) } or return "Failed to load the module.";
		eval { $self->bot->load($what) } or return $@;
		return "Loaded.";
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'unload'))
	{
		eval { $self->bot->unload($what) } or return "Failed to unload the module.";
		return "Unloaded.";
	}
	elsif ($self->Bot::BasicBot::Pluggable::Module::Utils::matchesCommand($args, 'reload'))
	{
		eval { $self->bot->unload($what) } or return "Failed to unload the module.";
		eval { $self->bot->load($what) } or return "Failed to load the module.";
		return "Reloaded.";
	}
	

	return;
}

my $missing = 0;
for my $key (qw/OWNER/)
{
	next if (defined $::config{$key});
	print "Missing expected config value for [$key]\n";
	$missing++;
}

return 0 if ($missing);
1;
