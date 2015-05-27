package Patched::Packages;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;

use Patched::Command;

use experimental qw(signatures);

sub have_updates ($this) {
    my $yum = Patched::Command->find("yum") or croak("Unable to find yum command");

    my $cmd = Patched::Command->new(cmd => $yum, args => ["check-update"], autodie => 0)->run;
    
    my $child_error = $cmd->child_error >> 8;
    if (100 == $child_error) {
        return 1;
    }
    else {
        return 0;
    }
}

sub update ($this) {
    my $yum = Patched::Command->find("yum") or croak("Unable to find yum command");

    my $cmd = Patched::Command->new(cmd => $yum, args => ["-y", "update"], autodie => 1)->run;

    return 1;
}
