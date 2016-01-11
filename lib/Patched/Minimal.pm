package Patched::Minimal;

use Mojo::Base -strict;

use experimental qw(signatures);

use Carp;
use Moose;
use Mojo::Util 'monkey_patch';

sub import {
    my $caller = caller;

    monkey_patch($caller, run => sub { 
        Patched::Command->new(
            cmd => shift,
            args => ref($_[0]) ? $_[0] : \@_
        )->run;
    });

    monkey_patch($caller, find_bin => sub { 
        Patched::Command->find(shift)
    });

    monkey_patch($caller, service => sub { 
        Patched::Service->new(name => shift)
    });

    monkey_patch($caller, package_install => sub { 
        Patched::Package->install(shift)
    });

    monkey_patch($caller, packages_install => sub { 
        Patched::Packages->install(shift)
    });
}

1;
