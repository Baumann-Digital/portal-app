xquery version "3.1";

module namespace baudiLocus="http://baumann-digital.de/ns/baudiLocus";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace http="http://expath.org/ns/http-client";

import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";
import module namespace baudiPersons="http://baumann-digital.de/ns/baudiPersons" at "/db/apps/baudiApp/modules/baudiPersons.xqm";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace request="http://exist-db.org/xquery/request";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";

import module namespace i18n="http://exist-db.org/xquery/i18n" at "/db/apps/baudiApp/modules/i18n.xql";


declare function baudiLocus:getOpenStreetMap($id as xs:string) {
    let $locus := $app:collectionLoci/id($id)
    let $geonamesID := $locus//tei:idno[@type="geonames"]/text()
    let $geonamesURL := concat('https://sws.geonames.org/', $geonamesID, '/about.rdf')
    let $request := <http:request href="{$geonamesURL}" method="get" timeout="3"><http:header name="Connection" value="close"/></http:request>
    let $response := http:send-request($request)
    let $geoCoord1 := if($geonamesID != '') then($response//*:lat/text()) else(substring-before($locus//tei:geo/text(), ' '))
    let $geoCoord2 := if($geonamesID != '') then($response//*:long/text()) else(substring-after($locus//tei:geo/text(), ' '))
    
    let $mapOSM := <div class="row">
                       <div id="Map" class="col" style="height:350px; max-width: 450px"></div>
                       <script src="$resources/js/OpenLayers-2.13.1/OpenLayers.js"></script>
                       <script>
                           var lat = {$geoCoord1};
                           var lon = {$geoCoord2};
                           var zoom = 13;
                       
                           var fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
                           var toProjection   = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection 900913
                           var position       = new OpenLayers.LonLat(lon, lat).transform( fromProjection, toProjection);
                       
                           map = new OpenLayers.Map("Map");
                           var mapnik         = new OpenLayers.Layer.OSM();
                           map.addLayer(mapnik);
                       
                           var markers = new OpenLayers.Layer.Markers( "Markers" );
                           map.addLayer(markers);
                           markers.addMarker(new OpenLayers.Marker(position));
                       
                           map.setCenter(position, zoom);
                       </script>
                      </div>
    return
        if($geoCoord1 and $geoCoord2)
        then($mapOSM)
        else()
};

declare function baudiLocus:getLocusName($locusID as xs:string) {
    let $locus := $app:collectionLoci/id($locusID)
    let $locusName := $locus/tei:placeName[1]/text()
    return
        $locusName
};
