-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/31/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/32/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE gallery (
  gallery_id INTEGER PRIMARY KEY NOT NULL,
  site_id varchar(16) NOT NULL,
  title varchar(255) NOT NULL,
  gallery_uri varchar(255) NOT NULL,
  muse_desc text,
  html_desc text,
  last_modified datetime,
  FOREIGN KEY (site_id) REFERENCES site(id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX gallery_idx_site_id ON gallery (site_id);

;
CREATE UNIQUE INDEX gallery_uri_site_id_unique ON gallery (gallery_uri, site_id);

;
CREATE TABLE gallery_attachment (
  gallery_id integer NOT NULL,
  attachment_id integer NOT NULL,
  PRIMARY KEY (gallery_id, attachment_id),
  FOREIGN KEY (attachment_id) REFERENCES attachment(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (gallery_id) REFERENCES gallery(gallery_id) ON DELETE CASCADE ON UPDATE CASCADE
);

;
CREATE INDEX gallery_attachment_idx_attachment_id ON gallery_attachment (attachment_id);

;
CREATE INDEX gallery_attachment_idx_gallery_id ON gallery_attachment (gallery_id);

;
ALTER TABLE attachment ADD COLUMN title varchar(255);

;
ALTER TABLE attachment ADD COLUMN muse_desc text;

;
ALTER TABLE attachment ADD COLUMN html_desc text;

;

COMMIT;

