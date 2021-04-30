xquery version "3.1";

module namespace baudiWork="http://baumann-digital.de/ns/baudiWork";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";
import module namespace baudiShared="http://baumann-digital.de/ns/baudiShared" at "/db/apps/baudiApp/modules/baudiShared.xqm";
import module namespace baudiSource="http://baumann-digital.de/ns/baudiSource" at "/db/apps/baudiApp/modules/baudiSource.xqm";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="https://exist-db.org/xquery/config" at "/db/apps/baudiApp/modules/config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace transform="http://exist-db.org/xquery/transform";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";

import module namespace i18n="http://exist-db.org/xquery/i18n" at "/db/apps/baudiApp/modules/i18n.xql";


declare function baudiWork:getWorkTitle($work as node()*){
    let $title := $work//mei:title[@type='uniform']/mei:titlePart[@type='main' and not(@class)]/normalize-space(text()[1])
                         let $titleSort := $work//mei:title[@type='uniform']/mei:titlePart[range:field-eq("titlePart-main", 'main') and @class='sort']/text()
                         let $numberOpus := $work//mei:title[@type='uniform']/mei:titlePart[@type='number' and @auth='opus']
                         let $numberOpusCount := $work//mei:title[@type='uniform']/mei:titlePart[@type='counter']/text()
                         let $numberOpusCounter := if($numberOpusCount)
                                                   then(concat(' ',baudiShared:translate('baudi.registry.works.opus.no'),' ',$numberOpusCount))
                                                   else()
    return
        if($numberOpus)then(concat($title,' op. ',$numberOpus,$numberOpusCounter))else($title)
};

(:declare function baudiWork:getLyricist($work as node()) {
  let $collectionPersons := collection('/db/apps/baudiPersons/data')//tei:person
  let $lyricists := $work//mei:lyricist/mei:persName
  return
    for $lyricist in $lyricists
        
        let $lyricistID := $lyricist/@auth
        let $lyricistEntry := if($lyricistID)
                              then($collectionPersons[@xml:id=$lyricistID])
                              else($lyricist)
        let $lyricistName := if($lyricistID)
                              then($lyricistEntry/tei:persName/text())
                              else($lyricist)
        let $lyricistGender := if($lyricistEntry[@sex="female"])
                               then('lyricist.female')
                               else('lyricist')
             
        return
          <h3>[lyricistID:'{$lyricistID/string()}', lyricistName:'{$lyricistName}', lyricistGender:'{$lyricistGender}']</h3>
};:)

declare function baudiWork:getPerfRes($work as node()*, $param as xs:string) {
    let $perfMedium := $work//mei:perfMedium
    let $perfResLists := $perfMedium//mei:perfResList
    let $perfResList := for $list in $perfResLists
                            let $perfResListName := $list/@auth
                            let $perfRess := $list//mei:perfRes/@auth
                            return
                                if($perfResListName and $param = 'short')
                                then(baudiShared:translate(concat('baudi.registry.works.perfRes.',$perfResListName)))
                                else if ($param = 'detail')
                                then(string-join(for $perfRes in $perfRess
                                            return
                                                baudiShared:translate(concat('baudi.registry.works.perfRes.',$perfRes)),' | ')
                                    )
                                else(baudiShared:translate('baudi.unknown'))
    return
        $perfResList
};


declare function baudiWork:getStemma($workID as xs:string, $height as xs:string?, $width as xs:string?) {
    <img src="{concat('https://digilib.baumann-digital.de/BauDi/02/', $workID, '_stemma.png?dh=2000')}" class="img-fluid" alt="Responsive image" height="{$height}" width="{$width}"/>
};
