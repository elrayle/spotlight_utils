# Recreates the insert statement for a thumbnail that was accidentally deleted.  Requires access to backup database to get
# the original values for the row.
load 'scripts/thumbnail_service.rb'

class RecreateThumbnailService
  class << self
    def create_insert_statements_for_just_featured_image(featured_image_ids)
      inserts = []
      featured_image_ids.each do |fii|
        fi = Spotlight::FeaturedImage.find(fii)
        inserts << "insert into spotlight_featured_images (id, type, display, image, source, document_global_id, image_crop_x, " \
                   "image_crop_y, image_crop_w, image_crop_h, created_at, updated_at, iiif_region, iiif_manifest_url, iiif_canvas_id, " \
                   "iiif_image_id, iiif_tilesource) values(#{strv(fi.id)}, #{strv(fi.type)}, #{strv(fi.display)}, NULL, " \
                   "#{strv(fi.source)}, #{strv(fi.document_global_id)}, #{strv(fi.image_crop_x)}, #{strv(fi.image_crop_y)}, " \
                   "#{strv(fi.image_crop_w)}, #{strv(fi.image_crop_h)}, #{strv(fi.created_at)}, #{strv(fi.updated_at)}, " \
                   "#{strv(fi.iiif_region)}, #{strv(fi.iiif_manifest_url)}, #{strv(fi.iiif_canvas_id)}, #{strv(fi.iiif_image_id)}, " \
                   "#{strv(fi.iiif_tilesource)})"
      end
      inserts
    end

    private

    def strv(value)
      return "NULL" if value.nil?
      "'#{value}'"
    end
  end
end
