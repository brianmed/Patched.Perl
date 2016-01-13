package Patched::Directory;

use Mojo::Base -strict;

use Carp;
use Moose;
use Mojo::Util;
use IO::String;

use experimental qw(signatures);

has 'path' => (is => 'ro', isa => 'Str');

sub chown ($this, $user = -1, $group = -1) {
    if (-1 == $user && -1 == $group) {
        croak('Please provide either $user or $group');
    }

    unless (-1 == $user) {
        $user = getpwnam($user) if $user =~ m/^\d+$/;
    }

    unless (-1 == $group) {
        $group = getgrnam($group) if $group =~ m/^\d+$/;
    }

    chown($user, $group, $this->path);

    return $this;
}

1;
