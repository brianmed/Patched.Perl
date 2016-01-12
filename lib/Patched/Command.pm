package Patched::Command;

use Mojo::Base -strict;

use Carp;
use Moose;
use IPC::Run qw();
use Scalar::Util qw(blessed);

use Patched::Log;

use feature qw(signatures);
no warnings "experimental::signatures";

has 'cmd' => (is => 'ro', isa => 'ScalarRef[Str] | ArrayRef[Str] | ArrayRef[Patched::Command] | Str');
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
    my @run = ();

    my $cmd = $this->cmd;

    my ($in, $out, $err);

    if ("ARRAY" eq ref $cmd && blessed $cmd->[0]) {
        my (@left, @right);

        my $left = $cmd->[0];
        my $right = $cmd->[1];

        @left = $this->_cmd($left->cmd, $left->args);
        @right = $this->_cmd($right->cmd, $right->args);

        @run = (\@left, \$in, '|', \@right, \$out, \$err);

        Patched::Log->info(sprintf("IPC::Run::run(%s | %s): STARTING", 
            join(" ", $left->cmd, @{$left->args}), 
            join(" ", $right->cmd, @{$right->args})
        ));
    }
    else {
        my @cmd = $this->_cmd($cmd, $this->args);

        @run = (\@cmd, \$in, \$out, \$err);

        Patched::Log->info(sprintf("IPC::Run::run(%s): STARTING", join(" ", $cmd, @{ $this->args })));
    }

    my $ret = IPC::Run::run(@run, IPC::Run::timeout($this->timeout));
    $this->child_error($?);
    $this->ret($ret);

    $this->stdout(\$out);
    $this->stderr(\$err);

    if ($ret) {
        Patched::Log->info(sprintf("IPC::Run::run: SUCCESS"));
        $this->success(1);
    }
    else {
        Patched::Log->info(sprintf("IPC::Run::run: FAIL: %s: %s", $this->ret, $this->child_error));
        Patched::Log->info(sprintf("-==========\n%s\n==========-\n", ${$this->stderr} // ''));
        $this->success(0);
    }

    if ($this->autodie) {
        croak("$run[0]: $?") unless $ret;
    }

    return $this;
}

sub pipe ($this) {
    $this->run;

    return $this;
}

sub _cmd ($this, $cmd, $args) {
    my @cmd = ();

    if (!ref ${cmd}) {
        @cmd = (${cmd});
    }
    elsif ("ARRAY" eq ref ${cmd}) {
        @cmd = @{ ${cmd} };
    }
    elsif ("SCALAR" eq ref ${cmd}) {
        @cmd = (${ ${cmd} });
    }

    if (!ref ${args}) {
        push(@cmd, ${args});
    }
    elsif ("ARRAY" eq ref ${args}) {
        push(@cmd, @{ ${args} });
    }
    elsif ("SCALAR" eq ref ${args}) {
        push(@cmd, ${ ${args} });
    }

    if ($this->sudo) {
        unshift(@cmd, "sudo", "-u", $this->sudo);
    }

    return @cmd;
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
