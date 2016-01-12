package Patched::Minimal;

use Mojo::Base -strict;

use Carp;
use Moose;
use Mojo::Util 'monkey_patch';

use Patched::Command;

sub command {
    my $this = shift;

    return Patched::Command->new({@_});
}

sub localhost {
    my $this = shift;

    return Patched::Localhost->new(@_);
}

sub package {
    my $this = shift;

    return Patched::Package->new(@_);
}

sub packages {
    my $this = shift;

    return Patched::Packages->new(@_);
}

sub service {
    my $this = shift;

    return Patched::Service->new(@_);
}

=for comment
sub pipeline ($this) {
    my @cmd = (shift, shift);

    return Patched::Command->new(cmd => \@cmd)->run;
}
=cut

sub import {
    my $caller = caller;

    monkey_patch($caller, p => sub { 
        Patched::Minimal->new
    });

=for comment
    monkey_patch($caller, run => sub { 
        Patched::Command->new(
            cmd => shift,
            args => ref($_[0]) ? $_[0] : \@_
        )->run;
    });

    monkey_patch($caller, pipeline => sub { 
        my @cmd = (shift, shift);
        Patched::Command->new(
            cmd => \@cmd,
        )->run;
    });

    monkey_patch($caller, cmd => sub { 
        Patched::Command->new(
            cmd => shift,
            args => ref($_[0]) ? $_[0] : \@_
        );
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
=cut
}

1;
