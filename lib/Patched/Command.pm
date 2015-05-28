package Patched::Command;

use Mojo::Base -strict;

use experimental qw(signatures);

use Carp;
use Moose;
use IPC::Run qw();

use Patched::Log;

has 'cmd' => (is => 'ro', isa => 'ScalarRef[Str] | ArrayRef[Str] | Str');
has 'args' => (is => 'ro', isa => 'ScalarRef[Str] | ArrayRef[Str] | Str');
has 'timeout' => (is => 'rw', isa => 'Int', default => 3600);
has 'ret' => (is => 'rw');
has 'child_error' => (is => 'rw', isa => 'Str');
has 'stdin' => (is => 'ro');
has 'stdout' => (is => 'rw', isa => 'ScalarRef[Str]');
has 'stderr' => (is => 'rw', isa => 'ScalarRef[Str]');
has 'autodie' => (is => 'rw', isa => 'Bool', default => 1);
has 'success' => (is => 'rw', isa => 'Bool');
has 'sudo' => (is => 'rw', isa => 'Str');

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

    if ($this->sudo) {
        unshift(@cmd, "sudo", "-u", $this->sudo);
    }

    Patched::Log->info(sprintf("IPC::Run::run(%s): STARTING", join(" ", @cmd)));

    my ($in, $out, $err);
    my $ret = IPC::Run::run(\@cmd, \$in, \$out, \$err, IPC::Run::timeout($this->timeout));
    $this->child_error($?);
    $this->ret($ret);

    $this->stdout(\$out);
    $this->stderr(\$err);

    if ($ret) {
        Patched::Log->info(sprintf("IPC::Run::run(%s): SUCCESS", join(" ", @cmd)));
        $this->success(1);
    }
    else {
        Patched::Log->info(sprintf("IPC::Run::run(%s): FAIL: %s", join(" ", @cmd), $this->child_error));
        $this->success(0);
    }

    if ($this->autodie) {
        croak("$cmd[0]: $?") unless $ret;
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

    croak("Unable to find $exe");
}

1;
