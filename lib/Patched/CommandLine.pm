package Patched::CommandLine;

use Mojo::Base 'Mojolicious';

use File::Basename qw(basename dirname);
use File::Spec::Functions 'catdir';
use Mojo::Util 'monkey_patch';

sub import {
  # Remember executable for later
  $ENV{MOJO_EXE} ||= (caller)[1];

  # Reuse home directory if possible
  local $ENV{MOJO_HOME} = catdir split('/', dirname $ENV{MOJO_EXE})
    unless $ENV{MOJO_HOME};

  # Initialize application class
  my $caller = caller;
  no strict 'refs';
  push @{"${caller}::ISA"}, 'Mojo';

  # Generate moniker based on filename
  my $moniker = basename $ENV{MOJO_EXE};
  $moniker =~ s/\.(?:pl|pm|t)$//i;
  my $app = shift->new(moniker => $moniker);

  monkey_patch $caller, $_, sub {$app} for qw(new app);

  monkey_patch $caller, plugin => sub { $app->plugin(@_) };

  monkey_patch $caller, plugin => sub { $app->plugin(@_) };

  require Mojolicious::Commands;

  Mojolicious::Commands::has(message => sub { "Usage:\n\n" });

  @{ $app->commands->namespaces } = ('Patched::Command');

  # Lite apps are strict!
  Mojo::Base->import(-strict);
}

1;
