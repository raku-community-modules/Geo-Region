[![Actions Status](https://github.com/raku-community-modules/Geo-Region/actions/workflows/linux.yml/badge.svg)](https://github.com/raku-community-modules/Geo-Region/actions) [![Actions Status](https://github.com/raku-community-modules/Geo-Region/actions/workflows/macos.yml/badge.svg)](https://github.com/raku-community-modules/Geo-Region/actions) [![Actions Status](https://github.com/raku-community-modules/Geo-Region/actions/workflows/windows.yml/badge.svg)](https://github.com/raku-community-modules/Geo-Region/actions)

NAME
====

Geo::Region - Geographical regions and groupings using UN M.49 and CLDR data

VERSION
=======

This document describes Geo::Region for Raku, built with Unicode CLDR v26.

SYNOPSIS
========

```raku
use Geo::Region;
use Geo::Region::Enum;

$amer = Geo::Region.new(include => Region::Americas);

$emea = Geo::Region.new(
    include => (Region::Europe, Region::WesternAsia, Region::Africa)
);

$apac = Geo::Region.new(
    include => (Region::Asia, Region::Oceania),
    exclude => Region::WesternAsia,
);

if $amer.contains($country) {
    # country is in the Americas (US, MX, BR, etc.)
}
elsif $emea.contains($country) {
    # country is in Europe, the Middle East, and Africa (FR, SA, ZW, etc.)
}
elsif $apac.contains($country) {
    # country is in Asia-Pacific (JP, TH, AU, etc.)
}
```

DESCRIPTION
===========

The `Geo::Region` class is used to create geographical regions and groupings of subregions and countries. Default regional groupings are provided using the [Unicode CLDR v26 Territory Containment](https://unicode.org/cldr/charts/26/supplemental/territory_containment_un_m_49.html) data, which is an extension of the United Nations [UN M.49 (Rev.3)](https://unstats.un.org/unsd/methods/m49/m49regin.htm) standard.

Regions
-------

Regions and subregions are represented with UN M.49 region codes, such as **419** for Latin America and **035** for Southeast Asia. Either the official format using a three-digit `0`-padded string like `'035'` or an integer like `35` may be used with this class. Note when using the `0`-padded format that it must be quoted as a string so as not to be treated as on octal literal.

The CLDR also adds two additional two-letter region codes which are supported: **EU** for the European Union and **QO** for Outlying Oceania. These region codes are all available as enumerations in [Geo::Region::Enum](Geo::Region::Enum).

Countries
---------

Countries and territories are represented with ISO 3166-1 alpha-2 country codes, such as **JP** for Japan and **AQ** for Antarctica, and are case insensitive. Unlike with region codes, the three-digit forms of country codes are not currently supported, nor are three-letter codes. The deprecated code **UK** for the United Kingdom is supported as an alias of the official code **GB**.

Constructor
-----------

The `new` class method is used to construct a Geo::Region object along with the `include` argument and optional `exclude` argument.

### include

Accepts either a single region code or an array reference of region or country codes to be included in the resulting custom region.

```raku
# countries in the European Union (EU)
Geo::Region.new(include => Region::EuropeanUnion);

# countries in Asia (142) plus Russia (RU)
Geo::Region.new(include => (Region::Asia, Country::Russia));
```

### exclude

Accepts values in the same format as `include`. This can be used to exclude countries or subregions from a region.

```raku
# countries in Europe (150) which are not in the European Union (EU)
Geo::Region.new(
  include => Region::Europe,
  exclude => Region::EuropeanUnion,
);
```

Methods
-------

### contains

Given a country or region code, determines if the region represented by the Geo::Region instance contains it.

```raku
if $region.contains($country) {
```

### is-within

Given a region code, determines if all the countries and regions represented by the Geo::Region instance are within it.

```raku
if $subregion.is-within($region) {
```

### countries

Returns a list of country codes of the countries within the region represented by the Geo::Region instance.

```raku
for $region.countries -> $country {
```

SEE ALSO
========

  * [Unicode CLDR: UN M.49 Territory Containment](http://unicode.org/cldr/charts/26/supplemental/territory_containment_un_m_49.html)

  * [United Nations: UN M.49 Standard Country, Area, & Region Codes](http://unstats.un.org/unsd/methods/m49/m49regin.htm)

AUTHOR
======

Nova Patch

COPYRIGHT AND LICENSE
=====================

Copyright 2014 - 2018 Nova Patch

Copyright 2024 Raku Community

This library is free software; you can redistribute it and/or modify it under the same terms as Raku itself.

