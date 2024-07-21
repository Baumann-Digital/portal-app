xquery version "3.1";

module namespace app = "http://baumann-digital.de/ns/templates";

import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace config = "https://exist-db.org/xquery/config" at "/db/apps/baudiApp/modules/config.xqm";
(:import module namespace baudiVersions="http://baumann-digital.de/ns/versions" at "versions.xqm";:)
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace i18n = "http://exist-db.org/xquery/i18n" at "/db/apps/baudiApp/modules/i18n.xql";
import module namespace baudiShared = "http://baumann-digital.de/ns/baudiShared" at "/db/apps/baudiApp/modules/baudiShared.xqm";
import module namespace baudiWork = "http://baumann-digital.de/ns/baudiWork" at "/db/apps/baudiApp/modules/baudiWork.xqm";
import module namespace baudiSource = "http://baumann-digital.de/ns/baudiSource" at "/db/apps/baudiApp/modules/baudiSource.xqm";
import module namespace baudiLocus = "http://baumann-digital.de/ns/baudiLocus" at "/db/apps/baudiApp/modules/baudiLocus.xqm";
import module namespace baudiPersons="http://baumann-digital.de/ns/baudiPersons" at "/db/apps/baudiApp/modules/baudiPersons.xqm";
import module namespace baudiEditions="http://baumann-digital.de/ns/baudiEditions" at "/db/apps/baudiApp/modules/baudiEditions.xqm";
import module namespace functx = "http://www.functx.com" at "/db/apps/baudiApp/modules/functx.xqm";
import module namespace console="http://exist-db.org/xquery/console";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace edirom = "http://www.edirom.de/ns/1.3";
declare namespace pkg = "http://expath.org/ns/pkg";
declare namespace crapp = "http://www.baumann-digital.de/ns/criticalReport";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare variable $app:digilibPath as xs:string := config:get-option('digilibPath');
declare variable $app:geonames as xs:string := config:get-option('geonames');
declare variable $app:BLBfacPath as xs:string := config:get-option('BLBfacPath');
declare variable $app:BLBfacPathImage as xs:string := config:get-option('BLBfacPathImage');

declare variable $app:collectionWorks := collection($config:data-collection-path || '/works')//mei:work;
declare variable $app:collectionSourcesMusic := collection($config:data-collection-path || '/sources/music')//mei:mei;
declare variable $app:collectionPersons := collection($config:data-collection-path || '/persons')//tei:person;
declare variable $app:collectionInstitutions := collection($config:data-collection-path || '/institutions')//tei:org;
declare variable $app:collectionPeriodicals := collection($config:data-collection-path || '/periodicals')//tei:TEI;
declare variable $app:collectionLoci := collection($config:data-collection-path || '/loci')//tei:place;
declare variable $app:collectionGalleryItems := 0 (:collection($config:data-collection-path || '/galleryItems/data')//tei:TEI:);
declare variable $app:collectionDocuments := collection($config:data-collection-path || '/sources/documents')//tei:TEI;
declare variable $app:collectionEditions := collection($config:data-collection-path || '/editions')//edirom:edition;
declare variable $app:collectionEditionsPath := collection($config:data-collection-path || '/editions');
declare variable $app:collStrTexts := '/db/apps/baudiData/texts';


declare function app:langSwitch($node as node(), $model as map(*)) {
    let $supportedLangVals := ('de', 'en')
    for $lang in $supportedLangVals
        return
            <li class="nav-item">
                <a id="{concat('lang-switch-', $lang)}" class="nav-link" style="{if (baudiShared:get-lang() = $lang) then ('color: white!important;') else ()}" href="" onclick="setCookie('forceLang', '{$lang}', 1)">{upper-case($lang)}</a>
            </li>
};

declare function app:registryDocuments($node as node(), $model as map(*)) {

let $lang := baudiShared:get-lang()
let $documents := $app:collectionDocuments

let $content :=  <div class="container">
                    <div class="container  overflow-auto" style="max-height: 500px;">
                        <div class="tab-content">
                            {let $cards := for $document in $documents
                                            
                                            let $id := $document/@xml:id/string()
                                            let $docType := if($document//tei:correspDesc) then('letter') else('document')
                                            let $titel := $document//tei:fileDesc/tei:titleStmt/tei:title/data()
                                            let $datumSent := $document//tei:correspAction[@type="sent"]/tei:date/@when
                                            let $status := $document/@status/string()
                                            let $statusSymbol := if($status='checked')
                                                                 then(<img src="/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                                                 else if($status='published')
                                                                 then(<img src="/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                                                 else(<img src="/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                                                                  
                                            order by $titel
                                            return
                                                 <div class="card bg-light mb-3">
                                                     <div class="card-body">
                                                       <div class="row justify-content-between">
                                                            <div class="col">
                                                                {if($datumSent)
                                                                then(<h6 class="card-subtitle mb-2 text-muted">{format-date($datumSent, '[D]. [M]. [Y]', $lang, (), ())}</h6>)
                                                                else()}
                                                                <h5 class="card-title">{$titel}</h5>
                                                                <!--<h6 class="card-subtitle mb-2 text-muted"></h6>-->
                                                            </div>
                                                            <div class="col-2">
                                                                <p class="text-right">{$statusSymbol}</p>
                                                            </div>
                                                       </div>
                                                       <p class="card-text"/>
                                                       <a href="/{$id}" class="card-link">{$id}</a>
                                                       <hr/>
                                                       <p>Tags</p>
                                                     </div>
                                                 </div>
                           
                                return
                                    $cards}
                         </div>
                        <br/>
                    </div>
                 </div>
       
return
   $content
};

declare function app:viewDocument($node as node(), $model as map(*)) {
    let $id := request:get-parameter("document-id", "error")
    let $doc := $app:collectionDocuments[@xml:id=$id]
    let $isLetter := exists($doc//tei:correspAction)
    return
        if($isLetter)
        then(app:viewLetter($node, $model))
        else(app:viewDoc($node, $model))
};

declare function app:viewDoc($node as node(), $model as map(*)) {
let $id := request:get-parameter("document-id", "error")
let $doc := $app:collectionDocuments[@xml:id=$id]
let $pages := $doc/tei:text/tei:body/tei:div[@type='page']/@n/normalize-space(data(.))

return
(
<div class="container">
    <div class="page-header">
            <h1>{$doc//tei:fileDesc/tei:titleStmt/tei:title/normalize-space(data(.))}</h1>
            <h5>{$id}</h5>
    </div>
    <ul class="nav nav-pills" role="tablist">
<!--        <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#datenblatt">Datenblatt</a></li>  -->
        <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#inhalt">Inhalt</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#daten">Daten</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#personen">Personen</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#institutionen">Institutionen</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#orte">Orte</a></li>
    </ul>
    <!-- Tab panels -->
    <div class="tab-content">
      <!--  <div class="tab-pane fade show active" id="datenblatt" >
        {transform:transform($dokument,doc("/db/apps/baudiApp/resources/xslt/dokumentDatenblatt.xsl"), ())}
        </div>-->
        <div class="tab-pane fade show active" id="inhalt" >
        {transform:transform($doc//tei:text,doc("/db/apps/baudiApp/resources/xslt/contentDocument.xsl"), ())}
        </div>
   </div>
</div>
)
};

declare function app:viewLetter($node as node(), $model as map(*)) {

let $id := request:get-parameter("document-id", "error")
let $letter := collection("/db/apps/baudiData/sources/documents/letters")//tei:TEI[@xml:id=$id]
let $pages := $letter/tei:text/tei:body/tei:div[@type='page']/@n/normalize-space(data(.))

return
(
<div class="container">
    <div class="page-header">
            <h1>{$letter//tei:fileDesc/tei:titleStmt/tei:title/normalize-space(data(.))}</h1>
            <h5>ID: {$id}</h5>
    </div>
 <ul class="nav nav-pills" role="tablist">
    { 
        for $tab at $pos in $pages
        let $tabCounted := $tab
        let $tabID := concat('#seite-',$tabCounted)
        
        return
    <li class="nav-item"><a class="nav-link {if($pos=1)then('active')else()}" data-toggle="tab" href="{$tabID}" role="tab" aria-controls="{$tabCounted}" aria-selected="false">[Seite {$tabCounted}]</a></li>
    }
    <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#datenblatt" role="tab" aria-controls="home" aria-selected="true">Datenblatt</a></li>
  </ul>
    <!-- Tab panels -->
    <div class="tab-content">
    <div class="tab-pane fade" id="datenblatt" role="tabpanel">
        {transform:transform($letter//tei:teiHeader,doc("/db/apps/baudiApp/resources/xslt/metadataLetter.xsl"), ())}
    </div>
    
    {if (count($pages)=1)
    then(
    <div class="tab-pane fade show active" id="seite-1" role="tabpanel">
    <div class="row">
        <div class="col">
            <br/>
                <div class="col">
                <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#bigPicture">
  Vollansicht
</button>
</div>
                <br/>
                {baudiSource:getFacsimilePreview($id)}
            </div>
        <div class="col">
                <br/>
                <strong>Transkription</strong>
                <br/><br/>
                {transform:transform($letter//tei:text,doc("/db/apps/baudiApp/resources/xslt/contentLetter.xsl"), ())}
        </div>
        <!-- Modal -->
    <div class="modal fade bd-example-modal-lg" id="bigPicture" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
  <div class="modal-header">
        <h5 class="modal-title" id="exampleModalCenterTitle">Seite 1 von 1</h5>
      </div>
      <div class="modal-body">
        {baudiSource:getFacsimilePreview($id)}
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-primary" data-dismiss="modal">Zurück</button>
      </div>
    </div>
  </div>
</div>
        </div>
    </div>
    )
    else(
        for $page at $pos in $pages
        let $letterOrigFacs := concat('https://digilib.baumann-digital.de/BauDi/07/',$letter//tei:div[@type='page' and @n=$page]/@facs)
        let $letterOrigLink := concat('https://digilib.baumann-digital.de/BauDi/07/',$id,'-',$page,'?dw=500')
     
        return
        
    <div class="tab-pane fade {if($pos=1)then('show active')else()}" id="{concat('seite-',$page)}" role="tabpanel">
    <div class="row">
        <div class="col">
                <br/>
                <div class="col">
                <button type="button" class="btn btn-primary" data-toggle="modal" data-target="{concat('#bigPicture',$page)}">
  Vollansicht
</button>
</div>
                <br/><br/>
                <img src="{if (exists($letter//tei:div[@type='page' and @n=$page and @facs])) then($letterOrigFacs) else($letterOrigLink)}" class="img-thumbnail" width="400"/>
       </div>
        <div class="col">
                <br/>
                <strong>Transkription</strong>
                <br/><br/>
                {transform:transform($letter//tei:div[@type='page' and @n=$page],doc("/db/apps/baudiApp/resources/xslt/contentLetter.xsl"), ())}
       </div>
<!-- Modal -->
    <div class="modal fade bd-example-modal-lg" id="{concat('bigPicture',$page)}" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
  <div class="modal-header">
        <h5 class="modal-title" id="exampleModalCenterTitle">{concat('Seite ',$page,' von ',count($pages))}</h5>
      </div>
      <div class="modal-body">
        <img src="{if (exists($letter//tei:div[@type='page' and @n=$page and @facs])) then($letterOrigFacs) else($letterOrigLink)}" class="img-thumbnail"/>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-primary" data-dismiss="modal">Zurück</button>
      </div>
    </div>
  </div>
</div>
    </div>
    </div>
        )
        }
  </div>
  </div>
)
};

declare function app:registryPersons($node as node(), $model as map(*)) {
    
    let $lang := baudiShared:get-lang()
      
    let $content := <div class="container">
                        <div class="container  overflow-auto" style="max-height: 500px;">
                            {let $cards := for $person in $app:collectionPersons
                                            let $id := $person/@xml:id/string()
                                            let $name := baudiShared:getPersName($id, 'short', 'no')
                                            
                                            let $status := $person/@status/string()
                                            let $statusSymbol := if($status='checked')
                                                                 then(<img src="/resources/img/ampel_gelb.png'" alt="{$status}" width="10px"/>)
                                                                 else if($status='published')
                                                                 then(<img src="/resources/img/ampel_gruen.png'" alt="{$status}" width="10px"/>)
                                                                 else(<img src="/resources/img/ampel_rot.png'" alt="{$status}" width="10px"/>)
                                                                  
                                            order by $name
                                             
                                            return
                                                 <div class="card bg-light mb-3" name="{$status}">
                                                     <div class="card-body">
                                                       <div class="row justify-content-between">
                                                            <div class="col">
                                                                <h5 class="card-title">{$name}</h5>
                                                                <h6 class="card-subtitle mb-2 text-muted"></h6>
                                                            </div>
                                                            <div class="col-2">
                                                                <p class="text-right">{$statusSymbol}</p>
                                                            </div>
                                                       </div>
                                                       <p class="card-text"/>
                                                       
                                                       <a href="/{$id}" class="card-link">{$id}</a>
                                                       <hr/>
                                                       <p>Tags</p>
                                                     </div>
                                                 </div>
                                return
                                    $cards
                            }
                        </div>
                        <br/>
                   </div>
       
       return
        $content

};

declare function app:viewPerson($node as node(), $model as map(*)) {
 
let $id := request:get-parameter("person-id", "error")
let $person := $app:collectionPersons/id($id)

let $nameHead := baudiShared:getPersName($id, 'short', 'no')

let $references := baudiShared:getReferences($id)

return
(
<div class="container">
    <br/>
    <div class="page-header">
        <h3>{$nameHead}</h3>
        <h5>{$id}</h5>
    </div>
    <hr/>

    <ul class="nav nav-pills" role="tablist">
        <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#tab1">{baudiShared:translate('baudi.registry.persons.general')}</a></li>  
        {if($references) then(<li class="nav-item"><a class="nav-link" data-toggle="tab" href="#tab2">{baudiShared:translate('baudi.registry.persons.references')}</a></li>) else()}
    </ul>
  <div class="tab-content">
    <div class="tab-pane fade show active" id="tab1">
    <br/>
        <div class="container">
            {if(baudiPersons:getTitle($id))
            then(<div class="row">
                   <div class="col">Titel</div>
                   <div class="col">{baudiPersons:getTitle($id)}</div>
                 </div>)
            else()}
            <div class="row">
              <div class="col">Vorname(n)</div>
              <div class="col">{if(baudiPersons:getFornames($id))
                                then(baudiPersons:getFornames($id))
                                else(baudiShared:translate('baudi.notKnown'))}</div>
            </div>
            {if(baudiPersons:getEpithet($id))
            then(<div class="row">
              <div class="col">Beiname</div>
              <div class="col">{baudiPersons:getEpithet($id)}</div>
            </div>)
            else()}
            {if(baudiPersons:getNameLink($id))
            then(<div class="row">
              <div class="col">Adelsprädikat</div>
              <div class="col">{baudiPersons:getNameLink($id)}</div>
            </div>)
            else()}
            <div class="row">
              <div class="col">Nachname(n)</div>
              <div class="col">{if(baudiPersons:getSurnames($id))
                                then(baudiPersons:getSurnames($id))
                                else(baudiShared:translate('baudi.notKnown'))}</div>
            </div>
            <div class="row">
              <div class="col">Pseudonym</div>
              <div class="col">Spalte 2</div>
            </div>
            {if(baudiPersons:getNickName($id))
            then(<div class="row">
              <div class="col">Spitzname</div>
              <div class="col">{baudiPersons:getNickName($id)}</div>
            </div>)
            else()}
            {if(baudiPersons:getNameUnspec($id))
            then(<div class="row">
              <div class="col">Namensbezeichnung</div>
              <div class="col">{baudiPersons:getNameUnspec($id)}</div>
            </div>)
            else()}
            <div class="row">
              <div class="col">Funktion</div>
              <div class="col">Spalte 2</div>
            </div>
            <div class="row">
              <div class="col">Tätigkeit</div>
              <div class="col">Spalte 2</div>
            </div>
             <div class="row">
              <div class="col">Lebensdaten</div>
              <div class="col">Spalte 2</div>
            </div>
            {if(baudiPersons:getAffiliations($id))
             then(<div class="row">
              <div class="col">Affiliation</div>
              <div class="col">{baudiPersons:getAffiliations($id)}</div>
            </div>)
            else()}
            <div class="row">
              <div class="col">Normdaten</div>
              <div class="col">Spalte 2</div>
            </div>
            <div class="row">
              <div class="col">Besonderes Ereignis</div>
              <div class="col">Spalte 2</div>
            </div>
            <div class="row">
              <div class="col">Wirkungsorte</div>
              <div class="col">Spalte 2</div>
            </div>
            <div class="row">
              <div class="col">Notizen</div>
              <div class="col">Spalte 2</div>
            </div>
        </div>
    </div>
    <br/>
    {if($references)
    then(<div class="tab-pane fade" id="tab2" ><br/><div class="container  overflow-auto" style="max-height: 500px;">{$references}</div></div>)
    else()}
    </div>
</div>
)
};

declare function app:registryLoci($node as node(), $model as map(*)) {

    let $lang := baudiShared:get-lang()
    let $loci := $app:collectionLoci

let $content := 
    <div class="container">
        <div class="container  overflow-auto" style="max-height: 500px;">
            <div class="tab-content">
                {let $cards := for $locus in $loci
                                let $name := $locus/tei:placeName[1]
                                let $id := $locus/@xml:id/string()
                                let $status := $locus/@status/string()
                                let $statusSymbol := if($status='checked')
                                                     then(<img src="/resources/img/ampel_gelb.png'" alt="{$status}" width="10px"/>)
                                                     else if($status='published')
                                                     then(<img src="/resources/img/ampel_gruen.png'" alt="{$status}" width="10px"/>)
                                                     else(<img src="/resources/img/ampel_rot.png'" alt="{$status}" width="10px"/>)
                                let $link :=  if($locus//tei:geo/text() !='') then(<a href="/{$id}" class="card-link">{$id}</a>) else($id) 
                                let $tags := <label class="btn btn-outline-primary btn-sm disabled">{baudiShared:translate(concat('baudi.registry.loci.tag.',$locus/@type))}</label>
                                
                                order by $name
                                return
                                     <div class="card bg-light mb-3" name="{$status}">
                                         <div class="card-body">
                                           <div class="row justify-content-between">
                                                <div class="col">
                                                    <h5 class="card-title">{$name}</h5>
                                                </div>
                                                <div class="col-2">
                                                    <p class="text-right">{$statusSymbol}</p>
                                                </div>
                                           </div>
                                           <p class="card-text"/>
                                           {$link}
                                           <hr/>
                                           {$tags}
                                         </div>
                                     </div>
               
                    return
                        $cards}
             </div>
          </div>
   <br/>
   </div>
       
return
   $content
};

declare function app:viewLocus($node as node(), $model as map(*)) {

let $id := request:get-parameter("locus-id", "error")
let $name := baudiLocus:getLocusName($id)

return
(
    <div class="container">
        <div class="page-header">
            <h1>{$name}</h1>
            <h5>{$id}</h5>
        </div>
        {baudiLocus:getOpenStreetMap($id)}
    </div>
)
};

declare function app:registryInstitutions($node as node(), $model as map(*)) {
    let $lang := baudiShared:get-lang()
    let $orgs := $app:collectionInstitutions
      
    let $content := <div class="container">
    <div class="container  overflow-auto" style="max-height: 500px;">
    <div class="tab-content">
    {let $cards := for $org in $orgs
                    let $name := baudiShared:getOrgNameFull($org)
                    let $id := $org/@xml:id/string()
                    
                    let $status := $org/@status/string()
                    let $statusSymbol := if($status='checked')
                                         then(<img src="/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                         else if($status='published')
                                         then(<img src="/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                         else(<img src="/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                                          
                    order by $name
                     
                    return
                         <div class="card bg-light mb-3" name="{$status}">
                             <div class="card-body">
                               <div class="row justify-content-between">
                                    <div class="col">
                                        <h5 class="card-title">{$name}</h5>
                                        <h6 class="card-subtitle mb-2 text-muted"></h6>
                                    </div>
                                    <div class="col-2">
                                        <p class="text-right">{$statusSymbol}</p>
                                    </div>
                               </div>
                               <p class="card-text"/>
                               
                               <a href="/{$id}" class="card-link">{$id}</a>
                               <hr/>
                               <p>Tags</p>
                             </div>
                         </div>
   
        return
            $cards}
        </div>
      </div>
   <br/>
   </div>
       
       return
        $content

};

declare function app:viewInstitution($node as node(), $model as map(*)) {

let $id := request:get-parameter("institution-id", "error")
let $org := $app:collectionInstitutions[@xml:id=$id]
let $name := if($org) then(baudiShared:getOrgNameFull($org)) else('N.N.')
let $place := $org/tei:location/string()
let $affiliates := for $person in $org//tei:listPerson/tei:person
                    let $persID := $person/tei:persName/@key
                    let $name := $person/tei:persName
                    return
                        <li><a href="{concat('/person/',$persID)}">{$name}</a></li>
return
(
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>{$name}</h1>
            <h5>{$id}</h5>
        </div>
        <br/>
        <div class="col">
            <table class="workView">
                <tr>
                    <th/>
                    <th/>
                </tr>
                <tr>
                    <td>Ort</td>
                    <td>{$place}</td>
                </tr>
                <tr>
                    <td>Personen</td>
                    <td>{$affiliates}</td>
                </tr>
            </table>
        </div>
    </div>
)
};

declare function app:registrySources($node as node(), $model as map(*)) {
    
    let $lang := baudiShared:get-lang()
    let $sources := $app:collectionSourcesMusic//mei:manifestationList/mei:manifestation (:[1]/ancestor::mei:mei:)
    
    let $genres := distinct-values($app:collectionSourcesMusic//mei:term[@type="source"] | $app:collectionSourcesMusic//mei:titlePart[@type='main' and not(@class)]/@type)
    
    let $content :=<div class="container">
    <br/>
         <ul class="nav nav-pills" role="tablist">
         <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">{baudiShared:translate('baudi.registry.sources.all')} ({count($sources)})</a></li>
            {for $genre in $genres
                let $genreCount := count($sources[.//mei:term[@type='source'][. = $genre]])
                let $nav-itemGenre := <li class="nav-item"><a class="nav-link" data-toggle="tab" href="{concat('#',$genre)}">{baudiShared:translate(concat('baudi.registry.sources.',$genre))} ({$genreCount})</a></li>
                order by baudiShared:translate(concat('baudi.registry.sources.',$genre))
                return
                    $nav-itemGenre
             }
    </ul>
    <!-- Tab panels -->
    <div class="container  overflow-auto" style="max-height: 500px;">
    <div class="tab-content">
    {for $genre at $pos in $genres
        let $cards := for $source in $sources[if($genre='main')then(.)else(.//mei:term[@type='source' and . = $genre])]
                         
                         let $id := $source/ancestor::mei:mei/@xml:id/normalize-space(data(.))
                         let $isSourceCollection := if($source//mei:term[@type='source' and .='collection']) then(true()) else(false())
                         let $title := $source//mei:titlePart[@type='main' and not(@class) and not(./ancestor::mei:componentList)]/normalize-space(text()[1])
                         let $titleSort := $title[1]
                         let $titleSub := baudiSource:getManifestationTitle($source,'sub')
                         let $titleSub2 := $source//mei:titlePart[@type='ediromSourceWindow']/normalize-space(text()[1])
                         let $numberOpus := $source/ancestor::mei:mei//mei:title[@type='uniform' and @xml:lang=$lang]/mei:titlePart[@type='number' and @codedval='opus']
                         let $numberOpusCount := $source/ancestor::mei:mei//mei:title[@type='uniform' and @xml:lang=$lang]/mei:titlePart[@type='counter']/text()
                         let $numberOpusCounter := if($numberOpusCount)
                                                   then(concat(' ',baudiShared:translate('baudi.registry.sources.opus.no'),' ',$numberOpusCount))
                                                   else()
                         let $perfMedium := baudiSource:getManifestationPerfResWithAmbitus($source, 'full')
                         let $composer := $source//mei:composer
                         let $lyricist := $source//mei:lyricist
                         let $componentSources := for $componentSource in $source//mei:componentList/mei:manifestation
                                                    let $componentId := $componentSource/mei:identifier/string()
                                                    return
                                                        $componentId
                         let $sourceRelationID := $source//mei:relation[not(@type='edirom')]/@corresp
                         let $termWorkGroup := for $tag in $source//mei:term[@type='workGroup']/string()
                                                let $label := <label class="btn btn-outline-primary btn-sm disabled">{baudiShared:translate(concat('baudi.registry.tag.',$tag))}</label>
                                                return $label
                         let $termGenre := for $tag in $source//mei:term[@type='genre']/string()
                                               let $label := <label class="btn btn-outline-secondary btn-sm disabled">{baudiShared:translate(concat('baudi.registry.tag.',$tag))}</label>
                                               return $label
                         let $termSource := for $tag in $source//mei:term[@type='source']/string()
                                                let $label := <label class="btn btn-outline-danger btn-sm disabled">{baudiShared:translate(concat('baudi.registry.tag.',$tag))}</label>
                                                return $label
                         let $tags := for $each in ($termSource|$termGenre|$termWorkGroup)
                                        order by $each
                                        return ($each,'&#160;')
                         let $order := lower-case(normalize-space(if($titleSort)then($titleSort)else($title)))
                         let $status := $source/ancestor::mei:mei/@status/string()
                         let $statusSymbol := if($status='checked')
                                              then(<img src="/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                              else if($status='published')
                                              then(<img src="/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                              else(<img src="/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                         order by $order
                         return
                             if ($isSourceCollection)
                             then(
                             <div class="card bg-light mb-3" name="{$status}">
                                 <div class="card-body">
                                   <div class="row justify-content-between">
                                        <div class="col">
                                            <h5 class="card-title">{baudiSource:getManifestationTitle($source,'uniform')}</h5>
                                            {if(baudiSource:getManifestationTitle($source,'sub'))then(<h6 class="card-subtitle mb-2">{$titleSub}</h6>)else()}
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                   </div>
                                    {if(count($componentSources)>=1)
                                     then(<p class="card-text"><i>{baudiShared:translate('baudi.registry.sources.components'), concat(' (', count($componentSources), ')')}</i></p>)
                                     else()}
                                   <a href="{concat('/source/', $id)}" class="card-link">{$id}</a>
                                   <hr/>
                                   <p>{$tags}</p>
                                 </div>
                             </div>
                             )
                             else(
                             <div class="card bg-light mb-3" name="{$status}">
                                 <div class="card-body">
                                   <div class="row justify-content-between">
                                        <div class="col">
                                        <h6 class="text-muted">Werk zugewiesen:
                                        {if(contains($sourceRelationID, '-02-'))
                                        then(<i>{baudiWork:getWorkTitle($app:collectionWorks[range:field-eq("work-id", $sourceRelationID)])}</i>,
                                        '&#160;', $sourceRelationID/string())
                                        else('noch nicht erfolgt!')}</h6>
                                            <h5 class="card-title">{baudiSource:getManifestationTitle($source, 'main')}</h5>
                                            {if($titleSub != '')then(<h6 class="card-subtitle mb-2">{baudiSource:getManifestationTitle($source, 'sub')}</h6>)else()}
                                            {if($titleSub2 != '')then(<h6 class="card-subtitle mb-2">{$titleSub2}</h6>)else()}
                                            {if(baudiSource:getManifestationTitle($source, 'perf'))then(<h6 class="card-subtitle-baudi text-muted">{baudiShared:translate('baudi.conjunction.for'), ' ', baudiSource:getManifestationTitle($source, 'perf')}</h6>)else()}
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                   </div>
                                   <p class="card-text">
                                    {if($composer)
                                     then(baudiShared:translate('baudi.registry.sources.composer'),': ',$composer,<br/>)
                                     else()}
                                    {if($lyricist)
                                     then(baudiShared:translate('baudi.registry.sources.lyricist'),': ',$lyricist)
                                     else()}
                                    {if(count($componentSources)>=1)
                                     then(<i>{baudiShared:translate('baudi.registry.sources.components'), concat(' (', count($componentSources), ')')}</i>)
                                     else()}
                                   </p>
                                   <a href="/{$id}" class="card-link">{$id}</a>
                                   <hr/>
                                   <p>{$tags}</p>
                                 </div>
                             </div>)
       
        let $tab := if($genre = 'main')
                    then(<div class="tab-pane fade show active" id="main">
                            <br/>
                            {$cards}
                         </div>)
                    else(<div class="tab-pane fade" id="{$genre}">
                           <br/>
                            {$cards}
                            </div>)
        return
            $tab}
        </div>
      </div>
   <br/>
   </div>
       
       return
        $content
       };

declare function app:viewSource($node as node(), $model as map(*)) {

let $id := request:get-parameter("source-id", "error")
let $lang := baudiShared:get-lang()
let $source := $app:collectionSourcesMusic[@xml:id=$id]
let $manifestation := $source//mei:manifestation
let $fileURI := document-uri($source/root())
let $sourceType := $source//mei:term[@type='source'][1]/string()
let $sourceWorkGroup := $source//mei:term[@type='workGroup'][1]/string()
let $sourceOrig := concat($app:digilibPath,$source/@xml:id)
let $sourceTitleUniform := baudiSource:getManifestationTitle($manifestation,'uniform')
let $sourceTitleMain := baudiSource:getManifestationTitle($manifestation,'main')
let $sourceTitleSub := baudiSource:getManifestationTitle($manifestation,'sub')
let $sourceTitlePerf := baudiSource:getManifestationTitle($manifestation,'perf')

let $sourceComposer := baudiSource:getManifestationPersona($id,'composer')
let $sourceArranger := baudiSource:getManifestationPersona($id,'arranger')
let $sourceEditor := baudiSource:getManifestationPersona($id,'editor')
let $sourceLyricist := baudiSource:getManifestationPersona($id,'lyricist')

let $relatedWorks := $source//mei:relation[@rel="isEmbodimentOf"]
let $relatedWorkID := $source//mei:relation[@rel="isEmbodimentOf"]/string(@corresp)
let $relatedWorkTitle := baudiWork:getWorkTitle($app:collectionWorks/id($relatedWorkID))

let $sourceEditionStmt := baudiSource:getSourceEditionStmt($id, $lang)

let $sourceTitlePage := if($source//mei:titlePage/mei:p/text())
                        then(baudiSource:renderTitlePage($source))
                        else()

let $sourcePerfRes := baudiSource:getManifestationPerfResWithAmbitus($source, 'full')

let $msIdentifiers := baudiSource:getManifestationIdentifiers($id)

let $msCondition := $source//mei:condition/mei:p/text()

let $msPaperSpecs := baudiSource:getManifestationPaperSpecs($id)

let $msHands := baudiSource:getManifestationHands($id)
let $msPaperNotes := baudiSource:getManifestationPaperNotes($id)
let $msStamps := if($source//mei:annot[@type="stamp"])
                 then(baudiSource:getManifestationStamps($source//mei:annot[@type="stamp"]))
                 else()
let $msNotes := if($source//mei:annot[not(@type)]/text())
                then(baudiSource:getManifestationNotes($id))
                else()

let $msScoreFormat := $source//mei:scoreFormat/text()
let $sourcePlateNum := if($source//mei:plateNum/text())
                       then(<tr>
                                <td>{baudiShared:translate('baudi.registry.sources.msDesc.plateNum')}</td>
                                <td>{$source//mei:plateNum/text()}</td>
                            </tr>)
                        else()

let $usedLang := for $lang in $source//mei:langUsage/mei:language/@codedval
                    return
                        baudiShared:translate(concat('baudi.lang.',$lang))
let $key := for $each in $source//mei:key
              let $keyPname := $each/@pname
              let $keyMode := $each/@mode
              let $keyAccid := $each/@accid
              let $keyPnameFull := concat($keyPname,$keyAccid)
              return
                  if($keyMode = 'major')
                  then(concat(
                                functx:capitalize-first(baudiShared:translate(concat('baudi.registry.works.pname.',$keyPnameFull))),
                                baudiShared:translate('baudi.registry.delimiter.key'),
                                baudiShared:translate(concat('baudi.registry.works.',$keyMode))
                             )
                        )
                  else if($keyMode = 'minor')
                  then(concat(
                                baudiShared:translate(concat('baudi.registry.works.pname.',$keyPnameFull)),
                                baudiShared:translate('baudi.registry.delimiter.key'),
                                baudiShared:translate(concat('baudi.registry.works.',$keyMode))
                             )
                      )
                  else()
let $meter := for $each in $source//mei:meter
                let $meterCount := $each/@count
                let $meterUnit := $each/@unit
                let $meterSym := $each/@sym
                let $meterSymbol := if($meterSym = 'common')
                                   then(<img src="/resources/img/timeSignature_common.png" width="20px"/>)
                                   else if($meterSym = 'cut')
                                   then(<img src="/resources/img/timeSignature_cut.png" width="20px"/>)
                                   else()
                return
                    if($meterSymbol)
                    then($meterSymbol)
                    else(concat($meterCount, '/', $meterUnit))
let $tempo := $source//mei:work/mei:tempo/text()

let $sourceHasLyrics := if($source//mei:div[@type="songtext"])then(true())else(false())

return
(
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>{$sourceTitleUniform}</h1>
            <h5>ID: {$id}</h5>
        </div>
        <br/>
        <div class="row">
       {if(exists($source//mei:facsimile/mei:surface))
       then(baudiSource:getFacsimilePreview($id))
        else()}
    <div class="col">
      <ul class="nav nav-pills" role="tablist">
          <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">{baudiShared:translate('baudi.registry.sources.tab.main')}</a></li>  
          <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#detail">{baudiShared:translate('baudi.registry.sources.tab.detail')}</a></li>
          {if($sourceHasLyrics)then(<li class="nav-item"><a class="nav-link" data-toggle="tab" href="#lyrics">{baudiShared:translate('baudi.registry.sources.tab.lyrics')}</a></li>)else()}
          <!--<li class="nav-item"><a class="nav-link" data-toggle="tab" href="#verovio">Verovio</a></li>-->
      </ul>
      <!-- Tab panels -->
      <div class="tab-content">
          <div class="tab-pane fade show active" id="main">
          <div class="container">
          <br/>
              <table class="sourceView">
            <tr>
                <th/>
                <th/>
            </tr>
            <tr>
               <td>{baudiShared:translate('baudi.registry.sources.sourceType')}</td>
               <td>{baudiShared:translate(concat('baudi.registry.sources.',$sourceType))}</td>
            </tr>
            {if($sourceTitleUniform)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.sources.titleUniform')}</td>
                    <td>{$sourceTitleUniform}</td>
                  </tr>)
             else()}
             {if($sourceTitleMain)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.sources.titleMain')}</td>
                    <td>{$sourceTitleMain}</td>
                  </tr>)
             else()}
             {if($sourceTitleSub)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.sources.titleSub')}</td>
                    <td>{$sourceTitleSub}</td>
                  </tr>)
             else()}
             </table>
             <table class="sourceView">
                {if(exists($relatedWorkID))
                then(<tr>
                       <td>{baudiShared:translate('baudi.registry.sources.relation')}</td>
                       <td>{if(exists($relatedWorkID))then(<a href="{$relatedWorkID}">{$relatedWorkTitle}</a>)else(baudiShared:translate('baudi.unknown'))}</td>
                     </tr>)
                else()}
             {if($sourceComposer)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.sources.composer')}</td>
                    <td>{$sourceComposer}</td>
                  </tr>)
             else()}
             {if($sourceArranger)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.sources.arranger')}</td>
                    <td>{$sourceArranger}</td>
                  </tr>)
             else()}
             {if($sourceLyricist or $sourceWorkGroup = 'vocal')
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.sources.lyricist')}</td>
                    <td>{if($sourceLyricist) then($sourceLyricist)
                        else if ($source//mei:manifestation//mei:lyricist/text() != '') then($source//mei:manifestation//mei:lyricist/text()) else(baudiShared:translate('baudi.unknown'))}</td>
                  </tr>)
             else()}
             {if($sourceEditor)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.sources.editor')}</td>
                    <td>{$sourceEditor}</td>
                  </tr>)
             else()}
             </table>
             <table class="sourceView">
             {if(not($usedLang/data(.) = ''))
             then(<tr>
                    <td>{if(count($usedLang) = 1)
                         then(baudiShared:translate('baudi.registry.works.langUsed'))
                         else if(count($usedLang) > 1)
                         then(baudiShared:translate('baudi.registry.works.langsUsed'))
                         else()}</td>
                    <td>{string-join($usedLang,', ')}</td>
                  </tr>)
             else()}
             
             {if(count($key) > 0)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.works.key')}</td>
                    <td>{normalize-space(string-join($key, ' | '))}</td>
                  </tr>)
             else()}
             {if(count($meter) > 0)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.works.meter')}</td>
                    <td>{$meter}</td>
                  </tr>)
             else()}
             {if($tempo)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.works.tempo')}</td>
                    <td><i>{normalize-space($tempo)}</i></td>
                  </tr>)
             else()}
             {if($sourcePerfRes)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.sources.perfRes')}</td>
                    <td>{$sourcePerfRes}</td>
                  </tr>)
             else()}
             </table>
              </div>
          </div>
          <div class="tab-pane fade" id="detail">
              <div class="container">
              <br/>
                {$msIdentifiers}
                {if($sourceEditionStmt)
                 then($sourceEditionStmt)
                 else()}
                {if ($msPaperSpecs)
                 then ($msPaperSpecs)
                 else ()}
                 {if ($msHands)
                 then ($msHands)
                 else ()}
                 {if ($msPaperNotes or $sourcePlateNum)
                 then (
                 <table class="sourceView">
                  <tr>
                      <th/>
                      <th/>
                  </tr>
                  {$msPaperNotes}
                  {$sourcePlateNum}
                  </table>)
                 else ()}
                 {if ($msStamps)
                 then ($msStamps)
                 else ()}
                 {if ($msNotes)
                 then ($msNotes)
                 else ()}
                 {if ($msScoreFormat)
                 then (<table class="sourceView">
                           <tr>
                             <th/>
                             <th/>
                           </tr>
                           <tr>
                             <td>{baudiShared:translate('baudi.registry.sources.msDesc.scoreFormat')}</td>
                             <td>
                               {$msScoreFormat}
                             </td>
                           </tr>
                       </table>)
                 else ()}
                 {if ($msCondition)
                 then (<table class="sourceView">
                           <tr>
                             <th/>
                             <th/>
                           </tr>
                           <tr>
                             <td>{baudiShared:translate('baudi.registry.sources.msDesc.condition')}</td>
                             <td>
                               {$msCondition}
                             </td>
                           </tr>
                       </table>)
                 else ()}
                 {if($sourceTitlePage)
                  then(<br/>, $sourceTitlePage, <br/>)
                  else()}
              </div>
          </div>
          {if($sourceHasLyrics)
          then(
          <div class="tab-pane fade" id="lyrics">
             <div class="container">
                <table class="sourceView">
                     <tr>
                       <th/>
                       <th/>
                     </tr>
                     <tr>
                         {baudiSource:getLyrics($id)}
                     </tr>
                 </table>
             </div>
          </div>)
          else()}
          <!--<div class="tab-pane fade" id="verovio">
              <div class="panel-body">
                  <div id="app" class="panel" style="border: 1px solid lightgray; min-height: 800px;"/>
              </div>
          </div>-->
      </div>
    </div>
    </div>
    </div>
)
};


declare function app:aboutProject($node as node(), $model as map(*)) {

let $text := doc(concat($app:collStrTexts,'/portal/aboutProject.xml'))/tei:TEI


return
(
    <div class="container">
    <br/>
        {baudiShared:getI18nText($text)}
    </div>
)
};

declare function app:aboutBaumann($node as node(), $model as map(*)) {

let $text := doc(concat($app:collStrTexts, "/portal/aboutBaumann.xml"))/tei:TEI

return
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>Ludwig Baumann <span class="text-muted" style="font-size: x-large;">(1866–1944)</span></h1>
        <hr/>
        </div>
            {baudiShared:getI18nText($text)
            (: transform:transform($text, doc("/db/apps/baudiApp/resources/xslt/formattingText.xsl"), ()) :)}
    </div>
};

declare function app:impressum($node as node(), $model as map(*)) {

let $text := doc(concat($app:collStrTexts, "/portal/impressum.xml"))//tei:body

return
(
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>Impressum</h1>
        </div>
        <hr/>
        <div class="container">
            {transform:transform($text,doc("/db/apps/baudiApp/resources/xslt/formattingText.xsl"), ())}
        </div>
    </div>
)
};

declare function app:indexPage($node as node(), $model as map(*)) {

let $text := doc(concat($app:collStrTexts, '/portal/index.xml'))

return
(
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>Startseite</h1>
        </div>
        <hr/>
        <div class="container">
            {transform:transform($text,doc("/db/apps/baudiApp/resources/xslt/formattingText.xsl"), ())}
        </div>
    </div>
)
};

declare function app:registryPeriodicals($node as node(), $model as map(*)) {

let $collection := $app:collectionPeriodicals

let $cards := for $item in $collection
                let $id := $item/@xml:id/string()
                let $title := $item//tei:sourceDesc//tei:title[@type="main"]/text()
                let $titleSub := for $each in $item//tei:series/tei:title/text()
                                    return
                                        ($each,<br/>)
                let $titleIssue := $item//tei:fileDesc/tei:titleStmt/tei:title/text()
                let $publisher := $item//tei:sourceDesc//tei:publisher/text()
                let $pubPlace := $item//tei:sourceDesc//tei:pubPlace/text()
                let $pubDate := $item//tei:sourceDesc//tei:date/text()
                let $volume := $item//tei:sourceDesc//tei:biblScope[@unit="volume"]/text()
                let $issue := $item//tei:sourceDesc//tei:biblScope[@unit="issue"]/text()
                let $status := $item//tei:publicationStmt/tei:p
                let $statusSymbol := if($status='checked')
                                              then(<img src="/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                              else if($status='published')
                                              then(<img src="/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                              else(<img src="/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)

                return
                    <div class="card bg-light mb-3">
                        <div class="card-body">
                            <div class="row justify-content-between">
                                <div class="col">
                                    <h5 class="card-title">{$title}</h5>
                                    {if($titleSub !='')then(<h6>{$titleSub}</h6>)else()}
                                </div>
                                <div class="col-2">
                                    <p class="text-right">{$statusSymbol}</p>
                                </div>
                            </div>
                            <p class="card-text">
                                {concat($publisher, ' ', $pubPlace, ' (', $pubDate, ')')}
                                <br/>
                                {concat('Jg. ', $volume, ' H. ', $issue)}
                            </p>
                            <hr/>
                            <a href="/{$id}" class="card-link">{$id}</a>
                        </div>
                    </div>
        
return
(
<div class="container">
        <br/>
        <div class="page-header">
            <h1><i18n:text key="baudi.registry.periodocals"/></h1>
        </div>
        <hr/>
        <div class="container">
            <div class="container  overflow-auto" style="max-height: 500px;">
                {$cards}
            </div>
            <br/>
        </div>
    </div>
)
};

declare function app:viewPeriodical($node as node(), $model as map(*)) {
 
let $id := request:get-parameter("periodical-id", "error")
let $issue := $app:collectionPeriodicals[@xml:id=$id]
let $titleIssue := $issue//tei:fileDesc/tei:titleStmt/tei:title/text()
let $text := $issue//tei:body

return
  <div class="container">
      <br/>
      <div class="page-header">
          <h3>{$titleIssue}</h3>
          <h5>{$id}</h5>
      </div>
      <hr/>
  
      <ul class="nav nav-pills" role="tablist">
          <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#tab1">Inhalt</a></li>  
          <!--<li class="nav-item"><a class="nav-link" data-toggle="tab" href="#tab2">Erwähnungen</a></li>-->
      </ul>
      <div class="tab-content">
          <div class="tab-pane fade show active" id="tab1">
              <br/>
              {transform:transform($text,doc("/db/apps/baudiApp/resources/xslt/formattingText.xsl"), ())}
          </div>
      </div>
  </div>
};

declare function app:guidelines($node as node(), $model as map(*)) {

let $codingGuidelines := doc(concat($app:collStrTexts,'/documentation/codingGuidelines.xml'))
let $editiorialGuidelines := doc(concat($app:collStrTexts,'/documentation/editorialGuidelines.xml'))
let $sourceDescGuidelines := doc(concat($app:collStrTexts,'/documentation/sourceDescGuidelines.xml'))

return
(
<div class="container">
        <ul class="nav nav-pills" role="tablist">
        <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#coding">Kodierung</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#edition">Edition</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#sourceDesc">Quellenbeschreibung</a></li>
    </ul>
    <!-- Tab panels -->
    <div class="tab-content">
        <div class="tab-pane fade show active" id="coding" >
        {transform:transform($codingGuidelines,doc("/db/apps/baudiApp/resources/xslt/contentCodingGuidelines.xsl"), ())}
        </div>
        <div class="tab-pane fade" id="edition" >
        {transform:transform($editiorialGuidelines,doc("/db/apps/baudiApp/resources/xslt/contentEditorialGuidelines.xsl"), ())}
        </div>
        <div class="tab-pane fade" id="sourceDesc" >
        {transform:transform($sourceDescGuidelines,doc("/db/apps/baudiApp/resources/xslt/contentSourceDescGuidelines.xsl"), ())}
        </div>
   </div>
    </div>
)
};

declare function app:registryWorks($node as node(), $model as map(*)) {
    
    let $works := $app:collectionWorks[not(parent::mei:componentList)]
    let $genres := distinct-values($app:collectionWorks//mei:term[@type="genre"]/text() | $app:collectionWorks//mei:titlePart[@type='main' and not(@class)]/@type)
    let $content := <div class="container">
         <ul class="nav nav-pills" role="tablist">
            <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">{baudiShared:translate('baudi.registry.works.all')} ({count($works)})</a></li>
            {for $genre at $pos in $genres[. != 'main']
                let $workCount := count($works//mei:term[@type='genre' and . = $genre])
                let $nav-itemGenre := <li class="nav-item"><a class="nav-link" data-toggle="tab" href="{concat('#',$genre)}">{baudiShared:translate(concat('baudi.registry.works.',$genre))} ({$workCount})</a></li>
                order by baudiShared:translate(concat('baudi.registry.works.',$genre))
                return
                    $nav-itemGenre
             }
    </ul>
    <hr/>
    <br/>
    <!-- Tab panels -->
    <div class="container overflow-auto" style="max-height: 600px;">
    <div class="tab-content">
    {for $genre at $pos in $genres
        let $cards := for $work in $works[if($pos=1)then(.)else(.//mei:term[@type='genre' and . = $genre])]
                         let $title := $work//mei:title[@type='uniform']/mei:titlePart[range:field-eq("titlePart-main", 'main') and not(@class)]/normalize-space(text()[1])
                         let $titleSort := $work//mei:title[@type='uniform']/mei:titlePart[@type='mainSort']/text()
                         let $titleSub := $work//mei:title[@type='uniform']/mei:titlePart[@type='subordinate']/normalize-space(text()[1])
                         let $numberOpus := $work//mei:title[@type='uniform']/mei:titlePart[@type='number' and @codedval='opus']
                         let $numberOpusCount := $work//mei:title[@type='uniform']/mei:titlePart[@type='counter']/text()
                         let $numberOpusCounter := if($numberOpusCount)
                                                   then(concat(' ',baudiShared:translate('baudi.registry.works.opus.no'),' ',$numberOpusCount))
                                                   else()
                         let $workID := $work/@xml:id/string()
                         let $composerID := $work//mei:composer//@codedval
                         let $composer := if($work//mei:composer//@codedval)
                                          then(baudiShared:getPersName($composerID, 'short', 'yes'))
                                          else($work//mei:composer/string())
                         let $arrangerID := $work//mei:arranger//@codedval
                         let $arranger := if($work//mei:arranger//@codedval)
                                          then(baudiShared:getPersName($arrangerID, 'short', 'yes'))
                                          else($work//mei:arranger/string())
                         let $lyricistID := $work//mei:lyricist//@codedval
                         let $lyricist := if($work//mei:lyricist//@codedval)
                                          then(baudiShared:getPersName($lyricistID, 'short', 'yes'))
                                          else($work//mei:lyricist/string())
                         let $editorID := $work//mei:editor//@codedval
                         let $editor := if($editorID)
                                        then(baudiShared:getPersName($editorID, 'short', 'yes'))
                                        else($work//mei:editor/string())
                         let $componentWorksCount := count($work//mei:componentList/mei:work)
                         (:for $componentWork in $work//mei:componentList/mei:work
                                                    let $componentId := $componentWork/mei:identifier[@type="baudiWork"]/string()
                                                    return
                                                        $works[@xml:id=$componentId]:)
                         let $relatedItemsCount := count($work//mei:relationList/mei:relation)
                         (:for $rel in $work//mei:relationList/mei:relation
                                                let $relationTarget := $rel/@target
                                                return
                                                    $app:collectionSourcesMusic[range:field-eq("relation-target", @xml:id)]:)
                         let $termWorkGroup := for $tag in $work//mei:term[@type='workGroup']/text()
                                                let $label := <label class="btn btn-outline-primary btn-sm disabled">{baudiShared:translate(concat('baudi.registry.works.',$tag))}</label>
                                                return $label
                         let $termGenre := for $tag in $work//mei:term[@type='genre']/text()
                                               let $label := <label class="btn btn-outline-secondary btn-sm disabled">{baudiShared:translate(concat('baudi.registry.works.',$tag))}</label>
                                               return $label
                         let $tags := for $each in ($termGenre|$termWorkGroup)
                                        return ($each,'&#160;')
                         let $order := lower-case(normalize-space(if($titleSort)then($titleSort)else($title)))
                         let $status := $work/@status/string()
                         let $statusSymbol := if($status='checked')
                                              then(<img src="/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                              else if($status='published')
                                              then(<img src="/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                              else(<img src="/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                         order by $order
                         return
                             <div class="card bg-light mb-3" name="{$status}">
                                 <div class="card-body">
                                    <div class="row justify-content-between">
                                        <div class="col">
                                            <h5 class="card-title">{baudiWork:getWorkTitle($work)}</h5>
                                            {if($titleSub !='')then(<h6>{$titleSub}</h6>)else()}
                                            <h6 class="card-subtitle-baudi text-muted">{baudiShared:translate('baudi.conjunction.for'), ' ', baudiWork:getPerfRes($work, 'short')}</h6>
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                    </div>
                                    <p class="card-text">{if($composer)
                                                         then(baudiShared:translate(concat('baudi.registry.works.composer',baudiShared:checkGenderforLangValues($composerID))),': ',$composer,<br/>)
                                                         else()}
                                                         {if($arranger)
                                                         then(baudiShared:translate(concat('baudi.registry.works.arranger',baudiShared:checkGenderforLangValues($arrangerID))),': ',$arranger,<br/>)
                                                         else()}
                                                        {if($lyricist)
                                                         then(baudiShared:translate(concat('baudi.registry.works.lyricist',baudiShared:checkGenderforLangValues($lyricistID))),': ',$lyricist,<br/>)
                                                         else()}
                                                         {if($editor)
                                                         then(baudiShared:translate(concat('baudi.registry.works.editor',baudiShared:checkGenderforLangValues($editorID))),': ',$editor,<br/>)
                                                         else()}
                                                        {if($componentWorksCount >= 1)
                                                         then(concat(baudiShared:translate('baudi.registry.works.components'),': ',
                                                                $componentWorksCount),<br/>)
                                                         else()}
                                                         {if($relatedItemsCount >= 1)
                                                         then(concat(baudiShared:translate('baudi.registry.works.relSources'), ': ',
                                                                $relatedItemsCount),<br/>)
                                                         else()}</p>
                                   <a href="/{$workID}" class="card-link">{$workID}</a>
                                   <hr/>
                                   <p>{$tags}</p>
                                 </div>
                             </div>
        
        let $tab := if($genre = 'main')
                    then(<div class="tab-pane fade show active" id="main">
                            <br/>
                            {$cards}
                         </div>)
                    else(<div class="tab-pane fade" id="{$genre}">
                           <br/>
                            {$cards}
                         </div>)
        return
            $tab}
        </div>
      </div>
   <br/>
   </div>
       
       return
        $content
       };
       
declare function app:viewWork($node as node(), $model as map(*)) {

let $workID := request:get-parameter("work-id", "error")
let $lang := baudiShared:get-lang()
let $work := $app:collectionWorks//mei:work[@xml:id=$workID]
let $fileURI := document-uri($work/root())
let $title := $work//mei:title[@type='uniform']/mei:titlePart[@type='main' and not(@class)]/normalize-space(.)
let $subtitle := $work//mei:title[@type='uniform']/mei:titlePart[@type = 'subordinate']/normalize-space(.)
let $numberOpus := $work//mei:title[@type='uniform']/mei:titlePart[@type='number' and @codedval='opus']
let $titlePerfMedium := $work//mei:title[@type='uniform']/mei:titlePart[@type = 'perfmedium']
let $titleMainAlt := $work//mei:titlePart[@type = 'mainAlt']
let $titleSubAlt := $work//mei:title[@type='uniform']/mei:titlePart[@type = 'subAlt']
let $composer := $work//mei:composer
let $composerID := $composer/mei:persName/@codedval
let $composerEntry := $app:collectionPersons/id($composerID)
let $composerName := baudiShared:getPersName($composerID, 'short', 'yes')
let $composerGender := if($composerEntry[@sex="female"]) then('composer.female') else('composer')
let $lyricist := $work//mei:lyricist
let $lyricistID := $lyricist/mei:persName/@codedval
let $lyricistEntry := $app:collectionPersons/id($lyricistID)
let $lyricistName := if($lyricistID)then(baudiShared:getPersName($lyricistID, 'short', 'yes'))else($lyricist//text()/normalize-space())
let $lyricistGender := if($lyricistEntry)
                       then('lyricist.female')
                       else('lyricist')

let $usedLang := for $lang in $work//mei:langUsage/mei:language/@codedval
                    return
                        baudiShared:translate(concat('baudi.lang.',$lang))
let $key := for $each in $work//mei:key
              let $keyPname := $each/@pname
              let $keyMode := $each/@mode
              let $keyAccid := $each/@accid
              let $keyPnameFull := concat($keyPname,$keyAccid)
              return
                  if($keyMode = 'major')
                  then(concat(
                                functx:capitalize-first(baudiShared:translate(concat('baudi.registry.works.pname.',$keyPnameFull))),
                                baudiShared:translate('baudi.registry.delimiter.key'),
                                baudiShared:translate(concat('baudi.registry.works.',$keyMode))
                             )
                        )
                  else if($keyMode = 'minor')
                  then(concat(
                                baudiShared:translate(concat('baudi.registry.works.pname.',$keyPnameFull)),
                                baudiShared:translate('baudi.registry.delimiter.key'),
                                baudiShared:translate(concat('baudi.registry.works.',$keyMode))
                             )
                      )
                  else()
let $meter := for $each in $work//mei:meter
                let $meterCount := $each/@count
                let $meterUnit := $each/@unit
                let $meterSym := $each/@sym
                let $meterSymbol := if($meterSym = 'common')
                                   then(<img src="/resources/img/timeSignature_common.png" width="20px"/>)
                                   else if($meterSym = 'cut')
                                   then(<img src="/resources/img/timeSignature_cut.png" width="20px"/>)
                                   else()
                return
                    if($meterSymbol)
                    then($meterSymbol)
                    else if($meterCount and $meterUnit)
                    then(concat($meterCount, '/', $meterUnit))
                    else()
let $tempo := $work//mei:work/mei:tempo/text()

let $incipText := $work//mei:incip/mei:incipText//text() => string-join(' ')

let $workgroup := $work//mei:term[@type='workGroup']/text()
let $genre := $work//mei:term[@type='genre']/text()

let $perfMedium := baudiWork:getPerfRes($work, 'detailShort')

let $relatedSourcesCards := for $source in $app:collectionSourcesMusic
                let $sourceId := $source/@xml:id/string()
                let $sourceType := $source//mei:term[@type='source'][1]/string()
                let $sourceTypeTranslated := baudiShared:translate(concat('baudi.registry.sources.',$sourceType))
                let $sort := switch ($sourceType)
                                case 'manuscript' return '01'
                                case 'msCopy' return '02'
                                case 'print' return '03'
                                case 'prCopy' return '04'
                                case 'copy' return '05'
                                case 'edition' return '06'
                                default return '00'
                let $correspWork := $source//mei:relation[@corresp=$workID]/@corresp
                let $correspWorkLabel := $source//mei:relation[@corresp=$workID]/@label/string()
                let $sourceTitle := $source//mei:manifestation//mei:titlePart[@type='main' and not(@class) and not(./ancestor::mei:componentList)]/normalize-space(text()[1])
                let $ediromSourceWindow := $source//mei:manifestation//mei:titlePart[@type='ediromSourceWindow'][1]/normalize-space(.)
                where $correspWork = $workID
                order by $sort ascending, lower-case($ediromSourceWindow) ascending
                return
                    (<div class="row justify-content-md-center" style="padding-bottom: 25px;">
                      <div class="card col-8" sortNo="{$sort}">
                          <div class="card-body">
                          <h5 class="card-title">{$sourceTitle}</h5>
<!--                            <h5 class="card-title">{functx:substring-before-if-contains($ediromSourceWindow, ' (')}</h5>-->
                            <h6 class="card-subtitle text-muted mt-0">{substring-before(substring-after($ediromSourceWindow, ' ('), ')')}</h6>
                            <!--<p class="card-text">Some quick example text to build on the card title and make up the bulk of the card's content.</p>-->
                            <a class="card-link" href="/{$sourceId}">{$sourceId}</a>
                          </div>
                      </div>
                    </div>)

let $incipURI := concat('http://localhost:8080/exist/rest',$fileURI) (: '?_query=//incip' :)

let $editions := $app:collectionEditions[.//edirom:work[@xml:id=$workID]]
let $editionsContent :=
    for $edition in $editions
        let $editionId := $edition/string(@xml:id)
        return
            (<div class="row justify-content-md-center" style="padding-bottom: 25px;">
              <div class="card col-8">
                  <div class="card-body">
                    <h5 class="card-title">{baudiWork:getWorkTitle($work)}</h5>
                    <h6 class="card-subtitle text-muted mt-0">Neuedition</h6>
                    <!--<p class="card-text">Some quick example text to build on the card title and make up the bulk of the card's content.</p>-->
                    <a class="card-link" href="/{$editionId}">{$editionId}</a>
                  </div>
              </div>
            </div>)

return
(
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>{if($numberOpus)then(concat($title,' op. ',$numberOpus))else($title)}</h1>
            {if($subtitle)then(<h4 class="text-muted">{$subtitle}</h4>)else()}
            <h5>ID: {$workID}</h5>
        </div>
        <br/>
    <ul class="nav nav-pills mb-3" id="pills-tab" role="tablist">
       <li class="nav-item">
         <a class="nav-link active" id="pills-main-tab" data-toggle="pill" href="#pills-main" role="tab" aria-controls="pills-main" aria-selected="true">Überblick</a>
       </li>
       {if(baudiEditions:hasEditions($workID))
        then(<li class="nav-item">
         <a class="nav-link" id="pills-edition-tab" data-toggle="pill" href="#pills-edition" role="tab" aria-controls="pills-edition" aria-selected="false">Edition</a>
       </li>)
       else()}
       <li class="nav-item">
         <a class="nav-link" id="pills-edition-tab" data-toggle="pill" href="#pills-xml" role="tab" aria-controls="pills-xml" aria-selected="false">XML</a>
       </li>
    </ul>
    <div class="tab-content" id="pills-tabContent">
  <div class="tab-pane fade show active" id="pills-main" role="tabpanel" aria-labelledby="pills-main-tab">
        <table class="workView">
            <tr>
                <th/>
                <th/>
            </tr>
            {if($titlePerfMedium != '')
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.works.perfmedium')}</td>
                    <td>{normalize-space($titlePerfMedium)}</td>
                  </tr>)
             else()}
             {if($titleMainAlt)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.works.titleAlt')}</td>
                    <td>{normalize-space($titleMainAlt)}</td>
                  </tr>)
             else()}
             {if($titleSubAlt)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.works.subtitleAlt')}</td>
                    <td>{normalize-space($titleSubAlt)}</td>
                  </tr>)
             else()}
             {if($composerName != '')
             then(<tr>
                    <td>Musik</td>
                    <td>{$composerName}</td>
                  </tr>)
             else()}
             {if($lyricistName != '')
             then(<tr>
                    <td>Text</td>
                    <td>{$lyricistName}</td>
                  </tr>)
             else()}
             {if($usedLang/data(.) != '')
             then(<tr>
                    <td>{if(count($usedLang) = 1)
                         then(baudiShared:translate('baudi.registry.works.langUsed'))
                         else if(count($usedLang) > 1)
                         then(baudiShared:translate('baudi.registry.works.langsUsed'))
                         else()}</td>
                    <td>{string-join($usedLang,', ')}</td>
                  </tr>)
             else()}
             <!-- {if($incipText != '')
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.works.incipit.text')}</td>
                    <td><em>{$incipText}</em></td>
                  </tr>)
             else()} -->
             {if(exists($key))
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.works.key')}</td>
                    <td>{normalize-space(string-join($key, ' | '))}</td>
                  </tr>)
             else()}
             {if($meter)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.works.meter')}</td>
                    <td>{$meter}</td>
                  </tr>)
             else()}
             {if($tempo)
             then(<tr>
                    <td>{baudiShared:translate('baudi.registry.works.tempo')}</td>
                    <td><i>{normalize-space($tempo)}</i></td>
                  </tr>)
             else()}
             {if($workgroup)
             then(<tr>
                    <td>Werkklasse</td>
                    <td>{string-join(for $each in $workgroup return baudiShared:translate(concat('baudi.registry.works.',$each)),' | ')}</td>
                  </tr>)
             else()}
             {if($genre)
             then(<tr>
                    <td>Werkgruppe</td>
                    <td>{baudiShared:translate(concat('baudi.registry.works.',$genre))}</td>
                  </tr>)
             else()}
             {if($perfMedium != '')
             then(<tr>
                    <td style="vertical-align: top;">{baudiShared:translate('baudi.registry.works.perfRes')}</td>
                    <td>{baudiWork:getPerfRes($work,'detailShort')}</td>
                  </tr>)
             else()}
             </table>
         <!--{if(baudiWork:hasIncipitMusic($workID))
         then(<br/>,
              <h4>{baudiShared:translate('baudi.registry.works.incipit')}</h4>,
              <br/>,
              baudiWork:getIncipitMusic($workID))
         else()}-->
        {if($relatedSourcesCards)
        then(
        <div>
           <br/>
           <h4>{baudiShared:translate('baudi.registry.works.relSources')}</h4>
           <br/>
           <div class="container overflow-auto" style="max-height: 500px;">
            {$relatedSourcesCards}
            </div>
           <br/>
        </div>)
        else()}
        </div>
        {if(baudiWork:hasStemma($workID))
        then(<div class="tab-pane fade" id="pills-stemma" role="tabpanel" aria-labelledby="pills-stemma-tab">
            {baudiWork:getStemma($workID, '', '')}
        </div>)
        else()}
        {if(baudiEditions:hasEditions($workID))
        then(<div class="tab-pane fade" id="pills-edition" role="tabpanel" aria-labelledby="pills-edition-tab">
            {$editionsContent}
        </div>)
        else()}
        <div class="tab-pane fade" id="pills-xml" role="tabpanel" aria-labelledby="pills-xml-tab">
            <div class="card" style="background: aliceblue;">
                <div class="card-body">
                    <pre><code>{serialize(app:process-xml-for-display($work), <output:serialization-parameters><output:method>xml</output:method><output:media-type>application/xml</output:media-type><output:indent>no</output:indent></output:serialization-parameters>)}</code></pre>
                </div>
            </div>
        </div>
    </div>
</div>
)
};

declare function app:registryEditions($node as node(), $model as map(*)) {
    let $editions := $app:collectionEditions//edirom:work
    let $content := <div class="container">
         <!--
         <ul class="nav nav-pills" role="tablist">
            <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">{baudiShared:translate('baudi.registry.works.all')} ({count($works)})</a></li>
            {for $genre at $pos in $genres[. != 'main']
                let $workCount := count($works//mei:term[@type='genre' and . = $genre])
                let $nav-itemGenre := <li class="nav-item"><a class="nav-link" data-toggle="tab" href="{concat('#',$genre)}">{baudiShared:translate(concat('baudi.registry.works.',$genre))} ({$workCount})</a></li>
                order by baudiShared:translate(concat('baudi.registry.works.',$genre))
                return
                    $nav-itemGenre
             }
    </ul>
    <hr/>
         -->
    <br/>
    <!-- Tab panels -->
    <div class="container overflow-auto" style="max-height: 600px;">
    <div class="tab-content">
    {
        let $cards := for $edition in $editions
                         let $workID := $edition/@xml:id
                         let $work := $app:collectionWorks/id($workID)
                         let $editionID := $edition/ancestor::edirom:edition/@xml:id/string()
                         let $title := $work//mei:title[@type='uniform']/mei:titlePart[@type='main' and not(@class)]/normalize-space(text()[1])
                         let $titleSort := $work//mei:title[@type='uniform']/mei:titlePart[@type='mainSort']/text()
                         let $titleSub := $work//mei:title[@type='uniform']/mei:titlePart[@type='subordinate']/normalize-space(text()[1])
                         let $numberOpus := $work//mei:title[@type='uniform']/mei:titlePart[@type='number' and @codedval='opus']
                         let $numberOpusCount := $work//mei:title[@type='uniform']/mei:titlePart[@type='counter']/text()
                         let $numberOpusCounter := if($numberOpusCount)
                                                   then(concat(' ',baudiShared:translate('baudi.registry.works.opus.no'),' ',$numberOpusCount))
                                                   else()
                         let $composer := if($work//mei:composer//@codedval)
                                          then(baudiShared:getPersName($work//mei:composer//@codedval, 'short', 'yes'))
                                          else($work//mei:composer/string())
                         let $arranger := if($work//mei:arranger//@codedval)
                                          then(baudiShared:getPersName($work//mei:arranger//@codedval, 'short', 'yes'))
                                          else($work//mei:arranger/string())
                         let $lyricist := if($work//mei:lyricist//@codedval)
                                          then(baudiShared:getPersName($work//mei:lyricist//@codedval, 'short', 'yes'))
                                          else($work//mei:lyricist/string())
                         let $editor := if($work//mei:editor//@codedval)
                                        then(baudiShared:getPersName($work//mei:editor//@codedval, 'short', 'yes'))
                                        else($work//mei:editor/string())
                         let $order := lower-case(normalize-space(if($titleSort)then($titleSort)else($title)))
                         let $status := $work/@status/string()
                         let $statusSymbol := if($status='checked')
                                              then(<img src="/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                              else if($status='published')
                                              then(<img src="/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                              else(<img src="/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                         order by $order
                         return
                             <div class="card bg-light mb-3" name="{$status}">
                                 <div class="card-body">
                                    <div class="row justify-content-between">
                                        <div class="col">
                                            <h5 class="card-title">{baudiWork:getWorkTitle($work)}</h5>
                                            {if($titleSub !='')then(<h6>{$titleSub}</h6>)else()}
                                            <h6 class="card-subtitle-baudi text-muted">{baudiShared:translate('baudi.conjunction.for'), ' ', baudiWork:getPerfRes($work, 'short')}</h6>
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                    </div>
                                    <p class="card-text">{if($composer)
                                                         then(baudiShared:translate('baudi.registry.works.composer'),': ',$composer,<br/>)
                                                         else()}
                                                         {if($arranger)
                                                         then(baudiShared:translate('baudi.registry.works.arranger'),': ',$arranger,<br/>)
                                                         else()}
                                                        {if($lyricist)
                                                         then(baudiShared:translate('baudi.registry.works.lyricist'),': ',$lyricist,<br/>)
                                                         else()}
                                                         {if($editor)
                                                         then(baudiShared:translate('baudi.registry.works.editor'),': ',$editor,<br/>)
                                                         else()}
                                   <hr/>
                                   <a class="card-link" href="/{$editionID}">{$editionID}</a></p>
                                   
                                 </div>
                             </div>
        
        let $tab := <div class="tab-pane fade show active" id="main">
                            <br/>
                            {$cards}
                         </div>
        return
            $tab}
        </div>
        <br/>
      </div>
   </div>
       
       return
        $content
};

declare function app:viewEdition($node as node(), $model as map(*)) {
    let $editionID := request:get-parameter("edition-id", "error")
    let $lang := baudiShared:get-lang()
    let $edition := $app:collectionEditions[@xml:id=$editionID]
    let $fileURI := document-uri($edition/root())
    let $editionTitle := $edition//edirom:editionName//text()
    let $editionWorks := $edition//edirom:work
    
    return
(
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>{$editionTitle}</h1>
            <h5>{$editionID}</h5>
        </div>
        <br/>
    <ul class="nav nav-pills mb-3" id="pills-tab" role="tablist">
       <li class="nav-item">
         <a class="nav-link active" id="pills-main-tab" data-toggle="pill" href="#pills-main" role="tab" aria-controls="pills-main" aria-selected="true">Überblick</a>
       </li>
       <li class="nav-item">
         <a class="nav-link" id="pills-xml-tab" data-toggle="pill" href="#pills-xml" role="tab" aria-controls="pills-xml" aria-selected="false">XML</a>
       </li>
    </ul>
    <div class="tab-content" id="pills-tabContent">
        <div class="tab-pane fade show active" id="pills-main" role="tabpanel" aria-labelledby="pills-main-tab">
            <div class="page-header">
            <h3>{baudiShared:translate('baudi.registry.works.components')}</h3>
            <hr/>
        </div>
            {
                for $work in $editionWorks
                    let $title := $work//edirom:name[@xml:lang=$lang]
                    let $workID := $work/@xml:id/string()
                (:  let $composer := if($work//mei:composer//@codedval)
                                      then(baudiShared:getPersName($composerID, 'short', 'yes'))
                                      else($work//mei:composer/string())
                     let $arrangerID := $work//mei:arranger//@codedval
                     let $arranger := if($work//mei:arranger//@codedval)
                                      then(baudiShared:getPersName($arrangerID, 'short', 'yes'))
                                      else($work//mei:arranger/string())
                     let $lyricistID := $work//mei:lyricist//@codedval
                     let $lyricist := if($work//mei:lyricist//@codedval)
                                      then(baudiShared:getPersName($lyricistID, 'short', 'yes'))
                                      else($work//mei:lyricist/string())
                     let $editorID := $work//mei:editor//@codedval
                     let $editor := if($editorID)
                                    then(baudiShared:getPersName($editorID, 'short', 'yes'))
                                    else($work//mei:editor/string())
                :)
                    let $status := $work/@status/string()
                    let $statusSymbol := if($status='checked')
                                         then(<img src="/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                         else if($status='published')
                                         then(<img src="/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                         else(<img src="/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                        return
                             <div class="card bg-light mb-3" name="{$status}">
                                 <div class="card-body">
                                    <div class="row justify-content-between">
                                        <div class="col">
                                            <h5 class="card-title">{$title}</h5>
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                    </div>
                                    <p class="card-text">
                                      <!--
                                        {if($composer)
                                         then(baudiShared:translate(concat('baudi.registry.works.composer',baudiShared:checkGenderforLangValues($composerID))),': ',$composer,<br/>)
                                         else()}
                                         {if($arranger)
                                         then(baudiShared:translate(concat('baudi.registry.works.arranger',baudiShared:checkGenderforLangValues($arrangerID))),': ',$arranger,<br/>)
                                         else()}
                                        {if($lyricist)
                                         then(baudiShared:translate(concat('baudi.registry.works.lyricist',baudiShared:checkGenderforLangValues($lyricistID))),': ',$lyricist,<br/>)
                                         else()}
                                         {if($editor)
                                         then(baudiShared:translate(concat('baudi.registry.works.editor',baudiShared:checkGenderforLangValues($editorID))),': ',$editor,<br/>)
                                         else()}
                                        {if($componentWorksCount >= 1)
                                         then(concat(baudiShared:translate('baudi.registry.works.components'),': ',
                                                $componentWorksCount),<br/>)
                                         else()}
                                         {if($relatedItemsCount >= 1)
                                         then(concat(baudiShared:translate('baudi.registry.works.relSources'), ': ',
                                                $relatedItemsCount),<br/>)
                                         else()}
                                        -->
                                    </p>
                                   <a href="/{$workID}" class="card-link">{$workID}</a>
                                 </div>
                             </div>
            }
        </div>
        <div class="tab-pane fade" id="pills-xml" role="tabpanel" aria-labelledby="pills-xml-tab">
            <div class="card" style="background: aliceblue;">
                <div class="card-body">
                    <pre><code>{serialize(app:process-xml-for-display($edition), <output:serialization-parameters><output:method>xml</output:method><output:media-type>application/xml</output:media-type><output:indent>no</output:indent></output:serialization-parameters>)}</code></pre>
                </div>
            </div>
        </div>
    </div>
</div>
)

};

declare function local:getPeriodicals($model) {
    collection($periodicalsCollectionURI)/id($model('docID'))
};

declare %templates:wrap function app:getPeriodicalsSummary($node as node(), $model as map(*)) {
    let $periodical := local:getPeriodicals($model)//tei:body/node()
    let $xslt := doc('/db/apps/baudiApp/resources/xslt/contentLetter.xsl')
    return
        transform:transform($periodical, $xslt, ())
};

declare function app:countSources($node as node(), $model as map(*)){
let $count := count($app:collectionSourcesMusic)
return
    (<span class="badge badge-light">{$count}</span>)
};
declare function app:countWorks($node as node(), $model as map(*)){
let $count := count($app:collectionWorks)
return
    (<span class="badge badge-light">{$count}</span>)
};
declare function app:countPersons($node as node(), $model as map(*)){
let $count := count($app:collectionPersons)
return
    (<span class="badge badge-light">{$count}</span>)
};
declare function app:countInstitutions($node as node(), $model as map(*)){
let $count := count($app:collectionInstitutions)
return
    (<span class="badge badge-light">{$count}</span>)
};
declare function app:countPeriodicals($node as node(), $model as map(*)){
let $count := count($app:collectionPeriodicals)
return
    (<span class="badge badge-light">{$count}</span>)
};
declare function app:countDocuments($node as node(), $model as map(*)){
let $count := count($app:collectionDocuments)
return
    (<span class="badge badge-light">{$count}</span>)
};
declare function app:countGalleryItems($node as node(), $model as map(*)){
let $count := count($app:collectionGalleryItems)
return
    (<span class="badge badge-light">{$count}</span>)
};
declare function app:countLoci($node as node(), $model as map(*)){
let $count := count($app:collectionLoci)
return
    (<span class="badge badge-light">{$count}</span>)
};
declare function app:countEditions($node as node(), $model as map(*)){
let $count := count($app:collectionEditions//edirom:work)
return
    (<span class="badge badge-light">{$count}</span>)
};

declare function app:portalVersion($node as node(), $model as map(*)){
 let $package := doc('/db/apps/baudiApp/expath-pkg.xml')
 let $version := $package//pkg:package/@version/string()
 let $versionStr := substring-before($version, '-')
 let $versionHash := substring-after($version, '-')
    return
        <p class="text-muted">{concat('Version ',$versionStr, ' | Hash: ',$versionHash)}</p>
};

declare function app:registryFilterBar($node as node(), $model as map(*)){
   <div class="alert alert-dark" role="alert">
       <div class="row">
           <div class="custom-control custom-switch" >
               <input class="custom-control-input" type="checkbox" id="ampel_rot" oninput="ampel_rot()"/>
               <label class="custom-control-label" style="padding-right:20px;" for="ampel_rot">erfasst</label>
           </div>
           <div class="custom-control custom-switch">
               <input class="custom-control-input" type="checkbox" id="ampel_gelb" oninput="ampel_gelb()"/>
               <label class="custom-control-label" style="padding-right:20px;" for="ampel_gelb">überprüft</label>
           </div>
           <div class="custom-control custom-switch">
               <input class="custom-control-input" type="checkbox" id="ampel_gruen" oninput="ampel_gruen()"/>
               <label class="custom-control-label" style="padding-right:20px;" for="ampel_gruen">öffentlich</label>
           </div>
       </div>
   </div>
};

declare function app:errorReport($node as node(), $model as map(*)){
    if($config:isDevelopment)
    then(<pre class="error">{templates:error-description($node, $model)}</pre>)
    else()
};

(:~
 : Processing XML files for display (and download)
 : Comments and not-greenlisted facsimile information will be removed
 :
 : @author Peter Stadler 
 : @param $nodes the nodes to transform
 : @return transformed nodes
~:)
declare function app:process-xml-for-display($nodes as node()*) as node()* {
    for $node in $nodes
    return
        typeswitch($node)
        case comment() return $node
        case element() return 
            element {node-name($node)} {
                $node/@*,
                app:process-xml-for-display($node/node())
            }
        case document-node() return document { app:process-xml-for-display($node/node()) }
        
        default return $node
};