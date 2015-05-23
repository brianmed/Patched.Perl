package Patched::File;

use Mojo::Base -strict;

use autodie;
use Moose;
use Mojo::Util;

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
    return Mojo::Util::spurt($contents, $path);
}

sub slurp ($this, $path) {
    return Mojo::Util::slurp($path);
}

1;
