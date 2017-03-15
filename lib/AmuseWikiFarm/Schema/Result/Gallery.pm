use utf8;
package AmuseWikiFarm::Schema::Result::Gallery;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Gallery

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

=head1 TABLE: C<gallery>

=cut

__PACKAGE__->table("gallery");

=head1 ACCESSORS

=head2 gallery_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 muse_desc

  data_type: 'text'
  is_nullable: 1

=head2 html_desc

  data_type: 'text'
  is_nullable: 1

=head2 last_modified

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "gallery_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "muse_desc",
  { data_type => "text", is_nullable => 1 },
  "html_desc",
  { data_type => "text", is_nullable => 1 },
  "last_modified",
  { data_type => "datetime", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gallery_id>

=back

=cut

__PACKAGE__->set_primary_key("gallery_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<uri_site_id_unique>

=over 4

=item * L</uri>

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint("uri_site_id_unique", ["uri", "site_id"]);

=head1 RELATIONS

=head2 gallery_attachments

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::GalleryAttachment>

=cut

__PACKAGE__->has_many(
  "gallery_attachments",
  "AmuseWikiFarm::Schema::Result::GalleryAttachment",
  { "foreign.gallery_id" => "self.gallery_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 site

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "site",
  "AmuseWikiFarm::Schema::Result::Site",
  { id => "site_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 attachments

Type: many_to_many

Composing rels: L</gallery_attachments> -> attachment

=cut

__PACKAGE__->many_to_many("attachments", "gallery_attachments", "attachment");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-03-15 09:37:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nMOSK2SExkcIFcVxp62x4A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
