use strict;
use warnings;

use Test2::V0;

use Imager;
use Imager::Filter::Binarization;
use File::Spec;
use FindBin '$Bin';

my $file = File::Spec->catfile($Bin, 'data', 'oreo.jpg');

for my $method (qw(sauvola niblack)) {
    my $img = Imager->new(file => $file) or die Imager->errstr;

    $img = $img->convert( preset => 'grey' );
    my @colors = $img->getcolorusage();
    ok @colors > 2;

    $img->filter(
        type => "binarization",
        method => $method,
        geometry => "5x5"
    );
 
    @colors = $img->getcolorusage();
    ok @colors <= 2;
}

done_testing;
