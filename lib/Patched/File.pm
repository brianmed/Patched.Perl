package Patched::File;

use Mojo::Base -strict;

use autodie;
use Moose;
use Mojo::Util;
use File::Temp qw(tempfile);
use IO::String;
use File::Copy;
use Tie::File;
use List::Util qw(any);

use experimental qw(signatures);

has 'path' => (is => 'ro', isa => 'Str');
has 'str' => (is => 'ro');

sub match ($this, $string) {
    my $fh;

    if (defined $this->str) {
        $fh = IO::String->new($this->str);
    }
    else {
        open($fh, "<", $this->path);
    }

    my $qr = qr/$string/;
    my $line;

    while (<$fh>) {
        if (/$qr/) {
            $line = $_;
            last;
        }
    }

    close($fh);

    return $line;
}

sub find ($this, $string) {
    my $fh;

    if (defined $this->str) {
        $fh = IO::String->new($this->str);
    }
    else {
        open($fh, "<", $this->path);
    }

    my $line;

    while (<$fh>) {
        if ($string eq $_) {
            $line = $_;
            last;
        }
    }

    close($fh);

    return $line;
}

sub comment ($this, @comments) {
    my $fh;
    if (defined $this->str) {
        $fh = IO::String->new($this->str);
    }
    else {
        open($fh, "+<", $this->path);
    }

    tie(my @lines, "Tie::File", $fh);
    foreach my $line (@lines) {
        if (any {"$line\n" eq $_} @comments) {
            $line = "# $line";
            next;
        }
    }
    untie(@lines);

    return $this;
}

# append if not found
sub upsert ($this, $upsert) {
    return $this if $this->find($upsert);

    $this->append($upsert);

    return $this;
}

sub prepend ($this, $prepend) {
    my $fh;
    if (defined $this->str) {
        $fh = IO::String->new($this->str);
    }
    else {
        open($fh, "+<", $this->path);
    }

    tie(my @lines, "Tie::File", $fh);
    unshift(@lines, $prepend);
    untie(@lines);

    return $this;
}

sub append ($this, $append) {
    my $fh;
    if (defined $this->str) {
        $fh = IO::String->new($this->str);
    }
    else {
        open($fh, ">>", $this->path);
    }

    print($fh $append);

    close($fh);

    return $this;
}

sub remove ($this, $line) {
    if ($this->str) {
        croak("Only regular files are supported for remove");
    }

    # Find
    open(my $fh, "<", $this->path);
    my ($found, @output) = (0);
    while (<$fh>) {
        if ($_ eq $line) {
            $found = 1;
            next;
        }

        push(@output, $_);
    }
    close($fh);

    return undef unless $found;

    # Remove
    open($fh, ">", $this->path);
    foreach my $line (@output) {
        print($fh $line);
    }
    close($fh);

    return $this;
}

sub replace ($this, $find, $replace) {
    if ($this->str) {
        croak("Only regular files are supported for replace");
    }

    # Find / replace (memory intensive)
    open(my $fh, "<", $this->path);
    my ($found, $output) = (0, "");
    while (<$fh>) {
        if (ref $find && "RegExp" eq ref($find)) {
            if ($_ =~ m/$find/) {
                $_ = $replace;
                $found = 1;
            }
        }
        else {
            if ($_ eq $find) {
                $_ = $replace;
                $found = 1;
            }
        }

        $output .= $_;
    }
    close($fh);

    return undef unless $found;

    $this->spurt($output);

    return $this;
}

sub spurt ($this, $contents) {
    return Mojo::Util::spurt($contents, $this->path);
}

sub slurp ($this) {
    return Mojo::Util::slurp($this->path);
}

sub tmp ($this, $ops) {
    my $suffix = $ops && $$ops{suffix} ? $$ops{suffix} : "tmp";
    my ($fh, $filename) = tempfile("patched_${suffix}_XXXXXX", TMPDIR => 1);

    if ($ops && $$ops{contents}) {
        print($fh $$ops{contents});
    }

    if ($ops && $$ops{fh}) {
        return($fh, $filename);
    }
    
    return($filename);
}

1;
