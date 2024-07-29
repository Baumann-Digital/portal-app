xquery version "3.1";

module namespace baudiSource="http://baumann-digital.de/ns/baudiSource";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";
import module namespace baudiShared="http://baumann-digital.de/ns/baudiShared" at "/db/apps/baudiApp/modules/baudiShared.xqm";
import module namespace baudiWork="http://baumann-digital.de/ns/baudiWork" at "/db/apps/baudiApp/modules/baudiWork.xqm";
import module namespace baudiPersons="http://baumann-digital.de/ns/baudiPersons" at "/db/apps/baudiApp/modules/baudiPersons.xqm";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="https://exist-db.org/xquery/config" at "/db/apps/baudiApp/modules/config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace transform="http://exist-db.org/xquery/transform";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";



import module namespace i18n="http://exist-db.org/xquery/i18n" at "i18n.xql";

declare function baudiSource:getManifestationTitle($manifestation as node()*, $param as xs:string) {
  
  let $source := $manifestation
  let $sourceTitleFull := string-join(($source//mei:titlePart[@type='main'], $source//mei:titlePart[@type='subordinate'], $source//mei:titlePart[@type='perf']), ' ')
  let $sourceTitleShort := $source//mei:titlePart[@type='main']
  let $sourceTitleUniform := ($source/ancestor::mei:mei//mei:fileDesc//mei:title[@type="uniform"])[1]
  let $sourceTitleUniformParts := ($sourceTitleUniform/mei:titlePart[@type='main'][. != ''], $sourceTitleUniform/mei:titlePart[@type='subordinate'][. != ''], $sourceTitleUniform/mei:titlePart[@type='perf'][. != ''])
  let $sourceTitleUniformJoined := if($sourceTitleUniform/mei:titlePart) then(string-join($sourceTitleUniformParts,' ')) else(string-join($sourceTitleUniform//text(),' '))
  let $param := if($param= 'sub') then('subordinate') else($param)
  let $sourceTitlePartParam := $source//mei:titlePart[@type=$param]

return
    (if ($param = 'full')
    then ($sourceTitleFull)
    else if ($param = 'short')
    then ($sourceTitleShort)
    else if ($param = 'uniform')
    then ($sourceTitleUniformJoined)
    else ($sourceTitlePartParam))[1]
};

declare function baudiSource:getManifestationPersona($sourceID as xs:string, $param as xs:string) {
    let $source := $app:collectionSourcesMusic[@xml:id=$sourceID]
    let $sourceManifestation := $source//mei:manifestation
    let $sourceManifestationPersona := if ($sourceManifestation//node()[name() = $param]/mei:persName/@codedval)
                                       then (baudiShared:getPersonaLinked($sourceManifestation//node()[name() = $param]/mei:persName/@codedval))
                                       else if ($sourceManifestation//node()[name() = $param]/mei:persName)
                                       then ($sourceManifestation//node()[name() = $param]/mei:persName/text()[1])
                                       else ()
    
    return
        $sourceManifestationPersona
};


declare function baudiSource:getManifestationPerfRes($sourceFile as node()*) {
    let $perfResLists := $sourceFile//mei:perfResList
    let $perfResList := for $list in $perfResLists
                        let $perfResListName := $list/@codedval
                        let $perfRess := $list//mei:perfRes/@codedval
                        return
                            if($perfResListName)
                            then(baudiShared:translate(concat('baudi.registry.works.perfRes.',$perfResListName)))
                            else(string-join(for $perfRes in $perfRess
                                        return
                                            baudiShared:translate(concat('baudi.registry.works.perfRes.',$perfRes)),' | ')
                                )
    return
        $perfResList
};

declare function baudiSource:getAmbPitch($ambNote as node()*) {
  let $ambPname := $ambNote/@pname/string()
  let $ambAccid := $ambNote/@accid/string()
  let $ambOct := $ambNote/@oct/number()
  let $ambNoteFull := concat($ambPname,$ambAccid)
  return
      if($ambOct < 3)
      then(
            (<i>{functx:capitalize-first(baudiShared:translate(concat('baudi.registry.works.pname.',$ambNoteFull))),
            if($ambOct - 2 = 0)
            then()
            else(<sup>{($ambOct - 2) * -1}</sup>)}</i>)
            )
      else if($ambOct >= 3)
      then(
            (<i>{baudiShared:translate(concat('baudi.registry.works.pname.',$ambNoteFull)),
            if($ambOct - 3 = 0)
            then()
            else(<sup>{$ambOct - 3}</sup>)}</i>)
            )
      else()
};

declare function baudiSource:getAmbitus($ambitus as node()*) as xs:string{
    let $lowest := if($ambitus/mei:ambNote[@type='lowest']) then(baudiSource:getAmbPitch($ambitus/mei:ambNote[@type='lowest'])) else()
    let $lowestAlt := if($ambitus/mei:ambNote[@type='lowestAlt']) then(baudiSource:getAmbPitch($ambitus/mei:ambNote[@type='lowestAlt'])) else()
    let $highest := if($ambitus/mei:ambNote[@type='highest'])then(baudiSource:getAmbPitch($ambitus/mei:ambNote[@type='highest']))else()
    let $highestAlt := if($ambitus/mei:ambNote[@type='highestAlt'])then(baudiSource:getAmbPitch($ambitus/mei:ambNote[@type='highestAlt']))else()
    return
            concat('[',
            if($lowestAlt)
            then(concat($lowest, ' (', $lowestAlt,')'))
            else($lowest),
            '–',
            if($highestAlt)
            then($highest, ' (', $highestAlt,')')
            else($highest),
            ']')
};

declare function baudiSource:getManifestationPerfResWithAmbitus($sourceFile as node()*, $param as xs:string) {
    let $param2 := switch ($param) case 'short' return '.short' default return ''
    let $sourceWork := $sourceFile//mei:work
    let $perfMedium := $sourceWork//mei:perfMedium
    let $perfResLists := $perfMedium//mei:perfResList
    
    let $perfResLabelString := for $list at $n in $perfResLists
                                let $listName := $list/@codedval
                                let $listType := $list/@type
                                let $perfResLabels := for $perfRes in $list/mei:perfRes
                                                         let $perfResAuth := $perfRes/@codedval
                                                         let $perfResAuthShorted := if(contains($perfResAuth,'.i'))
                                                                                  then(substring-before($perfResAuth,'.i'))
                                                                                  else if(matches($perfResAuth,'.ii'))
                                                                                  then(substring-before($perfResAuth,'.ii'))
                                                                                  else if(matches($perfResAuth,'.iii'))
                                                                                  then(substring-before($perfResAuth,'.iii'))
                                                                                  else if(matches($perfResAuth,'.iv'))
                                                                                  then(substring-before($perfResAuth,'.iv'))
                                                                                  else($perfResAuth)
                                                          let $ambitus := if($perfRes/mei:ambitus) then(baudiSource:getAmbitus($perfRes/mei:ambitus)) else()
                                                          let $perfResAuth := if($ambitus and $param != 'short')
                                                                              then(concat(baudiShared:translate(concat('baudi.registry.works.perfRes.', $perfResAuth, $param2)), ' ', $ambitus))
                                                                              else(baudiShared:translate(concat('baudi.registry.works.perfRes.', $perfResAuth, $param2)))
                                                          let $perfResAuthShort := baudiShared:translate(concat('baudi.registry.works.perfRes.', $perfResAuthShorted, '.short'))
                                                          let $perfResSolo := if($perfRes/@solo) then(baudiShared:translate('baudi.registry.works.perfRes.solo')) else()
                                                          let $perfResAdLib := if($perfRes/@adLib) then(baudiShared:translate('baudi.registry.works.perfRes.adLib')) else()
                                                          let $perfResOption := if($perfResSolo or $perfResAdLib) then(concat('(',string-join(($perfResSolo, $perfResAdLib), ', '),')')) else()
                                                          
                                                          return
                                                            if($listName)
                                                            then(string-join(($perfResAuthShort, $perfResOption), ' '))
                                                            else(string-join(($perfResAuth, $perfResOption), ' '))
                                
                                let $perfResLabelsDistCount := for $each in distinct-values($perfResLabels)
                                                                let $count := count($perfResLabels[.=$each])
                                                                let $countLabel := if($count > 1) then($count) else()
                                                                let $label := string-join(($countLabel,$each), ' ')
                                                                return
                                                                    $label
                                return
                                    
                                    if($listName)
                                    then(concat(baudiShared:translate(concat('baudi.registry.works.perfRes.', $listName, $param2)), ' (', string-join($perfResLabelsDistCount, ', '), ')'))
                                    else if ($list/@type = 'choose')
                                    then(string-join($perfResLabels, concat(' ', baudiShared:translate(concat('baudi.conjunction.or', $param2)), ' ')))
                                    else(string-join($perfResLabels, ', '))
    return
        string-join($perfResLabelString, ', ')
    
   (: let $perfResList := for $list in $perfResLists
                        let $perfResListName := $list/@codedval
                        let $perfRess := $list//mei:perfRes
                        return
                            (
                                <b>{baudiShared:translate(concat('baudi.registry.works.perfRes.',$perfResListName))}</b>,
                                <ul style="list-style-type: square;">
                                    {for $perfRes in $perfRess
                                        let $perfResVal := $perfRes/@codedval
                                        let $ambitus := if($perfRes/mei:ambitus) then(baudiSource:getAmbitus($perfRes/mei:ambitus)) else()
                                            return
                                                <li>{if($ambitus)
                                                     then (baudiShared:translate(concat('baudi.registry.works.perfRes.',$perfResVal)), ' | ', $ambitus)
                                                     else(baudiShared:translate(concat('baudi.registry.works.perfRes.',$perfResVal)))}
                                                </li>}
                                </ul>
                            )
    return
        $perfResList :)
    
    

};

declare function baudiSource:getManifestationIdentifiers($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]

let $msRepository := if($source//mei:physLoc/mei:repository/mei:corpName[@codedval])
                     then(baudiShared:getCorpNameFullLinked($source//mei:physLoc/mei:repository/mei:corpName))
                     else($source//mei:physLoc/mei:repository/string())
let $msRepositorySiglum := $source//mei:physLoc/mei:repository/mei:corpName/@label/string()
let $msRepositoryShelfmark := $source//mei:physLoc/mei:repository/mei:identifier[@type="shelfmark"] | $source//mei:manifestation/mei:identifier[@type="shelfmark"]
let $msRismNo := $source//mei:manifestation/mei:identifier[@type="rism"]/text()

let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.registry.sources.msDesc.repository')}</td>
                     <td>{$msRepository}</td>
                  </tr>
                  {if($msRepositoryShelfmark)
                  then(
                  <tr>
                     <td>{baudiShared:translate('baudi.registry.sources.msDesc.shelfmark')}</td>
                     <td>{$msRepositoryShelfmark}</td>
                  </tr>)
                  else()}
                  {if($msRismNo)
                  then(
                  <tr>
                     <td>RISM-{baudiShared:translate('baudi.registry.sources.opus.no')}</td>
                     <td>{$msRismNo}</td>
                  </tr>)
                  else()}
               </table>
return
    $table
};

declare function baudiSource:getManifestationPaperSpecs($sourceID  as xs:string) {

let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]
let $sourceType := string-join($source//mei:term[@type='source']/string(),'_')

let $msPaperDimensionsHeight := $source//mei:dimensions[@label="height"]/text() | $source//mei:dimensions/mei:height/text()
let $msPaperDimensionsHeightUnit := ($source//mei:dimensions[@label="height"]/@unit/string(), $source//mei:dimensions/mei:height/@unit/string())
let $msPaperDimensionsWidth := $source//mei:dimensions[@label="width"]/text() | $source//mei:dimensions/mei:width/text()
let $msPaperDimensionsWidthUnit := ($source//mei:dimensions[@label="width"]/@unit/string(), $source//mei:dimensions/mei:width/@unit/string())
let $height := if($msPaperDimensionsHeight) then(string-join(($msPaperDimensionsHeight, $msPaperDimensionsHeightUnit), ' '))else()
let $width := if($msPaperDimensionsWidth) then(string-join(($msPaperDimensionsWidth, $msPaperDimensionsWidthUnit), ' ')) else()
let $msPaperDimensions := if($height or $width)
                          then(concat(string-join(($height, $width), ' x '),
                                      ' (',
                                      string-join( (
                                      if($height)
                                      then(baudiShared:translate('baudi.registry.sources.msDesc.paper.dimensions.height.short'))
                                      else(),
                                      if($width)
                                      then(baudiShared:translate('baudi.registry.sources.msDesc.paper.dimensions.width.short'))
                                      else()), 'x'),
                                      ')'))
                          else()

let $msPaperOrientation := $source//mei:extent[@label="orientation"]/text()
let $prPaperFormat := if($msPaperOrientation and $msPaperDimensionsHeight and $msPaperDimensionsHeightUnit and $msPaperDimensionsWidth and $msPaperDimensionsWidthUnit)
                      then(baudiSource:getPrintPaperFormat($msPaperOrientation,$msPaperDimensionsHeight, $msPaperDimensionsHeightUnit, $msPaperDimensionsWidth, $msPaperDimensionsWidthUnit))
                      else('Dimensions not recorded')

let $msPaperFolii := $source//mei:extent[@label="folium"]/text() | $source//mei:extent[@unit="folio"]/text()
let $msPaperPages := $source//mei:extent[@label="pages"]/text() | $source//mei:extent[@unit="page"]/text()
let $msPaperPagination := baudiShared:translate(concat('baudi.registry.sources.msDesc.paper.pagination.', $source//mei:extent[@label="pagination"]/text()))

let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  {if($msPaperOrientation)
                  then(<tr>
                     <td>{baudiShared:translate('baudi.registry.sources.msDesc.paper.orientation')}</td>
                     <td>{baudiShared:translate(concat('baudi.registry.sources.msDesc.paper.orientation.', $msPaperOrientation))}</td>
                  </tr>)
                  else()}
                  {if($msPaperDimensions)
                  then(<tr>
                         <td>{baudiShared:translate('baudi.registry.sources.msDesc.paper.dimensions')}</td>
                         <td>{$msPaperDimensions}</td>
                       </tr>)
                  else if(contains($sourceType,'print'))
                  then(<tr>
                         <td>{baudiShared:translate('baudi.registry.sources.msDesc.paper.format')}</td>
                         <td>{$prPaperFormat}</td>
                       </tr>)
                  else('–')}
                  {if($msPaperFolii)
                  then(<tr>
                     <td>{baudiShared:translate('baudi.registry.sources.msDesc.paper.folii')}</td>
                     <td>{$msPaperFolii}</td>
                  </tr>)
                  else()}
                  {if($msPaperPages)
                  then(<tr>
                     <td>{baudiShared:translate('baudi.registry.sources.msDesc.paper.pages')}</td>
                     <td>{$msPaperPages}</td>
                  </tr>)
                  else()}
                  {if($msPaperPagination)
                  then(<tr>
                         <td>{baudiShared:translate('baudi.registry.sources.msDesc.paper.pagination')}</td>
                         <td>{$msPaperPagination}</td>
                       </tr>)
                  else()}
              </table>
return
    $table
};

declare function  baudiSource:getManifestationHands($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]

let $hands := $source//mei:handList/mei:hand
let $listOfHands := for $hand in $hands
                    
                    let $type := baudiShared:translate(concat('baudi.registry.sources.msDesc.hands.',$hand/@type))
                    let $medium := baudiShared:translate(concat('baudi.registry.sources.msDesc.hands.medium.',$hand/@medium))
                    let $text := $hand//text() => string-join(' ')
                    return
                        <li>{if($type) then($type || ', ') else(), $medium, if($text) then(' (' || $text || ')') else()}</li>
let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.registry.sources.msDesc.hands')}</td>
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
                                  let $i18n := baudiShared:translate(concat('baudi.registry.mei.annot.place.', $token))
                                  return
                                    $i18n
let $tableRow := 
                  <tr>
                     <td>{baudiShared:translate('baudi.registry.sources.msDesc.paperNotes')}</td>
                     <td>{concat($paperNote, ' (', string-join($paperNotePlaceTranslated, ' '), ')')}</td>
                  </tr>
return
    if($paperNote) then($tableRow) else()
};


declare function  baudiSource:getManifestationStamps($stampNotes as node()*) {

let $listOfStamps := for $stamp in $stampNotes
                        let $stampPlace:= tokenize($stamp/@place, ' ')
                        let $stampPlaceTranslated := for $token in $stampPlace
                                                        let $i18n := baudiShared:translate(concat('baudi.registry.mei.annot.place.', $token))
                                                        return
                                                           $i18n
                        let $stampPositions := for $stampPos in tokenize($stamp/@data, ' ')
                                                  let $stampData := substring-after($stampPos, '#')
                                                  let $stampPage := $stamp/ancestor::mei:mei//mei:surface[matches(@xml:id, $stampData)]/@label/string()
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
                     <td>{baudiShared:translate('baudi.registry.sources.msDesc.stamps')}</td>
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
                                                          let $i18n := baudiShared:translate(concat('baudi.registry.mei.annot.place.', $token))
                                                          return
                                                            $i18n
                        let $noteData := substring-after($note/@data, '#')
                        let $noteResp := substring-after($note/@resp, '#')
                        let $notePage := $source//mei:surface[@xml:id = $noteData]/@label/string()
                        let $resp := if($source//mei:hand[@xml:id = $noteResp]) then(functx:index-of-node($source//mei:hand, $source//mei:hand[@xml:id = $noteResp])) else()
                        return
                            if($resp) then(<li>{concat('[Hand ', $resp, ', ', $notePage, ' ', string-join($notePlaceTranslated, ' '), '] ')} <i>{$note/text()}</i></li>)
                            else(<li><i>{$note//text() => string-join('')}</i></li>)
let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{baudiShared:translate('baudi.registry.sources.msDesc.notes')}</td>
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


declare function baudiSource:getPrintPaperFormat($orientation as xs:string, $paperDimensionsHeight as xs:string, $paperDimensionsHeightUnit as xs:string, $paperDimensionsWidth as xs:string, $paperDimensionsWidthUnit as xs:string) as xs:string {

let $height := if($paperDimensionsHeightUnit = 'mm')
               then (number($paperDimensionsHeight))
               else if ($paperDimensionsHeightUnit = 'cm')
               then (number($paperDimensionsHeight) * 10)
               else if ($paperDimensionsHeightUnit = 'm')
               then (number($paperDimensionsHeight) * 1000)
               else('[unit unknown]')

let $width := if($paperDimensionsWidthUnit = 'mm')
               then (number($paperDimensionsWidth))
               else if ($paperDimensionsHeightUnit = 'cm')
               then (number($paperDimensionsWidth) * 10)
               else if ($paperDimensionsHeightUnit = 'm')
               then (number($paperDimensionsWidth) * 1000)
               else('[unit unknown]')

return
    if($orientation = 'portrait')
    then(if($height < 100)
            then('16° (Sedez)')
            else if(100 < $height and $height < 149)
            then('12° (Duodez)')
            else if(150 < $height and $height < 184)
            then('Kl.–8° (Klein-Oktav)')
            else if(185 < $height and $height < 224)
            then('8° (Oktav)')
            else if(225 < $height and $height < 249)
            then('Gr.–8° (Groß-Oktav)')
            else if(250 < $height and $height < 349)
            then('4° (Quart)')
            else if(350 < $height and $height < 399)
            then('Gr.-4° (Groß-Quart)')
            else if(400 < $height and $height < 449)
            then('2° (Folio)')
            else if(450 < $height and $height)
            then('Gr.-2° (Groß-Folio)')
            else(baudiShared:translate('baudi.registry.sources.msDesc.paper.format.unknown')))
    else if ($orientation = 'landscape')
    then(if($width < 100)
            then('16° (Quer-Sedez)')
            else if(100 < $width and $width < 149)
            then('12° (Quer-Duodez)')
            else if(150 < $width and $width < 184)
            then('Kl.–8° (Quer-Klein-Oktav)')
            else if(185 < $width and $width < 224)
            then('8° (Quer-Oktav)')
            else if(225 < $width and $width < 249)
            then('Gr.–8° (Quer-Groß-Oktav)')
            else if(250 < $width and $width < 349)
            then('4° (Quer-Quart)')
            else if(350 < $width and $width < 399)
            then('Gr.-4° (Quer-Groß-Quart)')
            else if(400 < $width and $width < 449)
            then('2° (Quer-Folio)')
            else if(450 < $width and $width)
            then('Gr.-2° (Quer-Groß-Folio)')
            else(baudiShared:translate('baudi.registry.sources.msDesc.paper.format.unknown')))
    else(baudiShared:translate('baudi.registry.sources.msDesc.paper.format.unknown'))
};

declare function baudiSource:getSourceEditionStmt($id, $lang) {
    let $source := $app:collectionSourcesMusic[@xml:id=$id]
    let $edition := $source//mei:editionStmt//mei:edition
    let $editionTitle := $edition/mei:title/text()
    let $editionPublisher := if($edition//mei:publisher/mei:corpName/@codedval)
                             then(baudiShared:getCorpNameFullLinked($edition//mei:publisher/mei:corpName))
                             else($edition//mei:publisher/mei:corpName)
    let $editionPubPlace := $edition//mei:pubPlace
    let $editionDate := if($edition//mei:bibl/mei:date/@*)then(baudiShared:formatDate($edition//mei:date,'full',$lang))else()
    let $editionDedicatee := if($edition//mei:dedicatee/data())
                             then(baudiShared:linkAll($edition//mei:dedicatee))
                             else()
    
    return
        if(1=1)
        then(
            <table class="sourceView">
                <tr>
                    <th/>
                    <th/>
                </tr>
                {if($editionTitle)
                then(
                <tr>
                    <td>{baudiShared:translate('baudi.registry.sources.editionStmt.title')}</td>
                    <td>{$editionTitle}</td>
                </tr>)
                else()}
                {if($editionPublisher)
                then(
                <tr>
                    <td>{baudiShared:translate('baudi.registry.sources.editionStmt.publisher')}</td>
                    <td>{$editionPublisher}</td>
                </tr>)
                else()}
                {if($editionDate)
                then(
                <tr>
                    <td>{baudiShared:translate('baudi.registry.sources.editionStmt.pubDate')}</td>
                    <td>{$editionDate}</td>
                </tr>)
                else()}
                {if($editionPubPlace)
                then(
                <tr>
                    <td>{baudiShared:translate('baudi.registry.sources.editionStmt.pubPlace')}</td>
                    <td>{$editionPubPlace}</td>
                </tr>)
                else()}
                {if($editionDedicatee)
                then(
                <tr>
                    <td>{baudiShared:translate('baudi.registry.sources.editionStmt.dedication')}</td>
                    <td>{$editionDedicatee}</td>
                </tr>)
                else()}
            </table>
        )
        else()
};

declare function baudiSource:renderTitlePage($source as node()*) {
let $titlePage := $source//mei:titlePage

return
    transform:transform($titlePage,doc('/db/apps/baudiApp/resources/xslt/formattingTitlePage.xsl'),())

};

declare function baudiSource:getFacsimilePreview($id as xs:string) {

let $sourceChiffre := subsequence(tokenize($id, '-'), 2, 1)

let $source := if($sourceChiffre = '01')
               then($app:collectionSourcesMusic[@xml:id= $id])
               else if($sourceChiffre = '07')
               then($app:collectionDocuments[@xml:id= $id])
               else('no source found')

let $digilibBasicPath := concat('https://digilib.baumann-digital.de/BauDi/', $sourceChiffre, '/')

let $facsimileTarget := if($sourceChiffre = '01')
                        then($app:collectionSourcesMusic[@xml:id= $id]//mei:facsimile[1]/mei:surface[if(@n='1')then(@n='1')else(1)][1]/mei:graphic/@target)
                        else if($sourceChiffre = '07')
                        then($app:collectionDocuments[@xml:id= $id]//tei:div[@type='page' and @n='1']/@facs)
                        else('no facsimile found')

let $facsimileTargetPath := if(starts-with($facsimileTarget, 'https://digital.blb-karlsruhe.de')) then(functx:substring-after-last($facsimileTarget,'/')) else($facsimileTarget)
let $digilibFacPath := concat($digilibBasicPath, $facsimileTargetPath)

let $BLBfacPath := concat($app:BLBfacPath, $facsimileTargetPath)
let $BLBfacPathImage := concat($app:BLBfacPathImage, $facsimileTargetPath)

let $graphicLocal := if(starts-with($facsimileTargetPath, 'baudi-'))
                     then(<img src="{concat($digilibFacPath, '?dw=500')}" class="img-thumbnail" width="400"/>)
                     else()
let $graphicBLB := if($source//mei:graphic[@targettype="blb-vlid"] or starts-with($facsimileTarget, 'https://digital.blb-karlsruhe.de'))
                   then(<a href="{$BLBfacPath}" target="_blank" data-toggle="tooltip" data-placement="top" title="Zum vollständigen Digitalisat unter digital.blb-karlsruhe.de">
                            <img class="img-thumbnail" src="{$BLBfacPathImage}" width="400"/>
                        </a>)
                   else()
let $graphicBLBLabel := <div>
                            <br/>
                            {baudiShared:translate('baudi.registry.sources.facsimile.source')}: Badische Landesbibliothek Karlsruhe
                        </div>

return
    <div class="col">
        {if($graphicLocal) then($graphicLocal)
         else if($graphicBLB) then($graphicBLB, $graphicBLBLabel)
         else(baudiShared:translate('baudi.noGraphic'))}
        
    </div>
};
