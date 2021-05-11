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


declare function baudiLocus:getGoogleMap($locusID as xs:string) {
    let $locus := $app:collectionLoci/id($locusID)
    let $geoCoord := $locus//tei:geo/text() => replace(' ', ',')
    
    let $map := <div id="googleMap">
                    <script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?sensor=false"/>
                    <div style="width:600px;height:500px" id="gmeg_map_canvas"/>
                    <span style="font-size: 10px; color: #111; text-decoration: none;">Powered by </span><a style="font-size: 10px; color: #111; text-decoration: none;" href="https://www.mso-digital.de/sea/google-ads/" title="MSO Digital">Google Ads Agentur</a>
                    <span style="font-size: 10px; color: #111; text-decoration: none;"> und 
                    </span><a style="font-size: 10px; color: #111; text-decoration: none;" href="https://mso-digital.de/mapsgenerator/" title="Google Maps auf der Website einbinden">Google Maps einbinden</a>
                    <script>var gmegMap, gmegMarker, gmegInfoWindow, gmegLatLng;function gmegInitializeMap(){{
                                gmegLatLng = new google.maps.LatLng({$geoCoord});
                                gmegMap = new google.maps.Map(document.getElementById("gmeg_map_canvas"),{{
                                    zoom:15,center:gmegLatLng,mapTypeId:google.maps.MapTypeId.HYBRID}});
                                    gmegMarker = new google.maps.Marker({{map:gmegMap,position:gmegLatLng}});
                                    gmegInfoWindow = new google.maps.InfoWindow({{content:'<b>{baudiLocus:getLocusName($locusID)}</b>'}});
                                    gmegInfoWindow.open(gmegMap,gmegMarker);}}
                                    google.maps.event.addDomListener(window,"load",gmegInitializeMap);</script>
                  </div>
    
    return
        if($geoCoord)
        then($map)
        else()
};

declare function baudiLocus:getLocusName($locusID as xs:string) {
    let $locus := $app:collectionLoci/id($locusID)
    let $locusName := $locus/tei:placeName[1]/text()
    return
        $locusName
};
