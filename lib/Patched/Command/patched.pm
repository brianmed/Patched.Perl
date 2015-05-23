package Patched::Command::patched;

use Mojo::Base 'Mojolicious::Commands';

has description => 'Patched configuration management';
has hint        => <<EOF;

See 'APPLICATION patched help COMMAND' for more information on a specific
command.
EOF

has message    => sub { shift->extract_usage . "\nCommands:\n" };
has namespaces => sub { ['Patched::Command::patched'] };

sub help { shift->run(@_) }

1;

=encoding utf8

=head1 NAME

Patched::Command::patched - Patched command

=head1 SYNOPSIS

  Usage: APPLICATION patched COMMAND [OPTIONS]

=head1 DESCRIPTION

L<Patched::Command::patched> lists available L<Patched> commands.

=head1 ATTRIBUTES

L<Patched::Command::patched> inherits all attributes from
L<Mojolicious::Commands> and implements the following new ones.

=head2 description

  my $description = $patched->description;
  $patched        = $patched->description('Foo');

Short description of this command, used for the command list.

=head2 hint

  my $hint = $patched->hint;
  $patched = $patched->hint('Foo');

Short hint shown after listing available L<Patched> commands.

=head2 message

  my $msg = $patched->message;
  $patched = $patched->message('Bar');

Short usage message shown before listing available L<Patched> commands.

=head2 namespaces

  my $namespaces = $patched->namespaces;
  $patched       = $patched->namespaces(['MyApp::Command::patched']);

Namespaces to search for available L<Patched> commands, defaults to
L<Patched::Command::patched>.

=head1 METHODS

L<Patched::Command::patched> inherits all methods from L<Mojolicious::Commands>
and implements the following new ones.

=head2 help

  $patched->help('app');

Print usage information for L<Patched> command.

=cut
