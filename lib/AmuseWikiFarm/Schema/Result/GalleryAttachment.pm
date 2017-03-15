use utf8;
package AmuseWikiFarm::Schema::Result::GalleryAttachment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::GalleryAttachment

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

=head1 TABLE: C<gallery_attachment>

=cut

__PACKAGE__->table("gallery_attachment");

=head1 ACCESSORS

=head2 gallery_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 attachment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "gallery_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "attachment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gallery_id>

=item * L</attachment_id>

=back

=cut

__PACKAGE__->set_primary_key("gallery_id", "attachment_id");

=head1 RELATIONS

=head2 attachment

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Attachment>

=cut

__PACKAGE__->belongs_to(
  "attachment",
  "AmuseWikiFarm::Schema::Result::Attachment",
  { id => "attachment_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 gallery

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Gallery>

=cut

__PACKAGE__->belongs_to(
  "gallery",
  "AmuseWikiFarm::Schema::Result::Gallery",
  { gallery_id => "gallery_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-03-15 09:37:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VpIKM4DkhNj26ryL+uE3dA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
