package Patched::Command;

use Mojo::Base -strict;

use Moose;
use IPC::Run;

has 'cmd' => (is => 'ro', isa => 'Ref');
has 'stdin' => (is => 'ro', isa => 'ArrayRef[Str]');
has 'stdout' => (is => 'ro', isa => 'ArrayRef[Str]');
has 'stderr' => (is => 'ro', isa => 'ArrayRef[Str]');

sub run ($this) {
    say($this->{cmd});
}

1;
