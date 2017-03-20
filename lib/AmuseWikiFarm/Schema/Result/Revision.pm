use utf8;
package AmuseWikiFarm::Schema::Result::Revision;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Revision - Text revisions

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

=head1 TABLE: C<revision>

=cut

__PACKAGE__->table("revision");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 f_full_path_name

  data_type: 'text'
  is_nullable: 1

=head2 message

  data_type: 'text'
  is_nullable: 1

=head2 status

  data_type: 'varchar'
  default_value: 'editing'
  is_nullable: 0
  size: 16

=head2 session_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 updated

  data_type: 'datetime'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "f_full_path_name",
  { data_type => "text", is_nullable => 1 },
  "message",
  { data_type => "text", is_nullable => 1 },
  "status",
  {
    data_type => "varchar",
    default_value => "editing",
    is_nullable => 0,
    size => 16,
  },
  "session_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "updated",
  { data_type => "datetime", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

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

=head2 title

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-02-17 19:36:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yieRb/xH9EN2+yAJnaVgzQ

# core modules
use File::Basename qw/fileparse/;
use File::Spec;
use File::Copy qw/copy move/;
use Digest::SHA;
use DateTime;

use Text::Amuse::Compile::Utils qw/read_file append_file write_file/;
use File::MimeInfo::Magic qw/mimetype/;
use Text::Amuse::Functions qw/muse_fast_scan_header/;
use Date::Parse;
use Text::Amuse;
use AmuseWikiFarm::Utils::Amuse qw/muse_get_full_path
                                   muse_parse_file_path
                                   muse_attachment_basename_for
                                   clean_username
                                   muse_naming_algo/;
use Text::Amuse::Preprocessor;
use AmuseWikiFarm::Log::Contextual;

=head2 muse_body

Return the text stored in the staging area (for editing)

=head2 muse_doc

Return a L<Text::Amuse> object for that file.

=head2 starting_file_body

Return the text stored in the starting file (for diffing).

=cut

sub muse_body  {
    my $self = shift;
    return $self->_read_muse_body($self->f_full_path_name);
}

sub starting_file_body {
    my $self = shift;
    return $self->_read_muse_body($self->starting_file);
}

sub muse_header {
    my $self = shift;
    my $header = eval { muse_fast_scan_header($self->f_full_path_name) };
    return $header || {};
}

sub is_deferred {
    my $self = shift;
    if (my $str = $self->muse_header->{pubdate}) {
        my $epoch = eval { str2time($str); };
        if ($epoch and $epoch > DateTime->now->epoch) {
            return DateTime->from_epoch(epoch => $epoch)->ymd;
        }
    }
    return;
}

sub deferred_pubdate {
    return shift->is_deferred || '';
}

sub is_deletion {
    return shift->muse_header->{DELETED} || '';
}


sub _read_muse_body {
    my ($self, $file) = @_;
    die "Bad usage" unless $file;
    return '' unless -f $file;
    my $body = read_file($file);
    return $body;
}

sub muse_doc {
    my $self = shift;
    my $file = $self->f_full_path_name;
    return '' unless -f $file;
    my $doc = Text::Amuse->new(file => $file);
    return $doc;
}

sub file_parsing {
    my ($self, $type) = @_;
    my ($name, $path, $suffix) = fileparse($self->f_full_path_name, qr{\.muse});
    if ($type eq 'dir') {
        return $path;
    }
    elsif ($type eq 'name') {
        return $name;
    }
}

sub muse_uri {
    return shift->file_parsing('name');
}

sub working_dir {
    my $self = shift;
    die "WTF?" unless $self->id;
    return File::Spec->catfile($self->site->staging_dir, $self->id);
}

=head2 private files

They have an underscore, so they are invalid files for use and avoid clashes.
They are pretty much internals

=over 4

=item starting_file

=item original_html

=item temporary_file

Temporary file

=item aux_file

Auxiliary file

=item git_msg_file

File for commit message

=back

=cut

sub starting_file {
    my $self = shift;
    return File::Spec->catfile($self->working_dir, 'private_orig.muse');
}

sub original_html {
    my $self = shift;
    return File::Spec->catfile($self->working_dir, 'private_orig.html');
}

sub temporary_file {
    my $self = shift;
    return File::Spec->catfile($self->working_dir, 'private_tmp.muse');
}

sub aux_file {
    my $self = shift;
    return File::Spec->catfile($self->working_dir, 'private_aux.muse');
}

sub git_msg_file {
    my $self = shift;
    return File::Spec->catfile($self->working_dir, 'private_git_msg.muse');
}

sub _write_commit_file {
    my ($self, $title) = @_;
    die "Bad usage" unless $title;
    my $file = $self->git_msg_file;
    write_file($file, "$title\n");
    if (my $body = $self->message) {
        # if by chance we pulled in ^M and \0, unclear if it happens
        # or git clear that up for us. Anyway, will not do any harm.
        # Hopefully.
        $body =~ s/[\0\r]//gs;
        append_file($file, "\n$body\n");
    }
    return $file;
}

=head2 attached_files

Return an array reference to the list of attached basenames.

=cut

sub attached_files {
    my $self = shift;
    my @files;
    my $dir = $self->working_dir;
    opendir(my $dh, $dir) || die "can't opendir $dir: $!";
    # we know only about pdf, jpeg, png
    @files = grep { /\w\.(pdf|jpe?g|png)$/ && -f File::Spec->catfile($dir, $_) }
      readdir($dh);
    closedir $dh;
    return \@files;
}

sub attached_images {
    my $self = shift;
    my @images;
    foreach my $i (@{ $self->attached_files }) {
        if ($i =~ m/\.pdf$/) {
            next;
        }
        else {
            push @images, $i;
        }
    }
    return \@images;
}

sub attached_pdfs {
    my $self = shift;
    my @pdfs;
    foreach my $i (@{ $self->attached_files }) {
        if ($i =~ m/\.pdf$/) {
            push @pdfs, $i;
        }
    }
    return \@pdfs;
}

sub attached_pdfs_string {
    my $self = shift;
    my @pdfs = @{ $self->attached_pdfs };
    if (@pdfs) {
        return "#ATTACH " . join(" ", @pdfs);
    }
    else {
        return '';
    }
}

sub attached_file_path {
    my ($self, $name) = @_;
    return unless $name;
    my $path = File::Spec->catfile($self->working_dir, $name);
    return unless -f $path;
    return $path;
}

=head2 attached_files_paths

Return a list of absolute path to the attached files.

=cut


sub attached_files_paths {
    my $self = shift;
    my @paths;
    foreach my $file (@{$self->attached_files}) {
        my $path = $self->attached_file_path($file);
        push @paths, $path if $path;
    }
    return @paths;
}


=head2 edit(\$string)

Edit the current revision. It's reccomended to pass a reference to a
scalar or an hashref with the string in the "body" key to avoid large
copying, but a scalar will do the same.

Return the error, if any.

=cut

sub edit {
    my ($self, $string) = @_;
    die "Missing argument" unless $string;

    my $target   = $self->f_full_path_name;
    my $original = $self->starting_file;
    my $temp     = $self->temporary_file;
    my $aux      = $self->aux_file;
    # check if we have the main file
    die "Can't edit a non-existent file!" unless -f $target;

    # assert that we have the starting point file
    unless (-f $original) {
        copy($target, $original) or die "Couldn't copy $target to $original $!";
    }

    my $is_ref = ref($string);

    # before overwriting, we do some mambo-jumbo to strip out \r

    # save the parameter in the temporary file
    open (my $fh, '>:encoding(utf-8)', $temp) or die "Fail to open $temp $!";
    if ($is_ref eq 'SCALAR') {
        print $fh $$string;
    }
    elsif ($is_ref eq 'HASH' and exists $string->{body}) {
        print $fh $string->{body};
    }
    elsif (!$is_ref) {
        print $fh $string;
    }
    else {
        die "Failed to write string, bad usage!";
    }
    close $fh or die "Fail to close $temp $!";

    my %ppargs = (
                  input => $temp,
                  output => $aux,
                 );

    if ($is_ref and $is_ref eq 'HASH') {
        foreach my $k (qw/fix_links fix_typography
                          fix_nbsp remove_nbsp
                          fix_footnotes/) {
            $ppargs{$k} = $string->{$k};
        }
    }
    my $pp = Text::Amuse::Preprocessor->new(%ppargs);
    if ($pp->process) {
        move($aux, $target) or die "Couldn't move $aux to $target";
        # finally move it to the target file
        # and update
        $self->status('editing');
        $self->updated(DateTime->now);
        $self->update;
        return;
    }
    elsif (my $error = $pp->error) {
        return $error;
    }
    else {
        die "This shouldn't happen: process returned false, but no error set\n";
    }
}

=head2 commit_version($message);

When this method is called, update the revision's status to "pending"
and set the message.

=cut

sub commit_version {
    my ($self, $message, $username) = @_;
    $message ||= "No message provided!";
    $self->message($message);
    $self->status('pending');
    $self->username(clean_username($username));
    $self->update;
}


=head2 add_attachment($filename)

Given the filename as first argument, copy it into the working
directory, taking care of not overwrite anything. Return an hashref
with two optional keys: C<error>, when the upload failed,
C<attachment> with the name of the newly created uri if succeeded.

if (my $error = $revision->add_attachment($file)->{error}) {
   return $c->loc(@$error);
}

=cut

sub add_attachment {
    my ($self, $filename) = @_;
    die "Missing argument" unless $filename;
    my $base = muse_attachment_basename_for($self->muse_uri);
    return $self->site->create_attachment($filename, $self->working_dir, $base);
}

=head2 destination_paths

Return an hash (not an hashref) where the keys are the existing files
in the staging directory, while the values are the absolute paths to
the future location of the same files (so you can copy the key to the
value).

=cut


sub destination_paths {
    my $self = shift;
    my $target_dir;
    my $f_class = $self->f_class;
    my $muse_uri = $self->muse_uri;
    if ($f_class eq 'text') {
        $target_dir = $self->site->path_for_file($muse_uri);
    }
    elsif ($f_class eq 'special')  {
        $target_dir = $self->site->path_for_specials;
    }
    my $pdf_dir = $self->site->path_for_uploads;
    die "<$target_dir> for $muse_uri is not a dir" unless $target_dir && -d $target_dir;
    die "pdf <$pdf_dir> is not a dir" unless $pdf_dir && -d $pdf_dir;
    my %dests;
    foreach my $file ($self->f_full_path_name, $self->attached_files_paths) {
        my ($basename, $path, $suffix) = fileparse($file, qr{\.pdf});
        if ($suffix) {
            $dests{$file} = File::Spec->catfile($pdf_dir, $basename . $suffix);
        }
        else {
            $dests{$file} = File::Spec->catfile($target_dir, $basename);
        }
    }
    return %dests;
}

=head1 STATUSES

The C<status> column determines the status of a revision. The valid
statuses are:

=over 4

=item editing

The default. The revision has not been committed yet and should be
left alone.

=item pending

The revision has been committed and is ready to be published.

=item published

The revision has been published and can be ignored.

=item processing

The revision has been given to the job server and is under processing.

=item conflict

The revision couldn't be published because couldn't be merged cleanly,
i.e., it would have overwritten some other change.

=back

Each of them are methods you can call and return true when the status
matches. You don't set them directly.

=cut

sub editing {
    shift->status eq 'editing' ? return 1 : return 0;
}

sub pending {
    shift->status eq 'pending' ? return 1 : return 0;
}

sub published {
    shift->status eq 'published' ? return 1 : return 0;
}

sub conflict {
    shift->status eq 'conflict' ? return 1 : return 0;
}

sub processing {
    shift->status eq 'processing' ? return 1 : return 0;
}


=head2 can_be_merged

Calling this method will trigger the SHA1 checksum on the
original_file and the target file. If they don't match, it means that
the revision would overwrite something.

=head2 has_modifications

Return true if the working file and the master copy differ or the
master copy doesn't exist. A new text with just the import will return
true here.

=head2 has_local_modifications

Return true if the revision has seen actual work. A new text with just
the import will return false here.

=cut

sub _shasums_are_equal {
    my ($self, $src, $dst) = @_;
    die "Missing source and destination" unless ($src && $dst);
    die "$src is not a file" unless -f $src;
    die "$dst is not a file" unless -f $dst;
    my $src_sha = Digest::SHA->new('SHA-1')->addfile($src);
    my $dst_sha = Digest::SHA->new('SHA-1')->addfile($dst);
    return $src_sha->hexdigest eq $dst_sha->hexdigest;
}

sub can_be_merged {
    my $self = shift;

    my $destination = $self->title->f_full_path_name;
    my $source = $self->starting_file;

    # will not merge, source doesn't exists, strange enough
    die "No starting file, this is a bug"  unless ($source and -f $source);

    if ($destination and -f $destination) {
        return $self->_shasums_are_equal($source, $destination);
    }
    else {
        # no destination? nothing to do, will merge cleanly
        return 1;
    }
}

sub has_modifications {
    my $self = shift;
    my $destination = $self->title->f_full_path_name;
    my $source = $self->f_full_path_name;
    die "Revision without muse, this is a bug"  unless ($source and -f $source);
    if ($destination and -f $destination) {
        # differ? then there are modifications
        return !$self->_shasums_are_equal($source, $destination);
    }
    else {
        # no destination? The text has modifications.
        return 1;
    }
}

sub has_local_modifications {
    my $self = shift;
    my $source = $self->starting_file;
    my $destination = $self->f_full_path_name;
    return !$self->_shasums_are_equal($source, $destination);
}

=head2 editing_ongoing

Check if the revision is being actively edited and permit the hijaking
of abandoned one. Lock time is 60 minutes.

=cut

sub editing_ongoing {
    my $self = shift;
    return unless $self->editing;
    log_debug { "Revision " . $self->id . " was updated on " . $self->updated };
    if (((time() - $self->updated->epoch) / 60) < 60) {
        return 1;
    }
    else {
        return;
    }
}

=head2 publish_text

Procedure:

=over 4

=item check if the status is pending

=item carefully move it in the target directory

=item if in a git directory, add it to the git and commit

=item call $site->compile_and_index_files on the muse and the attachments

=item return $self->title->full_uri

=back

=cut

sub publish_text {
    my ($self, $logger) = @_;
    unless ($self->pending) {
        if ($logger) {
            $logger->("Revision " .  $self->id . " has status " . $self->status .
                      ": can't proceed");
        }
        return;
    }
    my %files = $self->destination_paths;

    # catch the muse files and its attachments, and validate it.
    my $muse;
    my @attachments;
    foreach my $src (keys %files) {
        my $target = $files{$src};
        if ($target =~ m/\.muse$/) {
            die "Multiple muse files found in " . $self->id if $muse;
            $muse = $target;
        }
        else {
            push @attachments, $target;
        }
    }
    # first process the muse file
    die "muse file not found in " . $self->id unless $muse;

    local $ENV{GIT_AUTHOR_NAME}  = $self->author_name;
    local $ENV{GIT_AUTHOR_EMAIL} = $self->author_mail;

    my $git = $self->site->git;
    my $revid = $self->id;
    my $full_uri = $self->title->full_uri;
    my $commit_msg_file = $self->git_msg_file;
    if ($git and -f $self->original_html) {
        die "Original html found, but target exists" if -f $muse;

        copy ($self->original_html, $muse) or die $!;
        $git->add($muse);

        $self->_write_commit_file('HTML: ' . $full_uri . ' #' . $revid);
        $git->commit({ file => $commit_msg_file });

        die "starting muse revision not found!" unless -f $self->starting_file;
        copy ($self->starting_file, $muse) or die $!;

        $git->add($muse);
        # this means that the publishing was forced or is a new file
        if ($git->status->get('indexed')) {
            $self->_write_commit_file('Edit: ' . $full_uri . ' #' . $revid);
            $git->commit({ file => $commit_msg_file });
        }
    }

    foreach my $k (keys %files) {
        my $dest = $files{$k};
        if ($dest ne $muse) {
            # this shouldn't happen
            die "Attachment already exists" if -f $dest;
        }
        copy($k, $dest) or die "Couldn't copy $k to $dest $!";

        if ($git) {
            $git->add($dest);
        }
    }

    if ($git) {
        if ($git->status->get('indexed')) {
            # could be very well already been stored above
            $self->_write_commit_file('Published: ' . $full_uri . ' #' . $revid);
            $git->commit({ file => $commit_msg_file });
        }
    }
    $self->site->compile_and_index_files([ values %files ], $logger);
    # assert to have an up-to-date title object
    $self->title->discard_changes;
    $self->status('published');
    $self->update;
    return $full_uri;
}

sub f_class {
    my $self = shift;
    return $self->title->f_class;
}

=head1 METHOD MODIFIERS

Delete method is overloaded to check if the title would become orphan
and can't spawn further revisions.

=cut


sub delete {
    my $self = shift;
    my $title = $self->title;
    # cleanup the db from the attached files we are going to delete
    # and remove the tree
    my $site = $self->site;
    foreach my $file ($self->attached_files_paths) {
        if (my $att_row = $site->attachments->find_file($file)) {
            log_info { "Deleting $file from db" };
            $att_row->delete;
        }
    }
    $self->purge_working_tree;

    if ($title->can_spawn_revision) {
        return $self->next::method;
    }
    else {
        # this will bring down this row with it
        log_info { "Purging " . $title->uri . " from db" };
        return $title->delete;
    }
}

sub purge_working_tree {
    my $self = shift;
    my $working_tree = $self->working_dir;
    if (-d $working_tree) {
        opendir(my $dh, $working_tree) or die "Can't opendir $working_tree: $!";
        my @files = grep { /^\w/ } readdir($dh);
        closedir $dh;
        foreach my $file (@files) {
            my $path = File::Spec->catfile($working_tree, $file);
            if (-f $path) {
                log_info { "Removing $path" };
                unlink $path or log_warn { "Couldn't unlink $path $!" };
            }
            else {
                log_warn { "Found strange file in $working_tree: $path" };
            }
        }
        log_info {  "Removing $working_tree" };
        rmdir $working_tree or warn "Error removing $working_tree: $!";
    }
    else {
        log_fatal { "$working_tree is not a directory!" };
    }
}

=head2 is_new_text

Return true if the text is a new addition or not. This maps to
$self->title->muse_file_exists_in_tree.

=cut

sub is_new_text {
    my $self = shift;
    return !$self->title->muse_file_exists_in_tree;
}

# same as Result::Job
sub author_username {
    my $self = shift;
    return clean_username($self->username);
}
sub author_name {
    my $self = shift;
    return ucfirst($self->author_username);
}
sub author_mail {
    my $self = shift;
    my $hostname = 'localhost';
    if (my $site = $self->site) {
        $hostname = $site->canonical;
    }
    return $self->author_username . '@' . $hostname;
}

sub document_html_headers {
    my $self = shift;
    my $header = $self->muse_doc->header_as_html;
    Dlog_debug { "Header is $_" } $header;
    if ($header->{cover}) {
        unless ($header->{cover} =~ m/\A[0-9a-z]+([0-9a-z-][0-9a-z]+)*\.(jpe?g|png)\z/) {
            $header->{cover} = 'file_not_found.png';
        }
    }
    return $header;
}

__PACKAGE__->meta->make_immutable;
1;
