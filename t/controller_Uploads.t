use strict;
use warnings;
use utf8;
use Test::More tests => 57;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $pdf = catfile(qw/t files shot.pdf/);
my $png = catfile(qw/t files shot.png/);
ok (-f $pdf);
ok (-f $png);
my $site_id = '0sf1';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);

my ($rev) = $site->create_new_text({ title => 'HELLO',
                                     lang => 'hr',
                                     textbody => '<p>ciao</p>',
                                   }, 'text');
my $expected = $rev->add_attachment($pdf)->{attachment};
$rev->edit("#ATTACH $expected\n" . $rev->muse_body);
is $expected, "h-o-hello-1.pdf", "$expected is h-o-hello-1.pdf";
is_deeply($rev->attached_pdfs, [ $expected ]);
my $png_att = $rev->add_attachment($png)->{attachment};
$rev->edit("#cover $png_att\n" . $rev->muse_body);
is ($png_att, "h-o-hello-1.png");

$rev->commit_version;
$rev->publish_text;

my $text = $rev->title->discard_changes;
is ($text->cover_uri, '/library/h-o-hello-1.png');
is ($text->cover_thumbnail_uri, '/uploads/0sf1/thumbnails/h-o-hello-1.png.thumb.png');
is ($text->cover_small_uri, '/uploads/0sf1/thumbnails/h-o-hello-1.png.small.png');


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$mech->get_ok("/uploads/$site_id/$expected");
$mech->get_ok($text->cover_thumbnail_uri);
$mech->get_ok($text->cover_uri);
$mech->get_ok($text->cover_small_uri);
$mech->get_ok("/library/hello");
$mech->content_contains(qq{/uploads/$site_id/$expected"});
$mech->content_contains(qq{/uploads/$site_id/thumbnails/$expected.thumb.png"});


foreach my $file ($expected, $png_att) {
    foreach my $type (qw/small thumb/) {
        my $thumb = catfile('thumbnails', $site_id, "$file.$type.png");
        diag "Checking $thumb\n";
        if (-f $thumb) {
            unlink $thumb or die $!;
        }
        ok (! -f $thumb, "$thumb does not exist");
        $mech->get_ok("/uploads/$site_id/thumbnails/$file.$type.png");
        ok (-f $thumb, "$thumb exists");
        my $stat = (stat($thumb))[9];
        foreach my $sleep (1..2) {
            sleep $sleep if $sleep;
            $mech->get_ok("/uploads/$site_id/thumbnails/$file.$type.png");
            is ((stat($thumb))[9], $stat, "File $thumb has been cached correctly");
        }
        my $srcfile = $site->attachments->by_uri($file)->f_full_path_name;;
        ok(-f $srcfile, "Found $srcfile");
        my $atime = my $mtime = time();
        utime $atime, $mtime, $srcfile;
        $mech->get_ok("/uploads/$site_id/thumbnails/$file.$type.png");
        ok((stat($thumb))[9] > $stat, "Thumb $type $thumb regenerated");
    }
}
$mech->get_ok('/latest');
$mech->content_contains("/uploads/$site_id/thumbnails/$png_att.small.png");
