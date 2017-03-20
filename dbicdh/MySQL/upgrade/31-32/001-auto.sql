-- Convert schema '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/31/001-auto.yml' to '/home/melmoth/amw/AmuseWikiFarm/dbicdh/_source/deploy/32/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `gallery` (
  `gallery_id` integer NOT NULL auto_increment,
  `site_id` varchar(16) NOT NULL,
  `title` varchar(255) NOT NULL,
  `gallery_uri` varchar(255) NOT NULL,
  `muse_desc` text NULL,
  `html_desc` text NULL,
  `last_modified` datetime NULL,
  INDEX `gallery_idx_site_id` (`site_id`),
  PRIMARY KEY (`gallery_id`),
  UNIQUE `gallery_uri_site_id_unique` (`gallery_uri`, `site_id`),
  CONSTRAINT `gallery_fk_site_id` FOREIGN KEY (`site_id`) REFERENCES `site` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
CREATE TABLE `gallery_attachment` (
  `gallery_id` integer NOT NULL,
  `attachment_id` integer NOT NULL,
  INDEX `gallery_attachment_idx_attachment_id` (`attachment_id`),
  INDEX `gallery_attachment_idx_gallery_id` (`gallery_id`),
  PRIMARY KEY (`gallery_id`, `attachment_id`),
  CONSTRAINT `gallery_attachment_fk_attachment_id` FOREIGN KEY (`attachment_id`) REFERENCES `attachment` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `gallery_attachment_fk_gallery_id` FOREIGN KEY (`gallery_id`) REFERENCES `gallery` (`gallery_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE attachment ADD COLUMN title varchar(255) NULL,
                       ADD COLUMN muse_desc text NULL,
                       ADD COLUMN html_desc text NULL;

;

COMMIT;

