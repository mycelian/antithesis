#!perl
use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWikiFarm::Schema;
use Test::More tests => 10;
use Data::Dumper::Concise;
use YAML qw/Dump Load/;
use Path::Tiny;
use AmuseWikiFarm::Utils::Amuse;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0blobs0');

foreach my $f (path('t/binary-files')->children) {
    diag "Copying $f to uploads directory";
    $f->copy($site->path_for_uploads);
}


my %expected = (
                flac => 'audio/flac',
                mp3 => 'audio/mpeg',
                ogg  => 'audio/x-vorbis+ogg',
                avi => 'video/x-msvideo',
                mkv => 'video/x-matroska',
                mov => 'video/quicktime',
                mp4 => 'video/mp4',
                mpg => 'video/mpeg',
                ogv => 'video/x-theora+ogg',
                webm => 'video/webm',
                pdf => 'application/pdf',
                epub => 'application/epub+zip',
               );

my @files;
foreach my $f (sort (path($site->path_for_uploads)->children)) {
    my $mime = AmuseWikiFarm::Utils::Amuse::mimetype("$f");
    if ($f =~ m/\.(\w+)$/) {
        my $ext = $1;
        is $mime, $expected{$ext}, "$f mimetype correct: $mime";
        push @files, $f->basename;
    }
    else {
        die "Bad filename"
    }
}

# then create a file

my $muse = path($site->repo_root, qw/t tt test.muse/);
$muse->parent->mkpath;
$muse->spew_utf8(<<"MUSE");
#title File Gallery
#blob 1
#attach @{[ join(' ', @files) ]}

MUSE

ok $muse->exists, "$muse is fine";

$site->update_db_from_tree(sub { diag join(' ', @_) });

is $site->attachments->count, scalar(@files);
is $site->titles->count, 1;


