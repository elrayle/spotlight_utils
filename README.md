## Overview

These scripts are designed to be used with (spotlight)[https://github.com/projectblacklight/spotlight] exhibit app.
These scripts provide the ability to explore the database tables and to clean up data.

*WARNING: The scripts that delete table entries can NOT be undone.  Use with extreme caution!!!*
If you are not 100% sure what these scripts do and that you need to delete database entries this way, then do not use these scripts.

## Installation

Copy files from `scripts/*.rb` to the `scripts` directory of your spotlight exhibit app.

## Usage

### Load all scripts

```
Load in `bundle exec rails c`
load 'scripts/exhibit_service.rb'
load 'scripts/thumbnail_service.rb'
load 'scripts/featured_image_delete_service.rb'
load 'scripts/resource_delete_service.rb'
```

### Process for deleting an exhibit
    
* run in rails c:
 
```
# Explore whether it is safe to delete the exhibit.
 
load 'scripts/exhibit_service.rb'
ExhibitService.database_entries _ID_  # replace _ID_ with exhibit id number
 
# confirm that there aren't any ALT resources or ALT sidecars
# ok to delete with ALT sidecars, but not with ALT resources
# maybe should explore both further before deciding to delete
```

* navigate to exhibit dashboard → General → Delete Exhibit → Delete this exhibit → OK

* run in rails c:
 
``` 
# Resources are NOT deleted by the exhibit delete process through the UI.  This will show the residual resources.
 
load 'scripts/exhibit_service.rb'
ExhibitService.database_entries _ID_  # replace _ID_ with exhibit id number
 
# Confirm only resources and related featured images are listed.
 
load 'scripts/resource_delete_service.rb'
ids = ResourceDeleteService.find_resources_for_exhibit(exhibit: _ID_)  # replace _ID_ with exhibit id number
ResourceDeleteService.delete_resources(ids)
 
# Safe to delete:
#   * resource with no other related objects
#   * resource with only a featured image that has no ALT resources
#   * resource with ALT sidecars -- most likely - perhaps need to explore further
 
 
# Run again...
ExhibitService.database_entries _ID_  # replace _ID_ with exhibit id number
 
# Confirm there are no database entries related to the exhibit
```

### Explore intertwined database entries within an exhibit

```
ExhibitService.database_entries(_ID_)
```
where _ID_ is the id of the exhibit you want to explore

This will list...

* resources
* solr_document_sidecars
* searches
* filters
* main_navigations
* page
* attachments
* blacklight_configurations
* contact_emails
* contacts
* custom_fields
* reindexing_log_entries

Things to watch for...  search results for ALT which will show

* resources (in or out of the exhibit under investigation) that point to a featured_image in this exhibit (There should be a one-to-one relationship between a resource and a featured_image through resource.upload_id.)
* solr_document_sidecars that are referenced from multiple resources

### Delete featured_images with image==null

#### Find with
```
ids = FeaturedImageDeleteService.find_null_images
```

#### Repair process

Deletes...

* featured_images where id is in ids list
* the binary image file for the featured image being deleted
* thumbnail featured_images that are based on the featured image being deleted
* resources that have upload_id == featured_image.id
* solr_document_sidecars for each resource
* bookmarks for each resource

``` 
ids = FeaturedImageDeleteService.find_null_images
FeaturedImageDeleteService.delete_featured_images(ids, auto_delete: true)
```
auto_delete will delete anything with:  0 thumbnails and 0 resources and featured_image type is nil

#### Decision points

* Don't delete if there are any thumbnails that use the image UNTIL you confirm the thumbnails are also not in use
* May not want to delete images with a type other than NULL (e.g. Spotlight::Masthead, Spotlight::ExhibitThumbnail, Spotlight::ContactImage, etc.)
* Use caution if there are resources that reference the featured_image to be deleted
* Use even more caution if there are solr_document_sidecars and/or bookmarks that are related to a resource that refers to the featured image

### Finding related thumbnails that refer to a featured_image with image==null

#### Find with

Will be listed with its base featured_image (the image from which the thumbnail was created) when calling...

```
ids = FeaturedImageDeleteService.find_null_images
```
OR
```
FeaturedImageDeleteService.delete_featured_image(_BASE_ID_, pretest: true)
```
where _BASE_ID_ is the base feature image id from which the thumbnail was created

#### Repair process

You can use the same script to delete a thumbnail as for an uploaded featured image

```
FeaturedImageDeleteService.delete_featured_image(_THUMBNAIL_ID_)
```
where _THUMBNAIL_ID_ is the id in the spotlight_featured_images table of the thumbnail to be deleted

### To find thumbnails whose original source was deleted...

``` 
select id, iiif_tilesource from spotlight_featured_images where iiif_tilesource LIKE '%/images/%/info.json';
```

As an example, for image 1728...

* Thumbnails will have iiif_tilesource in format:   http://localhost:3000/images/1728/info.json
* Look for original source in same result set with id=1728

### Delete resources with upload_id==null

#### Find with

```
ids = ResourceDeleteService.find_null_images
```

#### Repair process

Deletes...

* resource where id is in ids list
* featured_image where id=resource.upload_id
* the binary image file for the featured image being deleted
* thumbnail featured_images that are based on the featured image being deleted
* solr_document_sidecars for the resource being deleted
* bookmarks for the resource being deleted

```
ids = ResourceDeleteService.find_null_images
ResourceDeleteService.delete_resources(ids)
```
 
#### Decision points

* Use caution in deleting a resource with other parts associated with it
* Don't delete if there are any thumbnails that use the image UNTIL you confirm the thumbnails are also not in use
* May not want to delete featured images with a type other than NULL (e.g. Spotlight::Masthead, Spotlight::ExhibitThumbnail, Spotlight::ContactImage, etc.)

