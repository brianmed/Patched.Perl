package Patched::Minimal;

use Mojo::Base -strict;

use Carp;
use Moose;
use Mojo::Util 'monkey_patch';

use Patched::Command;

sub import {
    my $caller = caller;

    monkey_patch($caller, command => sub { 
        Patched::Command->new(@_);
    });

    monkey_patch($caller, localhost => sub { 
        Patched::Localhost->new(@_);
    });

    monkey_patch($caller, package => sub { 
        Patched::Package->new(@_)
    });

    monkey_patch($caller, packages => sub { 
        Patched::Packages->new(@_)
    });

    monkey_patch($caller, service => sub { 
        Patched::Service->new(@_)
    });

    monkey_patch($caller, pipeline => sub { 
        my @cmd = (shift, shift);

        Patched::Command->new(cmd => \@cmd);
    });
}

1;
