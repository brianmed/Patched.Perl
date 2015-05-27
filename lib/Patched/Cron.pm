package Patched::Cron;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;

use Patched::Command;

use experimental qw(signatures);

sub exists ($this, $name, $entry) {
    if (!defined $name) {
        croak("Please pass in a name.\n");
    }

    if (!defined $entry) {
        croak("Please pass in an entry.\n");
    }

    my $crontab = Patched::Command->find("crontab") or croak("Unable to find crontab command");

    my $cmd = Patched::Command->new(cmd => $crontab, args => "-l")->run;

    unless ($cmd->success) {
        croak("Unable to get crontab listing");
    }

    if (Patched::File->new(str => $cmd->stdout)->find($entry)) {
        return 1;
    }
    else {
        return 0;
    }
}

sub add ($this, $name, $entry) {
}

1;
