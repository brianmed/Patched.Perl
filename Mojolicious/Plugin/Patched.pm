package Mojolicious::Plugin::Patched;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app, $conf) = @_;

  push @{$app->commands->namespaces}, 'Patched::Command';
}

1;
