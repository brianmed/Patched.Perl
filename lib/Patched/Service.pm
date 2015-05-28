package Patched::Service;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;

use Patched::Command;

use experimental qw(signatures);

has 'name' => (is => 'ro', isa => 'Str');

sub BUILD {
    my $this = shift;

    unless ($this->installed) {
        croak($this->name . " service not found");
    }
}

sub installed ($this) {
    unless (-f "/etc/rc.d/init.d/" . $this->name) {
        return 0;
    }

    my $chkconfig = Patched::Command->find("chkconfig");

    Patched::Command->new(cmd => $chkconfig, args => ["--list", $this->name])->run;

    return $this;
}

sub action ($this, $action) {
    my $service = Patched::Command->find("service");

    Patched::Command->new(cmd => $service, args => [$this->name, $action])->run;

    return $this;
}

1;
