package Patched::Command;

use Mojo::Base -strict;

use experimental qw(signatures);

use Moose;
use IPC::Run;

has 'cmd' => (is => 'ro', isa => 'ScalarRef[Str] | ArrayRef[Str] | Str');
has 'stdin' => (is => 'ro', isa => 'ArrayRef[Str]');
has 'stdout' => (is => 'rw', isa => 'ArrayRef[Str]');
has 'stderr' => (is => 'rw', isa => 'ArrayRef[Str]');

sub run ($this) {
    say($this->{cmd});
}

sub path_srch ($this, $exe) {
    my @PATH = split(/:/, $ENV{PATH});

    die("No exe given\n") if !$exe;

    foreach my $dir (@PATH) {
        if (-e "$dir/$exe") {
            return "$dir/$exe";
        }
    }

    return undef;
}

1;
