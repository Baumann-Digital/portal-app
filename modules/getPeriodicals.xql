xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";
import module namespace baudiShared="http://baumann-digital.de/ns/baudiShared"    at "/db/apps/baudiApp/modules/baudiShared.xqm";

(:declare option exist:serialize "method=json media-type=application/json omit-xml-declaration=yes";:)

(:declare option output:method "json";
declare option output:media-type "application/json";:)


(: Postal Objects collection :)
declare variable $periodicalsCollectionURI as xs:string := 'xmldb:exist:///db/apps/baudiData/sources/periodicals';

declare function local:getPeriodicalBaudiIdentifier($periodical) {
    $periodical/@xml:id/string()
};


for $periodical in $periodicalsCollectionURI//tei:TEI
(: Get parameters :)
let $periodicalBibl := $periodical//tei:sourceDesc/tei:bibl[@type='periodical']
let $titleMain := $periodicalBibl/tei:title[@type='main']
let $titleSub := $periodicalBibl/tei:title[@type='sub']
let $date := $periodicalBibl/tei:date/@when-iso/satring()
let $volume := $periodicalBibl/tei:biblScope[@unit="volume"]/string()
let $issue := $periodicalBibl/tei:biblScope[@unit="issue"]/string()
let $pages := concat($periodicalBibl/tei:biblScope[@unit="page"]/@from/string(),'–',$periodicalBibl/tei:biblScope[@unit="page"]/@to/string())


return map {
    'identifierBauDi': local:getPeriodicalBaudiIdentifier($periodical),
    'titleMain': $titleMain,
    'titleSub' : $titleSub,
    'date' : $date,
    'volume' : $volume,
    'issue' : $issue,
    'pages' : $pages
}
