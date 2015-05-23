package Patched::Controller::Index;

use Mojo::Base 'Mojolicious::Controller';

sub slash {
    my $c = shift;

    $c->render;
}

1;
