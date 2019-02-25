use strict;
use warnings;
package Imager::Filter::Binarization;
# ABSTRACT: A collection of image binarization algorthims as image filter.

=head1 SYNOPSIS

    use Imager;
    use Imager::Filter::Binarization;

    my $img = Imager->new(file => $file) or die Imager->errstr;
    $img->filter(
        type => "binarization",
        method => "niblack",
        geometry => "5x5"
    );
    $img->write(file => "binarized.png");

=head1 DESCRIPTION

This module provides several implementations of image binarization
algorithms. It assumes the input image is already grayscale, and
therefore use only the first channel (red) to perform binarization.

=cut

use List::Util qw<min max>;
use Statistics::Basic qw<vector mean stddev>;

sub binarization_filter {
    my %param = @_;
    my $ctx = { param => \%param };
    $ctx->{img_copy} = $param{imager}->copy();
    return binarize_with_niblack($ctx);
}

sub binarize_with_niblack {
    my ($ctx) = @_;
    my $img = $ctx->{param}{imager};
    my $img_copy = $ctx->{img_copy};

    my ($w,$h) = split("x", $ctx->{param}{geometry});

    my $img_bound_y = $img->getheight - 1;
    my $img_bound_x = $img->getwidth - 1;
    $w ||= $h;
    my $w_half_1 = int(($w-1)/2);
    my $w_half_2 = int($w/2);
    my $h_half_1 = int(($h-1)/2);
    my $h_half_2 = int($h/2);

    my $summerize_method = __PACKAGE__->can("summerize_" . $ctx->{param}{method});
    die "Unknown method: $ctx->{param}{method}" unless $summerize_method;

    for my $y (0 .. $img_bound_y) {
        for my $x (0..$img_bound_x) {
            my $y_0 = max(0, $y - $h_half_1);
            my $y_1 = min($y + $h_half_2, $img_bound_y);
            my $x_0 = max(0, $x - $w_half_1);
            my $x_1 = min($x + $w_half_2, $img_bound_x);
            my $w_ = $x_1 - $x_0 + 1;
            my $center = $img_copy->getpixel( x=> $x, y => $y );
            my @px = map { $img_copy->getscanline(y => $_, x => $x_0, width => $w_) } ($y_0 .. $y_1);

            my $new_px = $summerize_method->($ctx, $center, \@px);

            $img->setpixel( y => $y, x => $x, color => $new_px);
        }
    }
}

sub summerize_niblack {
    my ($ctx, $current_pixel, $pixels) = @_;
    my @c = map { ($_->rgba)[0] } @$pixels;
    my $v = vector(@c);
    my $T = mean($v) + ($ctx->{params}{k} // 0.2) * stddev($v);
    my $c = ($current_pixel->rgba)[0];
    return [ (($c > $T) ? 255 : 0) , 0, 0 ];
}

sub summerize_sauvola {
    my ($ctx, $current_pixel, $pixels) = @_;
    my @c = map { ($_->rgba)[0] } @$pixels;
    my $v = vector(@c);
    my $T = mean($v) * (1 + ($ctx->{params}{k} // 0.5) * (stddev($v)/ ($ctx->{params}{R} // 128) - 1));
    my $c = ($current_pixel->rgba)[0];
    return [ (($c > $T) ? 255 : 0) , 0, 0 ];
}

Imager->register_filter(
    type     => 'binarization',
    callsub  => \&binarization_filter,
    callseq  => ['image', 'method', 'geometry'],
    defaults => {},
);
