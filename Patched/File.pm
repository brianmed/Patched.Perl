package Patched::File;

use Mojo::Base -strict;

use autodie;
use Moose;
use Mojo::Util qw(spurt slurp);

use experimental qw(signatures);

has 'path' => (is => 'ro', isa => 'Str');

sub match ($this, $string) {
    open(my $fh, "<", $this->path);

    my $matched = 0;
    my $qr = qr/$string/;

    while (<$fh>) {
        if (/$qr/) {
            $matched = 1;
            last;
        }
    }

    close($fh);

    return $matched;
}

sub spurt ($this, $path, $contents) {
    return spurt($contents, $path);
}

sub slurp ($this, $path) {
    return slurp($path);
}

1;
