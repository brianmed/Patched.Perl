package Patched::Directory;

use Mojo::Base -strict;

use Carp;
use Moose;
use Mojo::Util;
use IO::String;

use experimental qw(signatures);

has 'path' => (is => 'ro', isa => 'Str');

sub chown ($this, $user = -1, $group = -1) {
    if ("-1" eq $user && "-1" eq $group) {
        croak('Please provide either $user or $group');
    }

    unless ("-1" eq $user) {
        $user = getpwnam($user) if $user !~ m/^\d+$/;
    }

    unless ("-1" eq $group) {
        $group = getgrnam($group) if $group !~ m/^\d+$/;
    }

    chown($user, $group, $this->path);

    return $this;
}

1;
