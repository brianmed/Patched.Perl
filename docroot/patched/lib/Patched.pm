package Patched;

use Mojo::Base 'Mojolicious';

use Patched::Globals;
use Patched::Bcrypt;

sub api_key
{
    state $api_key = pop;
}

sub startup {
    my $self = shift;
    
    my $InstallDir = $Patched::Globals::InstallDir;

    my $config = $self->plugin(JSONConfig => {file => "$InstallDir/config"});

    $self->secrets([$$config{secret}{current}]);
    $self->helper(api_key => \&api_key);

    $self->api_key($$config{api_key});

    $self->plugin('Patched');

    if ($$config{type} && "minion" eq $$config{type}) {
        $self->plugin(Minion => {Pg => "postgresql://$$config{dbi_user}:$$config{dbi_pass}\@127.0.0.1/patched_jobs"});
    }

    my $r = $self->routes;

    my $api = $r->under (sub {
        my $self = shift;

        return($self->render(json => {success => 0, data => { message => "No JSON found" }})) unless $self->req->json;

        my $api_key = $self->req->json->{api_key};

        unless ($api_key) {
            $self->render(json => {success => 0, data => { message => "No API Key found" }});

            return undef;
        }

        unless (Patched::Bcrypt->check_password($api_key, $self->api_key)) {
            $self->render(json => {success => 0, data => { message => "Credentials mis-match" }});

            return undef;
        }

        return 1;
    });
    
    $r->get('/')->to(controller => 'Index', action => 'slash');

    $api->post('/api/v1/job/run')->to(controller => "Job", action => "run");
}

1;
