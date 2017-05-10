#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::More tests => 108;
use Data::Dumper;
use Path::Tiny;
use Test::WWW::Mechanize::Catalyst;
use DateTime;
# reuse the 
my $site_id = '0deferred1';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0 });

ok !$site->show_preview_when_deferred;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
my (@urls, @covers, @teasers,
    @pub_urls, @pub_teasers, @pub_covers);
foreach my $i (0..3) {
    my $defer = $i > 1 ? 1 : 0;
    my ($rev) = $site->create_new_text({ uri => "deferred-text-$i",
                                         title => ($defer ? 'Deferred #' . $i : 'Published #' . $i),
                                         teaser => ($i ? "This is the preview for $i" : ''),
                                         author => "Pallino",
                                         SORTtopics => "Topico",
                                         pubdate => ($defer ? DateTime->now->add(days => 10)->ymd : DateTime->today->ymd),
                                         lang => 'en' }, 'text');
    my $cover = catfile(qw/t files shot.png/);
    if ($i) {
        my $got = $rev->add_attachment($cover);
        $rev->edit("#cover $got->{attachment}\n" . $rev->muse_body);
    }
    $rev->edit($rev->muse_body . "\n\nFULL TEXT HERE\n");
    $rev->commit_version;
    $rev->publish_text;
    if ($defer) {
        push @urls, $rev->title->full_uri;
        push @covers, $rev->title->cover if $rev->title->cover;
        push @teasers, $rev->title->teaser if $rev->title->teaser;
    }
    else {
        push @pub_urls, $rev->title->full_uri;
        push @pub_covers, $rev->title->cover  if $rev->title->cover;
        push @pub_teasers, $rev->title->teaser if $rev->title->teaser;
    }
}

$mech->get_ok('/api/autocompletion/topic');
$mech->content_contains('["Topico"]');
$mech->get_ok('/api/autocompletion/author');
$mech->content_contains('["Pallino"]');

foreach my $type (qw/author topic/) {
    my $rs = $site->categories->by_type($type)->with_texts(deferred => 1);
    my $cat = $rs->first;
    ok $cat, "Category $type found";
    is $cat->text_count, 4, "Text count is not stored";
    is ($schema->resultset('Category')->find($cat->id)->text_count, 0,
        "Category found from schema has no text_count");
}


foreach my $url (@urls) {
    diag $url;
    $mech->get($url);
    is $mech->status, 404;
}
foreach my $url (@pub_urls) {
    $mech->get_ok($url);
}

# attachments are always published even if the text is not
foreach my $att ($site->attachments->all) {
    $mech->get_ok($att->full_uri);
}

my @test_urls = (
                 '/category/topic/topico',
                 '/category/author/pallino'
                );

diag Dumper(\@pub_urls, \@pub_covers, \@pub_teasers);

foreach my $url (@test_urls) {
    diag "Getting $url";
    $mech->get($url);
    foreach my $fragment (@covers, @teasers, @urls) {
        $mech->content_lacks($fragment);
    }
    foreach my $fragment (@pub_covers, @pub_teasers, @pub_urls) {
        $mech->content_contains($fragment) or die $mech->content;
    }
}

$mech->get_ok('/login');
# foreach my $id (qw/amw-nav-bar-authors amw-nav-bar-topics/) {
#     $mech->content_lacks($id);
# }

ok($mech->form_id('login-form'), "Found the login-form");
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
# we have published texts in those categories
# foreach my $id (qw/amw-nav-bar-authors amw-nav-bar-topics/) {
#     $mech->content_contains($id);
# }
$mech->content_contains('You are logged in now!');
foreach my $url (@urls, @pub_urls) {
    $mech->get_ok($url);
    $mech->content_contains("FULL TEXT HERE");
}

foreach my $url (@test_urls) {
    $mech->get_ok($url);
    foreach my $fragment (@covers, @teasers, @urls, @pub_covers, @pub_teasers, @pub_urls) {
        $mech->content_contains($fragment);
    }
}

$mech->get_ok('/logout');
$site->add_to_site_options({
                             option_name => 'show_preview_when_deferred',
                             option_value => 1,
                            });
$site = $schema->resultset('Site')->find($site->id);

ok $site->show_preview_when_deferred;

foreach my $url (@test_urls) {
    $mech->get_ok($url);
    foreach my $fragment (@covers, @teasers, @pub_urls, @pub_covers, @pub_teasers) {
        $mech->content_contains($fragment);
    }
    foreach my $fragment (@urls) {
        $mech->content_contains($fragment);
    }
}
foreach my $url (@urls) {
    $mech->get_ok($url);
    $mech->content_contains('<div class="alert alert-info" role="alert">This text is not available</div>',
                            "$url is without body not accessible");
    $mech->content_lacks("FULL TEXT HERE");
}
foreach my $url (@pub_urls) {
    $mech->get_ok($url);
    $mech->content_lacks('<div class="alert alert-info" role="alert">This text is not available</div>',
                            "$url is without body not accessible");
    $mech->content_contains("FULL TEXT HERE");
}


