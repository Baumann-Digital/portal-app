xquery version "3.1";

module namespace source="http://baumann-digital.de/portal-app/ns/source";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace app="http://baumann-digital.de/ns/templates" at "app.xql";
import module namespace shared="http://baumann-digital.de/portal-app/ns/shared" at "shared.xqm";
import module namespace work="http://baumann-digital.de/portal-app/ns/work" at "work.xqm";
import module namespace persons="http://baumann-digital.de/portal-app/ns/persons" at "persons.xqm";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="https://exist-db.org/xquery/config" at "config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace transform="http://exist-db.org/xquery/transform";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";
import module namespace er="http://baumann-digital.de/portal-app/ns/external-requests" at "external-requests.xqm";

import module namespace i18n="http://exist-db.org/xquery/i18n" at "i18n.xql";

(:~
 : Retrieves the title of a manifestation node in a specified format.
 : @param $manifestation The MEI manifestation node.
 : @param $param The specified format. Values are 'full', 'short', 'uniform' or self-defined
 : @return The first match of 1. the title in a specified format, or 2. the title from an element called by an self-defined type, or 3. an empty sequence if not available.
 :)
declare function source:getManifestationTitle($manifestation as node()*, $param as xs:string) {
  
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

(:~
 : Retrieves the persona of a manifestation.
 : @param $sourceID The xml:id of an MEI file.
 : @param $param The name of the container element the persona is named (e.g., 'composer').
 : @return The name of a persona entity 1. as HTML-fragments (output of shared:getPersonaLinked) if @codededval is present, or 2. the name (text node) if @codededval is not present, or 3. an empty sequence if no element is found.
 :)
declare function source:getManifestationPersona($sourceID as xs:string, $param as xs:string) {
    let $source := $app:collectionSourcesMusic[@xml:id=$sourceID]
    let $sourceManifestation := $source//mei:manifestation
    let $sourceManifestationPersona := if ($sourceManifestation//node()[name() = $param]/mei:persName/@codedval)
                                       then (shared:getPersonaLinked($sourceManifestation//node()[name() = $param]/mei:persName/@codedval))
                                       else if ($sourceManifestation//node()[name() = $param]/mei:persName)
                                       then ($sourceManifestation//node()[name() = $param]/mei:persName/text()[1])
                                       else ()
    
    return
        $sourceManifestationPersona
};


declare function source:getManifestationPerfRes($sourceFile as node()*) {
    let $perfResLists := $sourceFile//mei:perfResList
    let $perfResList := for $list in $perfResLists
                        let $perfResListName := $list/@codedval
                        let $perfRess := $list//mei:perfRes/@codedval
                        return
                            if($perfResListName)
                            then(shared:translate(concat('registry.works.perfRes.',$perfResListName)))
                            else(string-join(for $perfRes in $perfRess
                                        return
                                            shared:translate(concat('registry.works.perfRes.',$perfRes)),' | ')
                                )
    return
        $perfResList
};

declare function source:getAmbPitch($ambNote as node()*) {
  let $ambPname := $ambNote/@pname/string()
  let $ambAccid := $ambNote/@accid/string()
  let $ambOct := $ambNote/@oct/number()
  let $ambNoteFull := concat($ambPname,$ambAccid)
  return
      if($ambOct < 3)
      then(
            (<i>{functx:capitalize-first(shared:translate(concat('registry.works.pname.',$ambNoteFull))),
            if($ambOct - 2 = 0)
            then()
            else(<sup>{($ambOct - 2) * -1}</sup>)}</i>)
            )
      else if($ambOct >= 3)
      then(
            (<i>{shared:translate(concat('registry.works.pname.',$ambNoteFull)),
            if($ambOct - 3 = 0)
            then()
            else(<sup>{$ambOct - 3}</sup>)}</i>)
            )
      else()
};

declare function source:getAmbitus($ambitus as node()*) as xs:string{
    let $lowest := if($ambitus/mei:ambNote[@type='lowest']) then(source:getAmbPitch($ambitus/mei:ambNote[@type='lowest'])) else()
    let $lowestAlt := if($ambitus/mei:ambNote[@type='lowestAlt']) then(source:getAmbPitch($ambitus/mei:ambNote[@type='lowestAlt'])) else()
    let $highest := if($ambitus/mei:ambNote[@type='highest'])then(source:getAmbPitch($ambitus/mei:ambNote[@type='highest']))else()
    let $highestAlt := if($ambitus/mei:ambNote[@type='highestAlt'])then(source:getAmbPitch($ambitus/mei:ambNote[@type='highestAlt']))else()
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

declare function source:getManifestationPerfResWithAmbitus($sourceFile as node()*, $param as xs:string) {
    let $param2 := switch ($param) case 'short' return '.short' default return ''
    let $sourceWork := $sourceFile//mei:work
    let $perfResLabelString := work:getPerfRes($sourceWork,$param2)
    
    return
        string-join($perfResLabelString, ', ')
};

declare function source:getManifestationIdentifiers($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]

let $msRepository := if($source//mei:physLoc/mei:repository/mei:corpName[@codedval])
                     then(shared:getCorpNameFullLinked($source//mei:physLoc/mei:repository/mei:corpName))
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
                     <td>{shared:translate('registry.sources.msDesc.repository')}</td>
                     <td>{$msRepository}</td>
                  </tr>
                  {if($msRepositoryShelfmark)
                  then(
                  <tr>
                     <td>{shared:translate('registry.sources.msDesc.shelfmark')}</td>
                     <td>{$msRepositoryShelfmark}</td>
                  </tr>)
                  else()}
                  {if($msRismNo)
                  then(
                  <tr>
                     <td>RISM-{shared:translate('registry.sources.opus.no')}</td>
                     <td>{$msRismNo}</td>
                  </tr>)
                  else()}
               </table>
return
    $table
};

declare function source:getManifestationPaperSpecs($sourceID  as xs:string) {

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
                                      then(shared:translate('registry.sources.msDesc.paper.dimensions.height.short'))
                                      else(),
                                      if($width)
                                      then(shared:translate('registry.sources.msDesc.paper.dimensions.width.short'))
                                      else()), 'x'),
                                      ')'))
                          else()

let $msPaperOrientation := $source//mei:extent[@label="orientation"]/text()
let $prPaperFormat := if($msPaperOrientation and $msPaperDimensionsHeight and $msPaperDimensionsHeightUnit and $msPaperDimensionsWidth and $msPaperDimensionsWidthUnit)
                      then(source:getPrintPaperFormat($msPaperOrientation,$msPaperDimensionsHeight, $msPaperDimensionsHeightUnit, $msPaperDimensionsWidth, $msPaperDimensionsWidthUnit))
                      else('Dimensions not recorded')

let $msPaperFolii := $source//mei:extent[@label="folium"]/text() | $source//mei:extent[@unit="folio"]/text()
let $msPaperPages := $source//mei:extent[@label="pages"]/text() | $source//mei:extent[@unit="page"]/text()
let $msPaperPagination := shared:translate(concat('registry.sources.msDesc.paper.pagination.', $source//mei:extent[@label="pagination"]/text()))

let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  {if($msPaperOrientation)
                  then(<tr>
                     <td>{shared:translate('registry.sources.msDesc.paper.orientation')}</td>
                     <td>{shared:translate(concat('registry.sources.msDesc.paper.orientation.', $msPaperOrientation))}</td>
                  </tr>)
                  else()}
                  {if($msPaperDimensions)
                  then(<tr>
                         <td>{shared:translate('registry.sources.msDesc.paper.dimensions')}</td>
                         <td>{$msPaperDimensions}</td>
                       </tr>)
                  else if(contains($sourceType,'print'))
                  then(<tr>
                         <td>{shared:translate('registry.sources.msDesc.paper.format')}</td>
                         <td>{$prPaperFormat}</td>
                       </tr>)
                  else('–')}
                  {if($msPaperFolii)
                  then(<tr>
                     <td>{shared:translate('registry.sources.msDesc.paper.folii')}</td>
                     <td>{$msPaperFolii}</td>
                  </tr>)
                  else()}
                  {if($msPaperPages)
                  then(<tr>
                     <td>{shared:translate('registry.sources.msDesc.paper.pages')}</td>
                     <td>{$msPaperPages}</td>
                  </tr>)
                  else()}
                  {if($msPaperPagination)
                  then(<tr>
                         <td>{shared:translate('registry.sources.msDesc.paper.pagination')}</td>
                         <td>{$msPaperPagination}</td>
                       </tr>)
                  else()}
              </table>
return
    $table
};

declare function  source:getManifestationHands($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]

let $hands := $source//mei:handList/mei:hand
let $listOfHands := for $hand in $hands
                    
                    let $type := shared:translate(concat('registry.sources.msDesc.hands.',$hand/@type))
                    let $medium := shared:translate(concat('registry.sources.msDesc.hands.medium.',$hand/@medium))
                    let $text := $hand//text() => string-join(' ')
                    return
                        <li>{if($type) then($type || ', ') else(), $medium, if($text) then(' (' || $text || ')') else()}</li>
let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{shared:translate('registry.sources.msDesc.hands')}</td>
                     <td>
                        <ol>
                            {$listOfHands}
                        </ol>
                     </td>
                  </tr>
              </table>
return
    if($source//mei:handList/mei:hand) then($table) else()
};

declare function  source:getManifestationPaperNotes($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]

let $paperNote := $source//mei:annot[@type="paperNote"]
let $paperNotePlace:= tokenize($paperNote/@place, ' ')
let $paperNotePlaceTranslated := for $token in $paperNotePlace
                                  let $i18n := shared:translate(concat('registry.mei.annot.place.', $token))
                                  return
                                    $i18n
let $tableRow := 
                  <tr>
                     <td>{shared:translate('registry.sources.msDesc.paperNotes')}</td>
                     <td>{concat($paperNote, ' (', string-join($paperNotePlaceTranslated, ' '), ')')}</td>
                  </tr>
return
    if($paperNote) then($tableRow) else()
};


declare function  source:getManifestationStamps($stampNotes as node()*) {

let $listOfStamps := for $stamp in $stampNotes
                        let $stampPlace:= tokenize($stamp/@place, ' ')
                        let $stampPlaceTranslated := for $token in $stampPlace
                                                        let $i18n := shared:translate(concat('registry.mei.annot.place.', $token))
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
                     <td>{shared:translate('registry.sources.msDesc.stamps')}</td>
                     <td><ul style="list-style-type: square;">{$listOfStamps}</ul></td>
                  </tr>
              </table>
return
    $table
};

declare function  source:getManifestationNotes($sourceID as xs:string) {
let $source := $app:collectionSourcesMusic[@xml:id = $sourceID]
let $notes := $source//mei:annot[not(@type)]
let $listOfNotes := for $note in $notes
                        let $notePlace:= tokenize($note/@place, ' ')
                        let $notePlaceTranslated := for $token in $notePlace
                                                          let $i18n := shared:translate(concat('registry.mei.annot.place.', $token))
                                                          return
                                                            $i18n
                        let $noteData := substring-after($note/@data, '#')
                        let $noteCorresp := substring-after($note/@corresp, '#')
                        let $notePage := $source//mei:surface[@xml:id = $noteData]/@label/string()
                        let $correspHand := if($source//mei:hand[@xml:id = $noteCorresp]) then(functx:index-of-node($source//mei:hand, $source//mei:hand[@xml:id = $noteCorresp])) else()
                        return
                            if($correspHand) then(<li><i>{$note/text()}</i>{concat(' [Hand ', $correspHand, ', ', $notePage, ' ', string-join($notePlaceTranslated, ' '), '] ')}</li>)
                            else(<li><i>{$note//text() => string-join('')}</i></li>)
let $table := <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  <tr>
                     <td>{shared:translate('registry.sources.msDesc.notes')}</td>
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

declare function  source:getLyrics($sourceID as xs:string) {
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


declare function source:getPrintPaperFormat($orientation as xs:string, $paperDimensionsHeight as xs:string, $paperDimensionsHeightUnit as xs:string, $paperDimensionsWidth as xs:string, $paperDimensionsWidthUnit as xs:string) as xs:string {

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
            else(shared:translate('registry.sources.msDesc.paper.format.unknown')))
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
            else(shared:translate('registry.sources.msDesc.paper.format.unknown')))
    else(shared:translate('registry.sources.msDesc.paper.format.unknown'))
};

declare function source:getSourceEditionStmt($id, $lang) {
    let $source := $app:collectionSourcesMusic[@xml:id=$id]
    let $edition := $source//mei:editionStmt//mei:edition
    let $editionTitle := $edition/mei:title/text()
    let $editionPublisher := if($edition//mei:publisher/mei:corpName/@codedval)
                             then(shared:getCorpNameFullLinked($edition//mei:publisher/mei:corpName))
                             else($edition//mei:publisher/mei:corpName)
    let $editionPubPlace := $edition//mei:pubPlace
    let $editionDate := if($edition//mei:bibl/mei:date/@*)then(shared:formatDate($edition//mei:date,'full',$lang))else()
    let $editionDedicatee := if($edition//mei:dedicatee/data())
                             then(shared:linkAll($edition//mei:dedicatee))
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
                    <td>{shared:translate('registry.sources.editionStmt.title')}</td>
                    <td>{$editionTitle}</td>
                </tr>)
                else()}
                {if($editionPublisher)
                then(
                <tr>
                    <td>{shared:translate('registry.sources.editionStmt.publisher')}</td>
                    <td>{$editionPublisher}</td>
                </tr>)
                else()}
                {if($editionDate)
                then(
                <tr>
                    <td>{shared:translate('registry.sources.editionStmt.pubDate')}</td>
                    <td>{$editionDate}</td>
                </tr>)
                else()}
                {if($editionPubPlace)
                then(
                <tr>
                    <td>{shared:translate('registry.sources.editionStmt.pubPlace')}</td>
                    <td>{$editionPubPlace}</td>
                </tr>)
                else()}
                {if($editionDedicatee)
                then(
                <tr>
                    <td>{shared:translate('registry.sources.editionStmt.dedication')}</td>
                    <td>{$editionDedicatee}</td>
                </tr>)
                else()}
            </table>
        )
        else()
};

declare function source:renderTitlePage($source as node()*) {
let $titlePage := $source//mei:titlePage

return
    transform:transform($titlePage,doc($config:app-root || '/resources/xslt/formattingTitlePage.xsl'),())

};

(:~
 : Get facsimile preview - delegates to external-requests module
 : 
 : @param $id the document ID
 : @return HTML div with facsimile preview
 : @deprecated Use er:get-facsimile-preview() directly
 :)
declare function source:getFacsimilePreview($id as xs:string) {
    er:get-facsimile-preview($id, $app:collectionSourcesMusic, $app:collectionDocuments)
};
