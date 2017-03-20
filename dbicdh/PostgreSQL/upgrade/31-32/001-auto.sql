-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/31/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/32/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "gallery" (
  "gallery_id" serial NOT NULL,
  "site_id" character varying(16) NOT NULL,
  "title" character varying(255) NOT NULL,
  "gallery_uri" character varying(255) NOT NULL,
  "muse_desc" text,
  "html_desc" text,
  "last_modified" timestamp,
  PRIMARY KEY ("gallery_id"),
  CONSTRAINT "gallery_uri_site_id_unique" UNIQUE ("gallery_uri", "site_id")
);
CREATE INDEX "gallery_idx_site_id" on "gallery" ("site_id");

;
CREATE TABLE "gallery_attachment" (
  "gallery_id" integer NOT NULL,
  "attachment_id" integer NOT NULL,
  PRIMARY KEY ("gallery_id", "attachment_id")
);
CREATE INDEX "gallery_attachment_idx_attachment_id" on "gallery_attachment" ("attachment_id");
CREATE INDEX "gallery_attachment_idx_gallery_id" on "gallery_attachment" ("gallery_id");

;
ALTER TABLE "gallery" ADD CONSTRAINT "gallery_fk_site_id" FOREIGN KEY ("site_id")
  REFERENCES "site" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "gallery_attachment" ADD CONSTRAINT "gallery_attachment_fk_attachment_id" FOREIGN KEY ("attachment_id")
  REFERENCES "attachment" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "gallery_attachment" ADD CONSTRAINT "gallery_attachment_fk_gallery_id" FOREIGN KEY ("gallery_id")
  REFERENCES "gallery" ("gallery_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE attachment ADD COLUMN title character varying(255);

;
ALTER TABLE attachment ADD COLUMN muse_desc text;

;
ALTER TABLE attachment ADD COLUMN html_desc text;

;

COMMIT;

