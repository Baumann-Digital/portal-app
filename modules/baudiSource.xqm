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

declare function baudiSource:getAmbPitch($ambNote as node()) {
  let $ambPname := $ambNote/@pname/string()
  let $ambAccid := $ambNote/@accid/string()
  let $ambOct := $ambNote/@oct/number()
  let $ambNoteFull := concat($ambPname,$ambAccid)
  return
      if($ambOct < 3)
      then(
            (<i>{functx:capitalize-first(baudiShared:translate(concat('baudi.catalog.works.pname.',$ambNoteFull))),
            if($ambOct - 2 = 0)
            then()
            else(<sup>{($ambOct - 2) * -1}</sup>)}</i>)
            )
      else if($ambOct >= 3)
      then(
            (<i>{baudiShared:translate(concat('baudi.catalog.works.pname.',$ambNoteFull)),
            if($ambOct - 3 = 0)
            then()
            else(<sup>{$ambOct - 3}</sup>)}</i>)
            )
      else()
};

declare function baudiSource:getAmbitus($ambitus as node()) {
    let $lowest := if($ambitus/mei:ambNote[@type='lowest']) then(baudiSource:getAmbPitch($ambitus/mei:ambNote[@type='lowest'])) else()
    let $lowestAlt := if($ambitus/mei:ambNote[@type='lowestAlt']) then(baudiSource:getAmbPitch($ambitus/mei:ambNote[@type='lowestAlt'])) else()
    let $highest := if($ambitus/mei:ambNote[@type='highest'])then(baudiSource:getAmbPitch($ambitus/mei:ambNote[@type='highest']))else()
    let $highestAlt := if($ambitus/mei:ambNote[@type='highestAlt'])then(baudiSource:getAmbPitch($ambitus/mei:ambNote[@type='highestAlt']))else()
    return
            (
            if($lowestAlt)
            then(concat($lowest, ' (', $lowestAlt,')'))
            else($lowest),
            '–',
            if($highestAlt)
            then($highest, ' (', $highestAlt,')')
            else($highest)
            )
};

declare function baudiSource:getManifestationPerfResWithAmbitus($sourceID as xs:string) {
    let $source := $app:collectionSourcesMusic[@xml:id=$sourceID]
    let $sourceWork := $source//mei:work
    let $perfResLists := $sourceWork//mei:perfResList
    let $perfResList := for $list in $perfResLists
                        let $perfResListName := $list/@auth
                        let $perfRess := $list//mei:perfRes
                        return
                            (
                                <b>{baudiShared:translate(concat('baudi.catalog.works.perfRes.',$perfResListName))}</b>,
                                <ul style="list-style-type: square;">
                                    {for $perfRes in $perfRess
                                        let $perfResVal := $perfRes/@auth
                                        let $ambitus := if($perfRes/mei:ambitus) then(baudiSource:getAmbitus($perfRes/mei:ambitus)) else()
                                            return
                                                <li>{if($ambitus)
                                                     then (baudiShared:translate(concat('baudi.catalog.works.perfRes.',$perfResVal)), ' | ', $ambitus)
                                                     else(baudiShared:translate(concat('baudi.catalog.works.perfRes.',$perfResVal)))}
                                                </li>}
                                </ul>
                            )
    return
        $perfResList
};

declare function baudiSource:getManifestationIdentifiers($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]

let $msRepository := baudiShared:getCorpNameFullLinked($source//mei:physLoc/mei:repository/mei:corpName)
let $msRepositorySiglum := $source//mei:physLoc/mei:repository/mei:corpName/@label/string()
let $msRepositoryShelfmark := $source//mei:physLoc/mei:repository/mei:identifier[@type="shelfmark"]
let $msRismNo := $source//mei:manifestation/mei:identifier[@type="rism"]

let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.repository')}</td>
                     <td>{$msRepository} ({$msRepositorySiglum})</td>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.shelfmark')}</td>
                     <td>{$msRepositoryShelfmark}</td>
                  </tr>
                  <tr>
                     <td>RISM-{baudiShared:translate('baudi.catalog.sources.opus.no')}</td>
                     <td>{$msRismNo}</td>
                  </tr>
               </table>
return
    $table
};

declare function baudiSource:getManifestationPaperSpecs($sourceID  as xs:string) {

let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]

let $msPaperDimensionsHeight := $source//mei:dimensions[@label="height"]/text()
let $msPaperDimensionsHeightUnit := $source//mei:dimensions[@label="height"]/@unit/string()
let $msPaperDimensionsWidth := $source//mei:dimensions[@label="width"]/text()
let $msPaperDimensionsWidthUnit := $source//mei:dimensions[@label="width"]/@unit/string()
let $msPaperDimensions := concat('ca. ', $msPaperDimensionsHeight, $msPaperDimensionsHeightUnit, ' x ', $msPaperDimensionsWidth, $msPaperDimensionsWidthUnit, ' (',baudiShared:translate('baudi.catalog.sources.msDesc.paper.dimensions.height.short'), 'x', baudiShared:translate('baudi.catalog.sources.msDesc.paper.dimensions.width.short'),')')
let $msPaperOrientation := baudiShared:translate(concat('baudi.catalog.sources.msDesc.paper.orientation.', $source//mei:extent[@label="orientation"]/text()))
let $msPaperFolii := $source//mei:extent[@label="folium"]/text()
let $msPaperPages := $source//mei:extent[@label="pages"]/text()
let $msPaperPagination := baudiShared:translate(concat('baudi.catalog.sources.msDesc.paper.pagination.', $source//mei:extent[@label="pagination"]/text()))

let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.paper.dimensions')}</td>
                     <td>{$msPaperDimensions}</td>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.paper.orientation')}</td>
                     <td>{$msPaperOrientation}</td>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.paper.folii')}</td>
                     <td>{$msPaperFolii}</td>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.paper.pages')}</td>
                     <td>{$msPaperPages}</td>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.paper.pagination')}</td>
                     <td>{$msPaperPagination}</td>
                  </tr>
              </table>
return
    $table
};

declare function  baudiSource:getManifestationHands($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]

let $hands := $source//mei:handList/mei:hand
let $listOfHands := for $hand in $hands
                    
                    let $type := baudiShared:translate(concat('baudi.catalog.sources.msDesc.hands.',$hand/@type))
                    let $medium := baudiShared:translate(concat('baudi.catalog.sources.msDesc.hands.medium.',$hand/@medium))
                    let $praeposition := baudiShared:translate('baudi.catalog.praeposition.with')
                    return
                        <li>{$type, $praeposition, $medium}</li>
let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.hands')}</td>
                     <td>
                        <ol>
                            {$listOfHands}
                        </ol>
                     </td>
                  </tr>
              </table>
return
    $table
};

declare function  baudiSource:getManifestationPaperNotes($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]

let $paperNote := $source//mei:annot[@type="paperNote"]
let $paperNotePlace:= tokenize($paperNote/@place, ' ')
let $paperNotePlaceTranslated := for $token in $paperNotePlace
                                  let $i18n := baudiShared:translate(concat('baudi.catalog.mei.annot.place.', $token))
                                  return
                                    $i18n
let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.paperNotes')}</td>
                     <td>{concat($paperNote, ' (', string-join($paperNotePlaceTranslated, ' '), ')')}</td>
                  </tr>
              </table>
return
    $table
};

declare function  baudiSource:getManifestationStamps($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]

let $stampNotes := $source//mei:annot[@type="stamp"]
let $listOfStamps := for $stamp in $stampNotes
                        let $stampPlace:= tokenize($stamp/@place, ' ')
                        let $stampPlaceTranslated := for $token in $stampPlace
                                                        let $i18n := baudiShared:translate(concat('baudi.catalog.mei.annot.place.', $token))
                                                        return
                                                           $i18n
                        let $stampPositions := for $stampPos in tokenize($stamp/@data, ' ')
                                                  let $stampData := substring-after($stampPos, '#')
                                                  let $stampPage := $source//mei:surface[matches(@xml:id, $stampData)]/@label/string()
                                                  return
                                                     $stampPage
                        return
                            <li>{concat($stamp, ' (', string-join($stampPositions, ', '), ' ', string-join($stampPlaceTranslated, ' '), ')')}</li>
let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.stamps')}</td>
                     <td><ul style="list-style-type: square;">{$listOfStamps}</ul></td>
                  </tr>
              </table>
return
    $table
};

declare function  baudiSource:getManifestationNotes($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]
let $notes := $source//mei:annot[not(@type)]
let $listOfNotes := for $note in $notes
                        let $notePlace:= tokenize($note/@place, ' ')
                        let $notePlaceTranslated := for $token in $notePlace
                                                          let $i18n := baudiShared:translate(concat('baudi.catalog.mei.annot.place.', $token))
                                                          return
                                                            $i18n
                        let $noteData := substring-after($note/@data, '#')
                        let $noteResp := substring-after($note/@resp, '#')
                        let $notePage := $source//mei:surface[matches(@xml:id, $noteData)]/@label/string()
                        let $resp := functx:index-of-node($source//mei:hand, $source//mei:hand[@xml:id = $noteResp])
                        return
                            <li>{concat('[Hand ', $resp, ', ', $notePage, ' ', string-join($notePlaceTranslated, ' '), '] ')} <i>{$note/text()}</i></li>
let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.catalog.sources.msDesc.notes')}</td>
                     <td>
                        <ul style="list-style-type: square;">
                            {$listOfNotes}
                        </ul>
                     </td>
                  </tr>
              </table>
return
    $table
};

declare function  baudiSource:getLyrics($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]
let $lyrics := $source//mei:div[@type="songtext"]
let $title := $lyrics//mei:l[@label='title']/text()
let $lgs := $lyrics/mei:lg[not(@label='title')]
let $lyricsText := for $lg in $lgs
                    let $ls := $lg/mei:l
                    return
                        (<ul style="list-style-type: none; margin: 0; padding: 0;">
                            {for $l in $ls
                                return
                                    <li>{$l}</li>}
                        </ul>, <br/>)
return
    (
        <br/>,
        <b>{$title}</b>,
        <br/>,
        <br/>,
        $lyricsText
    )
};
