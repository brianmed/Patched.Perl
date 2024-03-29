package Patched::Cron;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;

use Patched::Command;

use experimental qw(signatures);

has 'user' => (is => 'ro', isa => 'Str');

sub exists ($this, $entry) {
    if (!defined $this->user) {
        croak("Please pass in a user.\n");
    }

    if (!defined $entry) {
        croak("Please pass in an entry.\n");
    }

    my $crontab = Patched::Command->find("crontab") or croak("Unable to find crontab command");
    my $cmd = Patched::Command->new(cmd => $crontab, args => ["-u", $this->user, "-l"], autodie => 0)->run;

    unless ($cmd->success || 256 == int($cmd->child_error)) {
        croak("Unable to get crontab listing");
    }

    if (Patched::File->new(str => ${ $cmd->stdout })->find($entry)) {
        return 1;
    }
    else {
        return 0;
    }
}

sub add ($this, $entry) {
    if (!defined $this->user) {
        croak("Please pass in a user.\n");
    }

    if (!defined $entry) {
        croak("Please pass in an entry.\n");
    }

    if ($this->exists($entry)) {
        croak("crontab entry '$entry' already found");
    }

    my $crontab = Patched::Command->find("crontab") or croak("Unable to find crontab command");
    my $cmd = Patched::Command->new(cmd => $crontab, args => ["-u", $this->user, "-l"], autodie => 0)->run;
    
    unless ($cmd->success || 256 == int($cmd->child_error)) {
        croak("Unable to get crontab listing");
    }

    my $crontab_file = Patched::File->tmp({contents => ${ $cmd->stdout }, suffix => "crontab"});
    Patched::File->new(path => $crontab_file)->append("$entry\n");

    $cmd = Patched::Command->new(cmd => $crontab, args => ["-u", $this->user, $crontab_file], autodie => 0)->run;
    unless ($cmd->success || 256 == int($cmd->child_error)) {
        croak("Unable to set crontab with new entry");
    }

    return $this;
}

sub del ($this, $entry) {
    if (!defined $this->user) {
        croak("Please pass in a user.\n");
    }

    if (!defined $entry) {
        croak("Please pass in an entry.\n");
    }

    unless ($this->exists($entry)) {
        croak("crontab entry '$entry' not found");
    }

    my $crontab = Patched::Command->find("crontab") or croak("Unable to find crontab command");
    my $cmd = Patched::Command->new(cmd => $crontab, args => ["-u", $this->user, "-l"], autodie => 0)->run;
    unless ($cmd->success || 256 == int($cmd->child_error)) {
        croak("Unable to get crontab listing");
    }

    my $crontab_file = Patched::File->tmp({contents => ${ $cmd->stdout }, suffix => "crontab"});
    Patched::File->new(path => $crontab_file)->remove("$entry\n");

    $cmd = Patched::Command->new(cmd => $crontab, args => ["-u", $this->user, $crontab_file])->run;
    unless ($cmd->success || 256 == int($cmd->child_error)) {
        croak("Unable to set crontab with new entry");
    }

    return $this;
}

sub clear ($this) {
    if (!defined $this->user) {
        croak("Please pass in a user.\n");
    }

    my $crontab = Patched::Command->find("crontab") or croak("Unable to find crontab command");
    my $cmd = Patched::Command->new(cmd => $crontab, args => ["-u", $this->user, "-r"], autodie => 0)->run;
    unless ($cmd->success || 256 == int($cmd->child_error)) {
        croak("Unable to clear crontab");
    }

    return $this;
}

sub list ($this) {
    if (!defined $this->user) {
        croak("Please pass in a user.\n");
    }

    my $crontab = Patched::Command->find("crontab") or croak("Unable to find crontab command");
    my $cmd = Patched::Command->new(cmd => $crontab, args => ["-u", $this->user, "-l"], autodie => 0)->run;
    
    unless ($cmd->success || 256 == int($cmd->child_error)) {
        croak("Unable to get crontab listing");
    }

    # Should this be converted to an array?
    return ${ $cmd->stdout };
}

1;
