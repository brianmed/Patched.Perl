package Patched::Command;

use Mojo::Base -strict;

use experimental qw(signatures);

use Moose;
use IPC::Run qw();

use Patched::Log;

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
    my @cmd = ();

    if (!ref $this->{cmd}) {
        @cmd = ($this->{cmd});
    }
    elsif ("ARRAY" eq ref $this->{cmd}) {
        @cmd = @{ $this->{cmd} };
    }
    elsif ("SCALAR" eq ref $this->{cmd}) {
        @cmd = (${ $this->{cmd} });
    }

    if (!ref $this->{args}) {
        push(@cmd, $this->{args});
    }
    elsif ("ARRAY" eq ref $this->{args}) {
        push(@cmd, @{ $this->{args} });
    }
    elsif ("SCALAR" eq ref $this->{args}) {
        push(@cmd, ${ $this->{args} });
    }

    Patched::Log->info(sprintf("IPC::Run::run(%s): STARTING", join(" ", @cmd)));

    my ($in, $out, $err);
    my $ret = IPC::Run::run(\@cmd, \$in, \$out, \$err);
    $this->child_error($?);
    $this->ret($ret);

    $this->stdout([split(/\n/, $out)]);
    $this->stderr([split(/\n/, $err)]);

    if ($this->autodie) {
        croak("$cmd[0]: $?") unless $ret;
    }

    if ($ret) {
        Patched::Log->info(sprintf("IPC::Run::run(%s): SUCCESS", join(" ", @cmd)));
        $this->success(1);
    }
    else {
        Patched::Log->info(sprintf("IPC::Run::run(%s): FAIL: %s", join(" ", @cmd), $this->child_error));
        $this->success(0);
    }

    return $this;
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
