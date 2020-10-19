xquery version "3.1";

module namespace baudiSource="http://baumann-digital.de/ns/baudiSource";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace app="http://baumann-digital.de/ns/templates" at "app.xql";
import module namespace baudiShared="http://baumann-digital.de/ns/baudiShared" at "baudiShared.xqm";
import module namespace baudiWork="http://baumann-digital.de/ns/baudiWork" at "baudiWork.xqm";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="https://exist-db.org/xquery/config" at "config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace transform="http://exist-db.org/xquery/transform";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";



import module namespace i18n="http://exist-db.org/xquery/i18n" at "i18n.xql";

declare function baudiSource:getManifestationTitle($sourceID as xs:string, $param as xs:string) {
  
  let $source := $app:collectionSourcesMusic[@xml:id=$sourceID]
  let $sourceTitleFull := 'Full'
  let $sourceTitleShort := 'Short'
  let $sourceTitleUniform := $source//mei:work/mei:title[@type="uniform"]
  let $sourceTitleUniformParts := ($sourceTitleUniform/mei:titlePart[@type='main'], $sourceTitleUniform/mei:titlePart[@type='subordinate'], $sourceTitleUniform/mei:titlePart[@type='perf'])
  let $sourceTitleUniformJoined := string-join($sourceTitleUniformParts,' ')
  let $sourceTitlePartParam := $source//mei:manifestationList/mei:manifestation//mei:titlePart[@type=$param]

return
    if ($param = 'full')
    then ($sourceTitleFull)
    else if ($param = 'short')
    then ($sourceTitleShort)
    else if ($param = 'uniform')
    then ($sourceTitleUniformJoined)
    else ($sourceTitlePartParam)
};

declare function baudiSource:getManifestationPersona($sourceID as xs:string, $param as xs:string) {
    let $source := $app:collectionSourcesMusic[@xml:id=$sourceID]
    let $sourceManifestation := $source//mei:manifestationList/mei:manifestation
    let $sourceManifestationPersona := if ($sourceManifestation//node()[name() = $param]/mei:persName/@auth)
                                       then (baudiShared:getPersonaLinked($sourceManifestation//node()[name() = $param]/mei:persName/@auth))
                                       else ()
    
    return
        $sourceManifestationPersona
};

declare function baudiSource:getManifestationPerfRes($sourceID as xs:string) {
    let $source := $app:collectionSourcesMusic[@xml:id=$sourceID]
    let $sourceWork := $source//mei:work
    let $perfResLists := $sourceWork//mei:perfResList
    let $perfResList := for $list in $perfResLists
                        let $perfResListName := $list/@auth
                        let $perfRess := $list//mei:perfRes/@auth
                        return
                            (
                                <b>{baudiShared:translate(concat('baudi.catalog.works.perfRes.',$perfResListName))}</b>,
                                <ul style="list-style-type: square;">
                                    {for $perfRes in $perfRess
                                        return
                                            <li>{baudiShared:translate(concat('baudi.catalog.works.perfRes.',$perfRes))}</li>}
                                </ul>
                            )
    return
        $perfResList
};
