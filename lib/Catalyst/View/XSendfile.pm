package Catalyst::View::XSendfile;
use Moose;
use namespace::autoclean;
 
extends 'Catalyst::View';

# use Data::Dumper;
use MIME::Types ();
use File::stat;

# this should load straight away before forking
my $mime_types = MIME::Types->new(only_complete => 1);

# TODO: make this configurable.
# TODO: document it properly.

=head2 nginx configuration:

    location /private/repo/ {
        internal;
        alias /myapp-dir/amw/repo/;
    }
    location /private/staging/ {
        internal;
        alias /myapp-dir/amw/staging/;
    }
	location @proxy {
		access_log /var/log/nginx/library.log hitcount;
#		include proxy_params;
#		proxy_pass http://127.0.0.1:5001;
    	include /etc/nginx/fastcgi_params;
    	fastcgi_param SCRIPT_NAME '';
    	fastcgi_param PATH_INFO   $fastcgi_script_name;
        fastcgi_param HTTP_X_SENDFILE_TYPE X-Accel-Redirect;
        fastcgi_param HTTP_X_ACCEL_MAPPING /myapp-dir/amw=/private;
		fastcgi_pass  unix:/myapp-dir/amw/var/amw.sock;
	}

=cut


my $override = {
                muse => 'text/plain',
                epub => 'application/epub+zip',
               };

# Code here was stolen from Plack::Middleware::ETag and
# Catalyst::Plugin::Static::Simple

sub process {
    my ($self, $c) = @_;
    my $file = $c->stash->{serve_static_file};
    unless ($file and -f $file) {
        $c->log->error("$file is not a file!");
        return;
    }
    # $c->log->debug(Dumper($c->request->headers));
    $c->log->debug("Serving file $file");
    my ($header, $set) = $self->render($c, $file);
    if ($header && $set) {
        $c->response->header($header, $set);
        my $type = $self->_ext_to_type($file);
        $c->response->content_type($type);
        $c->response->body('');
        # set last modified to prevent etag
        $c->response->headers->last_modified(stat($file)->mtime);
        $c->log->debug("Serving $header $set as $type");
    }
    else {
        $c->serve_static_file($file);
    }
}

sub _ext_to_type {
    my ($self, $file) = @_;
    my $type;
    if ($file =~ m/\.(\w+)$/s) {
        my $ext = $1;
        $type = $override->{$ext} || $mime_types->mimeTypeOf($ext);
    }
    $type ? return "$type" : return 'text/plain';
}

sub render {
    my ($self, $c, $path) = @_;
    die "This shouldn't happen" unless $path;

    my $type = $c->request->header('X-Sendfile-Type');

    if ($type && !$c->response->header($type)) {
        if ($type eq 'X-Accel-Redirect') {
            if (my $url = $self->_map_accel_path($c, $path)) {
                return ($type, $url);
            }
        }
        elsif ($type eq 'X-Sendfile' or $type eq 'X-Lighttpd-Send-File') {
            return ($type, $path)
        }
    }
    return;
}
 
sub _map_accel_path {
    my ($self, $c, $path) = @_;
    if (my $mapping = $c->request->header('X-Accel-Mapping')) {
        my($internal, $external) = split /=/, $mapping, 2;
        $c->log->debug("Replacing $internal with $external");
        $path =~ s!^\Q$internal\E!$external!i;
        return $path;
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;
