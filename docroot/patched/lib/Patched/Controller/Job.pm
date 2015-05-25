package CallsAbound::Controller::API;

use Mojo::Base 'Mojolicious::Controller';

use Patched::Globals;
use Patched::Command;
use Patched::File;

sub run {
    my $c = shift;

    $c->inactivity_timeout(300);

    my $code = $c->req->json->{script};
    
    my $script = $Patched::Globals::Preamble . $code;

    my $file = Patched::File->tmp;

    my $perl = $Patched::Globals::Perl;

    my $cmd = Patched::Command->new(cmd => $perl, args => $file)->run;

    return($c->render(json => {status => $cmd->success}));
}

1;
