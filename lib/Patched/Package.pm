package Patched::Package;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;

use Patched::Command;

use experimental qw(signatures);

sub installed ($this, $pkg) {
    my $rpm = Patched::Command->find("rpm") or croak("Unable to find rpm command");

    return Patched::Command->new(cmd => $rpm, args => ["-q", "--quiet", $pkg], autodie => 0)->run->success;
}

sub install ($this, $pkg) {
    my $yum = Patched::Command->find("yum") or croak("Unable to find yum command");

    my $cmd = Patched::Command->new(cmd => $yum, args => ["install", "-y", $pkg], autodie => 0)->run;

    croak("Unable to install $pkg") unless $cmd->success;

    return $this;
}

sub erase ($this, $pkg) {
    my $yum = Patched::Command->find("yum") or croak("Unable to find yum command");

    my $cmd = Patched::Command->new(cmd => $yum, args => ["erase", "-y", $pkg], autodie => 0)->run;

    croak("Unable to erase $pkg") unless $cmd->success;

    return $this;
}

1;
