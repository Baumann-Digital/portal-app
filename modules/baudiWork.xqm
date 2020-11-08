xquery version "3.1";

module namespace baudiWork="http://baumann-digital.de/ns/baudiWork";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace app="http://baumann-digital.de/ns/templates" at "app.xql";
import module namespace baudiShared="http://baumann-digital.de/ns/baudiShared" at "baudiShared.xqm";
import module namespace baudiSource="http://baumann-digital.de/ns/baudiSource" at "baudiSource.xqm";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="https://exist-db.org/xquery/config" at "config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace transform="http://exist-db.org/xquery/transform";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";

import module namespace i18n="http://exist-db.org/xquery/i18n" at "i18n.xql";


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

declare function baudiWork:getPerfRes($workID as xs:string) {
    let $workDoc := $app:collectionWorks[@xml:id=$workID]
    let $work := $workDoc//mei:work
    let $perfResLists := $workDoc//mei:perfMedium/mei:perfResList
    let $perfResList := for $list in $perfResLists
                        let $perfResListName := $list/@auth
                        let $perfRess := $list//mei:perfRes/@auth
                        return
                            if($perfResListName)
                            then(baudiShared:translate(concat('baudi.catalog.works.perfRes.',$perfResListName)))
                            else(string-join(for $perfRes in $perfRess
                                        return
                                            baudiShared:translate(concat('baudi.catalog.works.perfRes.',$perfRes)),' | ')
                                )
    return
        $perfResList
};

declare function baudiWork:getPerfResDetail($workID as xs:string) {
    let $workDoc := $app:collectionWorks[@xml:id=$workID]
    let $work := $workDoc//mei:work
    let $perfResList := $workDoc//mei:perfMedium//mei:perfResList
    let $perfResList := for $list in $perfResList
                        let $perfResListName := $list/@auth
                        let $perfRess := $list//mei:perfRes/@auth
                        return
                            if($perfResListName)
                            then(baudiShared:translate(concat('baudi.catalog.works.perfRes.',$perfResListName)))
                            else(string-join(for $perfRes in $perfRess
                                        return
                                            baudiShared:translate(concat('baudi.catalog.works.perfRes.',$perfRes)),' | ')
                                )
    return
        $perfResList
};