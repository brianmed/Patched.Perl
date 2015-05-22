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

