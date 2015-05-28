package Patched::User;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;

use Patched::Environment;
use Patched::Command;
use Patched::Log;

use experimental qw(signatures);

has 'uname' => (is => 'rw', isa => 'Str');

sub exists ($this) {
    return getpwnam($this->uname);
}

# SALT=$(openssl rand -base64 16 | tr -d '+=' | head -c 16)
# perl -e 'print crypt("password","\$6\$$ARGV[0]\$") . "\n"' $SALT
sub add ($this, $opts) {
    my $adduser = Patched::Command->find("adduser");

    if (!$adduser) {
        croak("Unable to find adduser command");
    }

    my %option_map = (
        uid => "--uid",
        home => "--home",
        comment => "--comment",
        expire => "--expiredate",
        group => "--gid",
        groups => "--groups",
        password => "--password",
        system => "--system",
    );

    my $args = [];

    foreach my $key (sort keys %{ $opts }) {
        if ($option_map{$key}) {
            if ("system" eq $key) {
                push(@{ $args }, $option_map{$key});
            }
            else {
                push(@{ $args }, $option_map{$key}, $opts->{$key});
            }
        }
    }

    if ($opts->{xtra_args}) {
        push(@{ $args }, @{ $opts->{xtra_args} });
    }

    push(@{ $args }, $this->uname);

    Patched::Log->info("Adding user: " . $this->uname);

    return Patched::Command->new(cmd => $adduser, args => $args)->run->success;
}

sub del ($this, $opts) {
    my $userdel = Patched::Command->find("userdel");

    if (!$userdel) {
        croak("Unable to find userdel command");
    }

    my %option_map = (
        remove => "--remove",
    );

    my $args = [];

    foreach my $key (sort keys %{ $opts }) {
        if ($option_map{$key}) {
            push(@{ $args }, $option_map{$key});
        }
    }

    if ($opts->{xtra_args}) {
        push(@{ $args }, @{ $opts->{xtra_args} });
    }

    push(@{ $args }, $this->uname);

    Patched::Log->info("Deleting user: " . $this->uname);

    return Patched::Command->new(cmd => $userdel, args => $args)->run->success;
}

sub uid ($this, $name) {
    if (!defined $name) {
        croak("Please pass in a name.\n");
    }

    return scalar getpwnam($name);
}

sub name ($this, $uid) {
    if (!defined $uid) {
        croak("Please pass in a uid.\n");
    }

    return scalar getpwuid($uid);
}

sub home ($this, $name) {
    if (!defined $name) {
        croak("Please pass in a name.\n");
    }

    return (getpwnam($name))[7];
}

1;
