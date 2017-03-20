#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Cwd;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 2;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0gall0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

# create a gallery

my $gallery = $site->galleries->create({ gallery_uri => 'test',
                                         title => 'test',
                                       });
is $gallery->site_id, $site->id;

is $gallery->site->id, $site->id;

ok $site->upload_staging_dir;

my %staged;
foreach my $ext (qw/jpg pdf png/) {
    my $out = $site->stage_attachment(catfile(qw/t files shot/) . '.' . $ext);
    $staged{$out->{attachment}} = 1;
}
diag Dumper(\%staged);
is scalar(keys %staged), 3;

