package Patched::Environment;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;
use POSIX qw();

use experimental qw(signatures);

sub uname ($this, $name) {
    return POSIX::uname;
}

sub os ($this) {
    return $^O;
}

sub distribution ($this) {
    if ("linux" eq $this->os) {
        my $centos_release = "/etc/centos-release";

        if (-f $centos_release) {
            my $matched = Patched::File->new(path => $centos_release)->match("CentOS release");

            if ($matched) {
                if ($matched =~ m/CentOS release ([\d.]+)/) {
                    return("CentOS");
                }
            }
        }
    }

    croak("Unsupported");
}

sub version ($this) {
    if ("linux" eq $this->os) {
        my $centos_release = "/etc/centos-release";

        if (-f $centos_release) {
            my $matched = Patched::File->new(path => $centos_release)->match("CentOS release");

            if ($matched) {
                if ($matched =~ m/CentOS release ([\d.]+)/) {
                    my $ver = $1;

                    croak("Unsupported") unless $ver =~ m/^6/;
                    return($ver);
                }
            }
        }
    }

    croak("Unsupported");
}

1;
