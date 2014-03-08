package AmuseWikiFarm::Archive;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

use Search::Xapian (':all');
use AmuseWikiFarm::Utils::Amuse qw/muse_file_info/;
use Unicode::Collate::Locale;
use File::Spec;
use AmuseWikiFarm::Archive::Xapian;


has code => (is => 'ro',
             required => 1,
             isa => 'Str');

has dbic => (is => 'ro',
             required => 1,
             isa => 'Object');

has basedir => (is => 'ro',
                required => 0,
                isa => 'Str');

has xapian => (is => 'ro',
               required => 0,
               isa => 'Object',
               lazy => 1,
               builder => '_build_xapian_object',
              );

sub _build_xapian_object {
    my $self = shift;
    return AmuseWikiFarm::Archive::Xapian->new(
                                               code => $self->code,
                                               basedir => $self->basedir || '',
                                              );
}

has fields => (is => 'ro',
               isa => 'HashRef[Str]',
               lazy => 1,
               builder => '_build_fields');

sub _build_fields {
    my $self = shift;
    warn "Building fields\n";
    my %fields = map { $_ => 1 }
      $self->dbic->resultset('Title')->result_source->columns;
    return \%fields;
}

has site_exists => (is => 'ro',
                    required => 1,
                    isa => 'Str',
                    lazy => 1,
                    builder => '_build_site_exists');

sub _build_site_exists {
    my $self = shift;
    my $site = $self->dbic->resultset('Site')->find($self->code);
    $site ? return 1 : return 0;
    
}

sub repo {
    my $self = shift;
    my @path;
    if (my $root = $self->basedir) {
        push @path, $root;
    }
    push @path, (repo => $self->code);
    my $dir = File::Spec->catdir(@path);
    die "Fatal, no repo found!" unless -d $dir;
    return $dir;
}


=head2 index_file($file)

Add the file to the DB and Xapian databases, first parsing it with
C<muse_info_file> from L<AmuseWikiFarm::Utils::Amuse>.

=cut

sub index_file {
    my ($self, $file) = @_;
    unless ($file && -f $file) {
        $file ||= '<empty>';
        warn "File $file does not exist";
        return;
    }

    my $details = muse_file_info($file, $self->code);
    # unparsable
    return unless $details;

    if ($details->{f_suffix} ne '.muse') {
        warn "Inserting data for attachment $file\n";
        $self->dbic->resultset('Attachment')->update_or_create($details);
        return $file;
    }

    # ready to store into titles?
    my %insertion;
    # lower case the keys
    foreach my $col (keys %$details) {
        my $db_col = lc($col);
        if (exists $self->fields->{$db_col}) {
            $insertion{$db_col} = delete $details->{$col};
        }
    }

    my $parsed_cats = delete $details->{parsed_categories};
    if (%$details) {
        warn "Unhandle directive in $file: " . join(", ", %$details) . "\n";
    }
    print "Inserting data for $file\n";
    # TODO: see if we have to update the insertion
    my $title = $self->dbic->resultset('Title')->update_or_create(\%insertion);
    if ($parsed_cats && @$parsed_cats) {
        # here we can die if there are duplicated uris
        $title->set_categories($parsed_cats);
    }

    # TODO maybe the categories should be cleaned if there are none?

    return $file unless $self->xapian;
    # print $title->topic_list, ' ', $title->author_list, "\n";
    # XAPIAN INDEXING

    $self->xapian->index_text($title);
    return $file;
}


=head2 collation_index

Update the C<sorting_pos> field of each text and category based on the
collation for the current locale.

Collation on the fly would have been too slow, or would depend on the
(possibly crappy) collation of the database engine, if any.

=cut

sub collation_index {
    my $self = shift;
    my $site = $self->dbic->resultset('Site')->find($self->code);

    my $collator = Unicode::Collate::Locale->new(locale => $site->locale);

    my @texts = sort {
        # warn $a->id . ' <=>  ' . $b->id;
        $collator->cmp($a->list_title, $b->list_title)
    } $site->titles;

    my $i = 1;
    foreach my $t (@texts) {
        $t->sorting_pos($i++);
        $t->update;
    }

    # and then sort the categories
    my @categories = sort {
        # warn $a->id . ' <=> ' . $b->id;
        $collator->cmp($a->name, $b->name)
    } $site->categories;

    $i = 1;
    foreach my $cat (@categories) {
        $cat->sorting_pos($i++);
        $cat->update;
    }

}

__PACKAGE__->meta->make_immutable;

1;
