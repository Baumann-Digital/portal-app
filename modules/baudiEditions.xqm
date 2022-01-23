xquery version "3.1";

module namespace baudiEditions="http://baumann-digital.de/ns/baudiEditions";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace edirom="http://www.edirom.de/ns/1.3";
declare namespace baudiAnnots="http://baumann-digital.de/ns/baudiAnnots";

import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";
import module namespace baudiWork="http://baumann-digital.de/ns/baudiWork" at "/db/apps/baudiApp/modules/baudiWork.xql";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace request="http://exist-db.org/xquery/request";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";

import module namespace i18n="http://exist-db.org/xquery/i18n" at "/db/apps/baudiApp/modules/i18n.xql";

declare function baudiEditions:hasEditions($workID as xs:string){
    let $editions := $app:collectionEditions//edirom:work[@xml:id=$workID]
    return
        if(count($editions) > 0) then(true()) else(false())
};

declare function baudiEditions:hasRemarks($workID as xs:string){};

declare function baudiEditions:getRemarks($editionID as xs:string){};

(:declare function baudiEditions:hasEditions($workID as xs:string){};:)

