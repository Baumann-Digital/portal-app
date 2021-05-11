xquery version "3.1";

module namespace baudiLocus="http://baumann-digital.de/ns/baudiLocus";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace request="http://exist-db.org/xquery/request";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";

import module namespace i18n="http://exist-db.org/xquery/i18n" at "/db/apps/baudiApp/modules/i18n.xql";


declare function baudiLocus:getGeonamesData($locusID as xs:string) {
    let $locus := $app:collectionLoci/id($locusID)
    let $geonameID := $locus//tei:unit/text()
    return
        if($locus)
        then(doc(concat($app:geonames, $geonameID)))
        else()
};

declare function baudiLocus:getLocusName($locusID as xs:string) {
    let $locus := $app:collectionLoci/id($locusID)
    let $locusName := $locus//tei:placeName[1]/text()
    return
        $locusName
};
