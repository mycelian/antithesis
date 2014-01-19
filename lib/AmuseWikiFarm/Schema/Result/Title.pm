use utf8;
package AmuseWikiFarm::Schema::Result::Title;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Title

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<title>

=cut

__PACKAGE__->table("title");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 subtitle

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 lang

  data_type: 'varchar'
  default_value: 'en'
  is_nullable: 0
  size: 3

=head2 date

  data_type: 'text'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 source

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 list_title

  data_type: 'text'
  is_nullable: 1

=head2 author

  data_type: 'text'
  is_nullable: 1

=head2 uid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 attach

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pubdate

  data_type: 'timestamp'
  is_nullable: 1

=head2 f_path

  data_type: 'text'
  is_nullable: 0

=head2 f_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 f_archive_rel_path

  data_type: 'varchar'
  is_nullable: 0
  size: 4

=head2 f_timestamp

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 f_full_path_name

  data_type: 'text'
  is_nullable: 0

=head2 uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 deleted

  data_type: 'text'
  is_nullable: 1

=head2 site_id

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "subtitle",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "lang",
  { data_type => "varchar", default_value => "en", is_nullable => 0, size => 3 },
  "date",
  { data_type => "text", is_nullable => 1 },
  "notes",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "source",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "list_title",
  { data_type => "text", is_nullable => 1 },
  "author",
  { data_type => "text", is_nullable => 1 },
  "uid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "attach",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pubdate",
  { data_type => "timestamp", is_nullable => 1 },
  "f_path",
  { data_type => "text", is_nullable => 0 },
  "f_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "f_archive_rel_path",
  { data_type => "varchar", is_nullable => 0, size => 4 },
  "f_timestamp",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "f_full_path_name",
  { data_type => "text", is_nullable => 0 },
  "uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "deleted",
  { data_type => "text", is_nullable => 1 },
  "site_id",
  { data_type => "varchar", is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<uri_site_id_unique>

=over 4

=item * L</uri>

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint("uri_site_id_unique", ["uri", "site_id"]);

=head1 RELATIONS

=head2 title_authors

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TitleAuthor>

=cut

__PACKAGE__->has_many(
  "title_authors",
  "AmuseWikiFarm::Schema::Result::TitleAuthor",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 authors

Type: many_to_many

Composing rels: L</title_authors> -> author

=cut

__PACKAGE__->many_to_many("authors", "title_authors", "author");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-01-19 17:10:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TpyOxS036XynOQaA48g0dQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
