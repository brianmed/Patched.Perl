package Patched::Config;

use Mojo::Base -strict;

use autodie;

use Moose;
use Mojo::Util qw(decode slurp);
use FindBin;

use experimental qw(signatures);

has 'path' => (is => 'ro', isa => 'Str');
has 'str' => (is => 'ro', isa => 'Str');

## A lot from Mojolicious::Plugin::Config;
sub parse ($this) {
    if ($this->str) {
        return $this->_parse(decode('UTF-8', $this->str), "this->str");
    }
    
    my $file = $this->path;

    my $path = "$FindBin::Bin/$file";
    
    return $this->_parse(decode('UTF-8', slurp $path), $path);
}

sub _parse ($this, $content, $file) {
    # Run Perl code in sandbox
    my $config = eval 'package Patched::Config::Sandbox; no warnings;'
        . "use Mojo::Base -strict; $content";
    die qq{Can't load configuration from file "$file": $@} if $@;
    die qq{Configuration file "$file" did not return a hash reference.\n}
        unless ref $config eq 'HASH';
    
    return $config;
}

1;
