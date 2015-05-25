package Patched::Command;

use Mojo::Base -strict;

use experimental qw(signatures);

use Moose;
use IPC::Run qw();

has 'cmd' => (is => 'ro', isa => 'ScalarRef[Str] | ArrayRef[Str] | Str');
has 'args' => (is => 'ro', isa => 'ScalarRef[Str] | ArrayRef[Str] | Str');
has 'ret' => (is => 'rw', isa => 'Int');
has 'child_error' => (is => 'rw', isa => 'Str');
has 'stdin' => (is => 'ro', isa => 'ArrayRef[Str]');
has 'stdout' => (is => 'rw', isa => 'ArrayRef[Str]');
has 'stderr' => (is => 'rw', isa => 'ArrayRef[Str]');
has 'autodie' => (is => 'rw', isa => 'Bool', default => 1);
has 'success' => (is => 'rw', isa => 'Bool');

sub run ($this) {
    if (!ref $this->{cmd}) {
        my @cmd = ($this->{cmd});

        if (!ref $this->{args}) {
            push(@cmd, $this->{args});
        }

        my ($in, $out, $err);
        my $ret = IPC::Run::run(\@cmd, \$in, \$out, \$err);
        $this->child_error($?);
        $this->ret($ret);

        if ($this->autodie) {
            croak("$cmd[0]: $?") unless $ret;
        }

        if ($ret) {
            $this->success(1);
        }
        else {
            $this->success(0);
        }

        return $this;
    }
}

sub find ($this, $exe) {
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
