package Patched::File;

use Mojo::Base -strict;

use autodie;
use Moose;
use Mojo::Util;
use File::Temp qw(tempfile);

use experimental qw(signatures);

has 'path' => (is => 'ro', isa => 'Str');

sub match ($this, $string) {
    open(my $fh, "<", $this->path);

    my $qr = qr/$string/;
    my $line = "";

    while (<$fh>) {
        if (/$qr/) {
            $line = $_;
            last;
        }
    }

    close($fh);

    return $line;
}

sub spurt ($this, $path, $contents) {
    return Mojo::Util::spurt($contents, $path);
}

sub slurp ($this, $path) {
    return Mojo::Util::slurp($path);
}

sub tmp ($this, $ops) {
    my ($fh, $filename) = tempfile("patched_tmp_XXXXXX", TMPDIR => 1 );

    if ($$ops{contents}) {
        print($fh $$ops{contents});
    }

    if ($ops && $$ops{fh}) {
        return($fh, $filename);
    }
    
    return($filename);
}

1;
