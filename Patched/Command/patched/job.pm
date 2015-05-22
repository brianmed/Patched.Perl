package Patched::Command::patched::job;

use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Date;
use Mojo::JSON 'decode_json';
use Mojo::Util qw(dumper tablify);

has description => 'Manage Patched jobs';
has usage => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

}

1;
