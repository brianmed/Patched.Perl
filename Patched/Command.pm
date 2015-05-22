package Patched::Command;

use Moose;
use IPC::Run;

has 'cmd' => (is => 'ro', isa => 'Ref');
has 'stdin' => (is => 'ro', isa => 'ArrayRef[Str]');
has 'stdout' => (is => 'ro', isa => 'ArrayRef[Str]');
has 'stderr' => (is => 'ro', isa => 'ArrayRef[Str]');

sub run {
}

1;
