package Patched::Minimal;

use Mojo::Base -strict;

use Carp;
use Moose;
use Mojo::Util 'monkey_patch';
use Mojo::Loader 'data_section';
use Mojo::Template;

use Patched::Command;

sub import {
    my $caller = caller;

    monkey_patch($caller, command => sub { 
        Patched::Command->new(@_);
    });

    monkey_patch($caller, config => sub { 
        if (1 == @_) {
            if ("-" eq $_[0]) {
              my $name = "minimal.conf";

              my $str = Mojo::Template->new->name("template $name from DATA section")
                ->render(data_section("main", $name));

                @_ = (str => $str);
            }
            else {
                unshift(@_, "path");
            }
        }

        Patched::Config->new(@_)->parse;
    });

    monkey_patch($caller, directory => sub { 
        if (1 == @_) {
            unshift(@_, "path");
        }

        Patched::Directory->new(@_);
    });

    monkey_patch($caller, file => sub { 
        if (1 == @_) {
            unshift(@_, "path");
        }

        Patched::File->new(@_);
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

    monkey_patch($caller, user => sub { 
        if (1 == @_) {
            unshift(@_, "uname");
        }

        Patched::User->new(@_)
    });

    monkey_patch($caller, pipeline => sub { 
        my @cmd = (shift, shift);

        Patched::Command->new(cmd => \@cmd);
    });
}

1;
