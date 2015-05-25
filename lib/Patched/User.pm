package Patched::User;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;

use Patched::Environment;
use Patched::Command;

use experimental qw(signatures);

sub exists ($this, $name) {
    if (!defined $name) {
        croak("Please pass in a name.\n");
    }

    return getpwnam($name);
}

sub add ($this, $name) {
    unless ("CentOS" eq $main::Distro) {
        croak("Unsupported");
    }

    unless ($main::Version =~ m/^6/) {
        croak("Unsupported");
    }

    my $adduser = Patched::Command->find("adduser");

    if (!$adduser) {
        croak("Unable to find adduser command");
    }

    return Patched::Command->new(cmd => $adduser, args => "bpm")->run->success;
}
