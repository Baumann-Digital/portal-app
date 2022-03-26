xquery version "3.1";

module namespace baudiWork="http://baumann-digital.de/ns/baudiWork";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace edirom="http://www.edirom.de/ns/1.3";

import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";
import module namespace baudiShared="http://baumann-digital.de/ns/baudiShared" at "/db/apps/baudiApp/modules/baudiShared.xqm";
import module namespace baudiSource="http://baumann-digital.de/ns/baudiSource" at "/db/apps/baudiApp/modules/baudiSource.xqm";
import module namespace baudiPersons="http://baumann-digital.de/ns/baudiPersons" at "/db/apps/baudiApp/modules/baudiPersons.xqm";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="https://exist-db.org/xquery/config" at "/db/apps/baudiApp/modules/config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace transform="http://exist-db.org/xquery/transform";
import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

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
    let $param2 := switch ($param) case 'short' return '.short' default return ''
    let $perfMedium := $work//mei:perfMedium
    let $perfResLists := $perfMedium//mei:perfResList
    
    let $perfResLabelString := for $list at $n in $perfResLists
                                let $listName := $list/@auth
                                let $listType := $list/@type
                                let $perfResLabels := for $perfRes in $list/mei:perfRes
                                                         let $perfResAuth := $perfRes/@auth
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
};

declare function baudiWork:hasStemma($workID as xs:string){
    let $stemmaImg := $app:collectionWorks[@xml:id=$workID]//mei:annot[@type="stemma"]
    return
        if($stemmaImg) then(true()) else(false())
};

declare function baudiWork:getStemma($workID as xs:string, $height as xs:string?, $width as xs:string?) {
    <img src="{concat('https://digilib.baumann-digital.de/BauDi/02/', $workID, '_stemma.png?dh=2000')}" class="img-fluid" alt="Responsive image" height="{$height}" width="{$width}"/>
};


declare function baudiWork:hasIncipitMusic($workID as xs:string){
let $workFile := $app:collectionWorks[@xml:id=$workID]
let $incipit := $workFile//mei:incip[.//mei:score]/node()
return
    if($incipit) then(true()) else(false())
};

declare function baudiWork:getIncipitMusic($workID as xs:string){
let $workFile := $app:collectionWorks[@xml:id=$workID]
let $workFileName := concat($workID, '_incip.mei')
let $incipit := $workFile//mei:incip/node()

let $meiFile := <mei xmlns="http://www.music-encoding.org/ns/mei">
                    <meiHead><fileDesc><titleStmt><title/></titleStmt><pubStmt/></fileDesc></meiHead>
                    <music><body>{$incipit}</body></music>
                </mei>
let $meiFileStored := if(doc-available(concat('/db/apps/baudiWorks/data/', $workFileName)) = false())
                      then(login:set-user("org.exist.login", (), true()),
                           xmldb:store('/db/apps/baudiWorks/data/', $workFileName, $meiFile))
                      else()
let $meiFileCall := concat(substring-before($app:dbRootUrl,'baudiApp'), 'baudiWorks/data/', $workFileName )
let $script :=  <script type="module">
                    import 'https://www.verovio.org/javascript/app/verovio-app.js';
                    
                    const options = {{
                        defaultView: 'responsive', // default is 'responsive', alternative is 'document'
                        defaultZoom: 3, // 0-7, default is 4
                        enableResponsive: true, // default is true
                        enableDocument: true // default is true
                    }}
                    
                    // A MusicXML file
                    // var file = 'https://www.verovio.org/examples/musicxml/Vivaldi_Concerto_No.4_in_F_Minor_Winter.xml';
                    // A MEI file
                    var file = '{$meiFileCall}';
                    
                    const app = new Verovio.App(document.getElementById("appVerovio"), options);
                    fetch(file)
                        .then(function(response) {{
                            return response.text();
                        }})
                        .then(function(text) {{
                            app.loadData(text);
                        }});
                   
               </script> 

return
    if($incipit)
    then(
        <div class="panel-body">
            <div id="appVerovio" class="panel" style="border: 1px solid lightgray; min-height: 100px; max-height: 500px; min-width: 100px; max-width: 1000px;">Verovio is loading...</div>
        </div>,
        $script
        )
        else()
};
