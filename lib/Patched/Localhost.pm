package Patched::Localhost;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;

use Patched::Command;

use experimental qw(signatures);

sub reboot ($this) {
    my $init = Patched::Command->find("init") or croak("Unable to find init command");
    Patched::Command->new(cmd => $init, args => ["6"], autodie => 0)->run;
}

1;
