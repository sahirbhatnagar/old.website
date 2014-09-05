
<!-- saved from url=(0077)https://raw.githubusercontent.com/aijaz/photoBlog/master/generatePhotoPost.pl -->
<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><style type="text/css"></style></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">#!/usr/bin/perl

use strict;
use warnings;

=head1 SYNOPSIS

 generatePhotoPost.pl --image i.jpg --thumbnail t.jpg --histogram h.jpg --title "Title" --tag Tag1 --tag Tag2 --date YYYYMMDDhhmm

 This script creates a directory, if necessary, based on the current
 date, or YYYYMMDDhhmm, if specified. 

 The script will then extract the EXIF information from the image file
 i.jpg.  It will also extract size information from the image,
 thumbnail and histogram files.

 It will then create the YAML preamble for the blog post.  If the blog
 post already exists, it will combine the new YAML preamble with the
 old contents and save that to the blog post file.  If the blog post
 does not already exist, it will be created in the proper place with a
 complete YAML preamble and empty contents.

=cut    


use Data::Dumper;
use Getopt::Long;
use Image::ExifTool qw(:Public);
use File::Basename;
use File::Path qw (make_path);
use File::Copy;

my $creator = "Aijaz Ansari";

my $file;
my $image;
my $title;
my @tags;
my $date;
my $thumbnail;
my $histogram;
my $exif_h;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$mon++;
$year += 1900;
my $specifiedDate = undef;


Getopt::Long::GetOptions(
    "image=s"     =&gt; \$image,
    "thumbnail=s" =&gt; \$thumbnail,
    "histogram=s" =&gt; \$histogram,
    "title=s"     =&gt; \$title,
    "tag=s"       =&gt; \@tags,
    "date=s"      =&gt; \$specifiedDate,
    );

# Convert spaces in the title to dashes
my $fileTitle = lc($title);
$fileTitle    =~ s/\s+/-/g;
$fileTitle    =~ s/^\-//;
$fileTitle    =~ s/\-$//;

if ($specifiedDate) {
    ($year, $mon, $mday, $hour, $min) = $specifiedDate =~ /(....)(..)(..)(..)(..)/;
}

# This is the location of your octopress blog.
my $dir = sprintf("/Users/aijaz/octopress/source/_posts/%d/%02d", $year, $mon);
print "Directory: $dir\n";

if (! -e $dir) {
    print "Making directory\n";
    make_path($dir);
}
elsif (! -d $dir) {
    die "ERROR: $dir is a file.  It needs to be a directory.";
}

my $fileName = sprintf("$dir/%d-%02d-%02d-%s.markdown", $year, $mon, $mday, $fileTitle);
print "fileName: $fileName\n\n";

# Get exif info from image
my $exif = ImageInfo($image);

# use a default thumbnail filename if one hasn't been provided
unless ($thumbnail) {
    $thumbnail = $image;
    $thumbnail =~ s/\./T./;
}

my $postDate = sprintf("%d-%02d-%02d %02d:%02d", $year, $mon, $mday, $hour, $min);

my $imageUrl = $image;
$imageUrl =~ s/.*source//;

my %hash = ();

# Get info for the thumbnail
if ($thumbnail) {
    my $thumbnailUrl = $thumbnail;
    $thumbnailUrl =~ s/.*source//;
    $hash{thumbnail} = $thumbnailUrl;
    my $img_info         = `identify $thumbnail`;
    my @info_list        = split(/ /, $img_info);
    ($hash{thumbnailWidth}, $hash{thumbnailHeight}) = $info_list[2] =~ /(\d+)x(\d+)/;
}

# Get info for the histogram
if ($histogram) {
    my $histogramUrl = $histogram;
    $histogramUrl =~ s/.*source//;
    $hash{histogram} = $histogramUrl;
    my $img_info         = `identify $histogram`;
    my @info_list        = split(/ /, $img_info);
    ($hash{histogramWidth}, $hash{histogramHeight}) = $info_list[2] =~ /(\d+)x(\d+)/;
}

# Get info for the image
my $img_info         = `identify $image`;
my @info_list        = split(/ /, $img_info);
($hash{photoWidth}, $hash{photoHeight}) = $info_list[2] =~ /(\d+)x(\d+)/;


my $tags = "";
if (@tags) {
    $hash{tags} = join("\n",
                         "",
                         (map { "- $_" } @tags)
        );
}


# Create the YAML text
print "Writing to $fileName.temp\n";
open (F, "&gt;$fileName.temp") || die "Cannot open $fileName.temp for writing";
print F join("\n",
             "---",
             "layout: photo",
             "title: \"$title\"",
             "date: $postDate",
             "comments: false",
             "categories:",
             "- Photos",
             "author: Aijaz Ansari",
             "image: $imageUrl",
             "",
    );

#print Dumper (keys %$exif);

if ($exif-&gt;{ISO}) { $hash{iso} = $exif-&gt;{ISO}; }
if ($exif-&gt;{Aperture}) { $hash{aperture} = $exif-&gt;{Aperture}; }
if ($exif-&gt;{"ShutterSpeed"}) { $hash{shutterSpeed} = $exif-&gt;{"ShutterSpeed"}; }
if ($exif-&gt;{"FocalLength"}) { $hash{focalLength} = $exif-&gt;{"FocalLength"}; }
if ($exif-&gt;{"ScaleFactor35efl"}) { $hash{scaleFactor} = $exif-&gt;{"ScaleFactor35efl"}; }
if ($exif-&gt;{"Flash"}) { $hash{flash} = $exif-&gt;{"Flash"}; }
if ($exif-&gt;{"ExposureCompensation"}) { $hash{expComp} = $exif-&gt;{"ExposureCompensation"}; }
if ($exif-&gt;{"Model"}) { $hash{camera} = $exif-&gt;{"Model"}; }
if ($exif-&gt;{"LensID"}) { $hash{lens} = $exif-&gt;{"LensID"}; }
elsif ($exif-&gt;{"LensInfo"}) { $hash{lens} = $exif-&gt;{"LensInfo"}; }
elsif ($exif-&gt;{"LensModel"}) { $hash{lens} = $exif-&gt;{"LensModel"}; }
elsif ($exif-&gt;{"Lens"}) { $hash{lens} = $exif-&gt;{"Lens"}; }
if ($exif-&gt;{"Creator"}) { $hash{creator} = $exif-&gt;{"Creator"}; }
if ($exif-&gt;{"DateTimeOriginal"}) { $hash{dateTaken} = $exif-&gt;{"DateTimeOriginal"}; }
elsif ($exif-&gt;{"CreateDate"}) { $hash{dateTaken} = $exif-&gt;{"CreateDate"}; }
elsif ($exif-&gt;{"DateCreated"}) { $hash{dateTaken} = $exif-&gt;{"DateCreated"}; }
if ($exif-&gt;{"Copyright"}) { $hash{copyright} = $exif-&gt;{"Copyright"}; }
elsif ($exif-&gt;{"CopyrightNotice"}) { $hash{copyright} = $exif-&gt;{"CopyrightNotice"}; }

$hash{creator} = $creator unless $hash{creator};
if ($hash{lens}) {
    $hash{lens} = '"'.$hash{lens}.'"';
}

my $license = qq^
&lt;a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/deed.en_US"&gt;&lt;img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc-nd/3.0/88x31.png" /&gt;&lt;/a&gt;&lt;br /&gt;&lt;span xmlns:dct="http://purl.org/dc/terms/" href="http://purl.org/dc/dcmitype/StillImage" property="dct:title" rel="dct:type"&gt;$title&lt;/span&gt; by &lt;a xmlns:cc="http://creativecommons.org/ns#" href="{{ site.root }}/$imageUrl" property="cc:attributionName" rel="cc:attributionURL"&gt;$hash{creator}&lt;/a&gt; is licensed under a &lt;a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/deed.en_US"&gt;Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License&lt;/a&gt;.
^;

$hash{license} = qq[&lt;a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/3.0/deed.en_US"&gt;&lt;img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc-nd/3.0/88x31.png" /&gt;&lt;/a&gt;];

foreach my $k (sort keys (%hash) ) {
    print  F "$k: $hash{$k}\n";
}
print F "---\n";

# if the actual file already exists, and if there's any text there,
# print it here, so we don't lose it

if (open (ORIG, "$fileName")) {
    my $numSeen = 0;
    while (&lt;ORIG&gt;) {
        if (/^---\s*$/) {
            $numSeen++;
            if ($numSeen == 2) {
                last;
            }
        }
    }
    while (&lt;ORIG&gt;) {
        print F $_;
    }
    close ORIG;
}

close F;

print "Moving $fileName.temp to $fileName\n";
my $success = move("$fileName.temp", $fileName);
if (! $success) {
    die "Couldn't move temp file \n  $fileName.temp \n  to actual file\n  $fileName\n\n  Actual file may be corrupted. Recover data from temp file now.";
}


</pre></body></html>