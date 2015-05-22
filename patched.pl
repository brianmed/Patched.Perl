#!/opt/perl

use Mojolicious::Lite;

plugin Minion => {Pg => "postgresql://$ENV{DBI_USER}:$ENV{DBI_PASS}\@127.0.0.1/patched"};
plugin qw(Patched);

get '/' => sub {
    my $c = shift;
    $c->render(template => 'index');
};

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to the Mojolicious real-time web framework!

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
