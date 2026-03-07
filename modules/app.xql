xquery version "3.1";

module namespace app = "http://baumann-digital.de/ns/templates";

import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace config = "https://exist-db.org/xquery/config" at "config.xqm";
import module namespace crud = "http://baumann-digital.de/ns/crud" at "crud.xqm";
(:import module namespace baudiVersions="http://baumann-digital.de/ns/versions" at "versions.xqm";:)
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace i18n = "http://exist-db.org/xquery/i18n" at "i18n.xql";
import module namespace shared = "http://baumann-digital.de/portal-app/ns/shared" at "shared.xqm";
import module namespace work = "http://baumann-digital.de/portal-app/ns/work" at "work.xqm";
import module namespace source = "http://baumann-digital.de/portal-app/ns/source" at "source.xqm";
import module namespace locus = "http://baumann-digital.de/portal-app/ns/locus" at "locus.xqm";
import module namespace persons="http://baumann-digital.de/portal-app/ns/persons" at "persons.xqm";
import module namespace editions="http://baumann-digital.de/portal-app/ns/editions" at "editions.xqm";
import module namespace er="http://baumann-digital.de/portal-app/ns/external-requests" at "external-requests.xqm";
import module namespace functx = "http://www.functx.com" at "functx.xqm";
import module namespace console="http://exist-db.org/xquery/console";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace edirom = "http://www.edirom.de/ns/1.3";
declare namespace pkg = "http://expath.org/ns/pkg";
declare namespace crapp = "http://www.baumann-digital.de/ns/criticalReport";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

(:~
 : Collection variables using dynamic CRUD pattern
 : Collections are loaded on-demand via crud:data-collection()
 :)
declare variable $app:collectionWorks := crud:data-collection('works')//mei:work;
declare variable $app:collectionSourcesMusic := crud:data-collection('sources/music')//mei:mei[@status];
declare variable $app:collectionPersons := crud:data-collection('persons')//tei:person;
declare variable $app:collectionInstitutions := crud:data-collection('institutions')//tei:org;
declare variable $app:collectionLoci := crud:data-collection('loci')//tei:place;
declare variable $app:collectionGalleryItems := 0 (:collection($config:data-collection-path || '/galleryItems/data')//tei:TEI:);
declare variable $app:collectionDocuments := crud:data-collection('sources/documents')//tei:TEI;
declare variable $app:collectionEditions := crud:data-collection('editions')//edirom:edition;
declare variable $app:collectionEditionsPath := crud:get-collection-path('editions');
declare variable $app:collectionTexts := crud:data-collection('texts')//tei:TEI;
declare variable $app:collStrTexts := crud:get-collection-path('texts');


declare function app:langSwitch($node as node(), $model as map(*)) {
    let $supportedLangVals := ('de', 'en')
    for $lang in $supportedLangVals
        return
            <li class="nav-item">
                <a id="{concat('lang-switch-', $lang)}" class="nav-link" style="{if (shared:get-lang() = $lang) then ('color: white!important;') else ()}" href="" onclick="setCookie('forceLang', '{$lang}', 1)">{upper-case($lang)}</a>
            </li>
};

(:~
 : Loads documents collection into the model map for registry view.
 :)
declare function app:load-registry-documents($node as node(), $model as map(*)) {
    map:merge((
        $model,
        map {
            "documents": $app:collectionDocuments
        }
    ))
};

(:~
 : Outputs the list of document cards for the registry.
 :)
declare function app:registry-documents-list($node as node(), $model as map(*)) {
    let $lang := shared:get-lang()
    let $cards := for $document in $model?documents
                    let $id := $document/@xml:id/string()
                    let $docType := if($document//tei:correspDesc) then('letter') else('document')
                    let $titel := $document//tei:fileDesc/tei:titleStmt/tei:title/data()
                    let $datumSent := $document//tei:correspAction[@type="sent"]/tei:date/@when
                    let $status := $document/@status/string()
                    let $statusSymbol := shared:get-status-symbol($status)
                                          
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
};

(:~
 : Route function that determines if document is a letter or not.
 : Delegates to viewLetter or load-document.
 :)
declare function app:viewDocument($node as node(), $model as map(*)) {
    let $id := request:get-parameter("document-id", "error")
    let $doc := $app:collectionDocuments[@xml:id=$id]
    let $isLetter := exists($doc//tei:correspAction)
    return
        if($isLetter)
        then(app:viewLetter($node, $model))
        else($node)
};

(:~
 : Loads document data into the model map.
 : This is the main data loading function for the document view.
 :)
declare function app:load-document($node as node(), $model as map(*)) {
    let $id := request:get-parameter("document-id", "error")
    let $doc := $app:collectionDocuments[@xml:id=$id]
    
    return
        if ($doc) then
            map:merge((
                $model,
                map {
                    "document-id": $id,
                    "document": $doc,
                    "document-title": $doc//tei:fileDesc/tei:titleStmt/tei:title/normalize-space(data(.)),
                    "document-content": transform:transform($doc//tei:text, doc($config:app-root || "/resources/xslt/contentDocument.xsl"), ())
                }
            ))
        else
            $model
};

(:~
 : Outputs the document's title.
 :)
declare function app:document-title($node as node(), $model as map(*)) {
    $model?document-title
};

(:~
 : Outputs the document's ID.
 :)
declare function app:document-id($node as node(), $model as map(*)) {
    $model?document-id
};

(:~
 : Outputs the document's transformed content.
 :)
declare function app:document-content($node as node(), $model as map(*)) {
    $model?document-content
};

(:~ 
 : DEPRECATED - kept for viewLetter compatibility
 :)
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
            {transform:transform($dokument,doc($config:app-root || "/resources/xslt/dokumentDatenblatt.xsl"), ())}
            </div>-->
            <div class="tab-pane fade show active" id="inhalt" >
            {transform:transform($doc//tei:text,doc($config:app-root || "/resources/xslt/contentDocument.xsl"), ())}
            </div>
       </div>
    </div>
    )
};

declare function app:viewLetter($node as node(), $model as map(*)) {

let $id := request:get-parameter("document-id", "error")
let $letter := collection(concat(config:get-option('dataCollectionPath'),"/sources/documents/letters"))//tei:TEI[@xml:id=$id]
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
        {transform:transform($letter//tei:teiHeader,doc($config:app-root || "/resources/xslt/metadataLetter.xsl"), ())}
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
                {source:getFacsimilePreview($id)}
            </div>
        <div class="col">
                <br/>
                <strong>Transkription</strong>
                <br/><br/>
                {transform:transform($letter//tei:text,doc($config:app-root || "/resources/xslt/contentLetter.xsl"), ())}
        </div>
        <!-- Modal -->
    <div class="modal fade bd-example-modal-lg" id="bigPicture" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
  <div class="modal-header">
        <h5 class="modal-title" id="exampleModalCenterTitle">Seite 1 von 1</h5>
      </div>
      <div class="modal-body">
        {source:getFacsimilePreview($id)}
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
        let $letterOrigFacs := er:get-letter-facsimile-url($letter, $page)
        let $letterOrigLink := er:get-letter-thumbnail-url($id, $page)
     
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
                {transform:transform($letter//tei:div[@type='page' and @n=$page],doc($config:app-root || "/resources/xslt/contentLetter.xsl"), ())}
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

(:~
 : Loads persons collection into the model map for registry view.
 :)
declare function app:load-registry-persons($node as node(), $model as map(*)) {
    map:merge((
        $model,
        map {
            "persons": $app:collectionPersons
        }
    ))
};

(:~
 : Outputs the list of person cards for the registry.
 :)
declare function app:registry-persons-list($node as node(), $model as map(*)) {
    let $lang := shared:get-lang()
    let $cards := for $person in $model?persons
                    let $id := $person/@xml:id/string()
                    let $name := shared:getPersName($id, 'reversed', 'no')
                    let $referencesCount := count(shared:getReferences($id)//xhtml:div[matches(@class,'RegisterEntry')])
                    let $status := $person/@status/string()
                    let $statusSymbol := shared:get-status-symbol($status)
                    
                    where $referencesCount gt 0
                    order by $name
                     
                    return
                         <div class="card bg-light mb-3" name="{$status}">
                             <div class="card-body">
                               <div class="row">
                                    <div class="col-6">
                                        <h5 class="card-title">{$name}</h5>
                                    </div>
                                    <div class="col-4">
                                        <span class="text-muted">{shared:translate('registry.persons.references') || ': ' || $referencesCount}</span>
                                    </div>
                                    <div class="col-2">
                                        <p class="text-right">{$statusSymbol}</p>
                                    </div>
                               </div>
                               <a href="/{$id}" class="card-link">{$id}</a>
                             </div>
                         </div>
    return
        $cards
};

(:~
 : Loads person data into the model map.
 : This is the main data loading function for the person view.
 :)
declare function app:load-person($node as node(), $model as map(*)) {
    let $id := request:get-parameter("person-id", "error")
    let $person := $app:collectionPersons/id($id)
    
    return
        if ($person) then
            map:merge((
                $model,
                map {
                    "person-id": $id,
                    "person": $person,
                    "person-name": shared:getPersName($id, 'reversed', 'no'),
                    "person-references": shared:getReferences($id),
                    "person-title": persons:getTitle($id),
                    "person-name-full": persons:getName($id, 'full'),
                    "person-forenames": persons:getForenames($id),
                    "person-epithet": persons:getEpithet($id),
                    "person-namelink": persons:getNameLink($id),
                    "person-surname-birth": persons:getSurnames($id, 'birth'),
                    "person-surname-married": persons:getSurnames($id, 'married'),
                    "person-surname": persons:getSurnames($id, ''),
                    "person-genname": persons:getGenName($id),
                    "person-nickname": persons:getNickName($id),
                    "person-unspec": persons:getNameUnspec($id),
                    "person-pseudonym": persons:getPseudonym($id),
                    "person-rolename": persons:getRoleName($id),
                    "person-occupation": persons:getOccupation($id),
                    "person-affiliation": persons:getAffiliations($id),
                    "person-residences": persons:getResidences($id),
                    "person-annotation": persons:getAnnotation($id),
                    "person-lifedata": persons:getLifeData($id),
                    "person-gnd": shared:getNormDataIdentifier($person, 'gnd', true()),
                    "person-viaf": shared:getNormDataIdentifier($person, 'viaf', true())
                }
            ))
        else
            $model
};

(:~
 : Outputs the person's name.
 :)
declare function app:person-name($node as node(), $model as map(*)) {
    $model?person-name
};

(:~
 : Outputs the person's ID.
 :)
declare function app:person-id($node as node(), $model as map(*)) {
    $model?person-id
};

(:~
 : Outputs person details as a list of rows.
 :)
declare function app:person-details($node as node(), $model as map(*)) {
    let $details := (
        map { "key": "title", "value": $model?person-title },
        map { "key": "name.full", "value": $model?person-name-full },
        (: Only show forenames/surname if full name is not available :)
        if (not($model?person-name-full)) then (
            map { 
                "key": if (count(tokenize($model?person-forenames, ' ')) gt 1) then 'forenames' else 'forename', 
                "value": $model?person-forenames 
            },
            map { "key": "surname", "value": $model?person-surname }
        ) else (),
        map { "key": "epithet", "value": $model?person-epithet },
        map { "key": "nameLink", "value": $model?person-namelink },
        map { "key": "surname.birth", "value": $model?person-surname-birth },
        map { "key": "surname.marriage", "value": $model?person-surname-married },
        map { "key": "genName", "value": $model?person-genname },
        map { "key": "pseudonym", "value": $model?person-pseudonym },
        map { "key": "nickName", "value": $model?person-nickname },
        map { "key": "unSpec", "value": $model?person-unspec },
        map { "key": "roleName", "value": $model?person-rolename },
        map { "key": "occupation", "value": $model?person-occupation },
        map { "key": "lifeData", "value": $model?person-lifedata },
        map { "key": "affiliation", "value": $model?person-affiliation },
        map { "key": "residences", "value": $model?person-residences },
        map { "key": "annotation", "value": $model?person-annotation },
        map { "key": "normDataGND", "value": $model?person-gnd, "condition": $model?person-gnd != '' },
        map { "key": "normDataVIAF", "value": $model?person-viaf, "condition": $model?person-viaf != '' }
    )
    
    return
        for $detail in $details
        let $value := $detail?value
        let $condition := if (exists($detail?condition)) then $detail?condition else exists($value) and $value != ''
        where $condition
        return
            <div class="row">
                <div class="col-5">{shared:translate('person.' || $detail?key)}</div>
                <div class="col">{$value}</div>
            </div>
};

(:~
 : Outputs the person's references.
 :)
declare function app:person-references($node as node(), $model as map(*)) {
    $model?person-references
};

(:~
 : Outputs the person's XML data.
 :)
declare function app:person-xml($node as node(), $model as map(*)) {
    serialize(
        app:process-xml-for-display($model?person), 
        <output:serialization-parameters>
            <output:method>xml</output:method>
            <output:media-type>application/xml</output:media-type>
            <output:indent>no</output:indent>
        </output:serialization-parameters>
    )
};

(:~
 : Fetches and displays GND/VIAF/Wikidata information for a person.
 :)
declare function app:person-gnd-info($node as node(), $model as map(*)) {
    let $person := $model?person
    let $gndId := $person//tei:idno[@type='gnd']/string()
    let $viafId := $person//tei:idno[@type='viaf']/string()
    return
        if (($gndId and $gndId != '') or ($viafId and $viafId != '')) then
            er:get-authority-info($gndId, $viafId)
        else ()
};

(:~
 : Loads loci collection into the model map for registry view.
 :)
declare function app:load-registry-loci($node as node(), $model as map(*)) {
    map:merge((
        $model,
        map {
            "loci": $app:collectionLoci
        }
    ))
};

(:~
 : Outputs the list of locus cards for the registry.
 :)
declare function app:registry-loci-list($node as node(), $model as map(*)) {
    let $lang := shared:get-lang()
    let $cards := for $locus in $model?loci
                    let $name := $locus/tei:placeName[1]
                    let $id := $locus/@xml:id/string()
                    let $status := $locus/@status/string()
                    let $statusSymbol := shared:get-status-symbol($status)
                    let $referencesCount := count(shared:getReferences($id)//xhtml:div[matches(@class,'RegisterEntry')])
                    let $tags := <label class="btn btn-outline-primary btn-sm disabled">{shared:translate(concat('registry.loci.tag.',$locus/@type))}</label>
                    
                    where $referencesCount gt 0
                    order by $name
                    return
                         <div class="card bg-light mb-3" name="{$status}">
                             <div class="card-body">
                               <div class="row">
                                    <div class="col-6">
                                        <h5 class="card-title">{$name}</h5>
                                    </div>
                                    <div class="col-4">
                                        <span class="text-muted">{shared:translate('registry.persons.references') || ': ' || $referencesCount}</span>
                                    </div>
                                    <div class="col-2">
                                        <p class="text-right">{$statusSymbol}</p>
                                    </div>
                               </div>
                               <a href="/{$id}" class="card-link">{$id}</a>
                               <hr/>
                               {$tags}
                             </div>
                         </div>
    return
        $cards
};

(:~
 : Loads locus data into the model map.
 : This is the main data loading function for the locus view.
 :)
declare function app:load-locus($node as node(), $model as map(*)) {
    let $id := request:get-parameter("locus-id", "error")
    let $locus := $app:collectionLoci/id($id)
    
    return
        if ($locus) then
            map:merge((
                $model,
                map {
                    "locus-id": $id,
                    "locus": $locus,
                    "locus-name": locus:getLocusName($id),
                    "locus-references": shared:getReferences($id)
                }
            ))
        else
            $model
};

(:~
 : Outputs the locus's name.
 :)
declare function app:locus-name($node as node(), $model as map(*)) {
    $model?locus-name
};

(:~
 : Outputs the locus's ID.
 :)
declare function app:locus-id($node as node(), $model as map(*)) {
    $model?locus-id
};

(:~
 : Outputs the OpenStreetMap for the locus.
 :)
declare function app:locus-map($node as node(), $model as map(*)) {
    locus:getOpenStreetMap($model?locus-id)
};

(:~
 : Outputs the locus's references.
 :)
declare function app:locus-references($node as node(), $model as map(*)) {
    $model?locus-references
};

(:~
 : Outputs the locus's XML data.
 :)
declare function app:locus-xml($node as node(), $model as map(*)) {
    serialize(
        app:process-xml-for-display($model?locus), 
        <output:serialization-parameters>
            <output:method>xml</output:method>
            <output:media-type>application/xml</output:media-type>
            <output:indent>no</output:indent>
        </output:serialization-parameters>
    )
};

(:~
 : Loads institutions collection into the model map for registry view.
 :)
declare function app:load-registry-institutions($node as node(), $model as map(*)) {
    map:merge((
        $model,
        map {
            "institutions": $app:collectionInstitutions
        }
    ))
};

(:~
 : Outputs the list of institution cards for the registry.
 :)
declare function app:registry-institutions-list($node as node(), $model as map(*)) {
    let $lang := shared:get-lang()
    let $cards := for $org in $model?institutions
                    let $name := shared:getOrgNameFull($org)
                    let $id := $org/@xml:id/string()
                    let $referencesCount := count(shared:getReferences($id)//xhtml:div[matches(@class,'RegisterEntry')])
                    let $status := $org/@status/string()
                    let $statusSymbol := shared:get-status-symbol($status)
                                          
                    order by $name
                    where $referencesCount gt 0
                    return
                        <div class="card bg-light mb-3" name="{$status}">
                            <div class="card-body">
                               <div class="row">
                                    <div class="col-6">
                                        <h5 class="card-title">{$name}</h5>
                                    </div>
                                    <div class="col-4">
                                        <span class="text-muted">{shared:translate('registry.persons.references') || ': ' || $referencesCount}</span>
                                    </div>
                                    <div class="col-2">
                                        <p class="text-right">{$statusSymbol}</p>
                                    </div>
                               </div>
                               <a href="/{$id}" class="card-link">{$id}</a>
                             </div>
                         </div>
    return
        $cards
};

(:~
 : Loads institution data into the model map.
 : This is the main data loading function for the institution view.
 :)
declare function app:load-institution($node as node(), $model as map(*)) {
    let $id := request:get-parameter("institution-id", "error")
    let $org := $app:collectionInstitutions[@xml:id=$id]
    
    return
        if ($org) then
            let $orgName := shared:getOrgNameFull($org)
            let $place := if($org/tei:location/tei:settlement/@key)
                          then(<a href="/{$org/tei:location/tei:settlement/@key/string()}">{$org/tei:location/tei:settlement/text()}</a>)
                          else($org/tei:location/tei:settlement/text())
            return
                map:merge((
                    $model,
                    map {
                        "institution-id": $id,
                        "institution": $org,
                        "institution-name": $orgName,
                        "institution-place": $place,
                        "institution-affiliates": persons:getAffiliates($id),
                        "institution-references": shared:getReferences($id),
                        "institution-gnd": shared:getNormDataIdentifier($org, 'gnd', true()),
                        "institution-viaf": shared:getNormDataIdentifier($org, 'viaf', true())
                    }
                ))
        else
            $model
};

(:~
 : Outputs the institution's name.
 :)
declare function app:institution-name($node as node(), $model as map(*)) {
    $model?institution-name
};

(:~
 : Outputs the institution's ID.
 :)
declare function app:institution-id($node as node(), $model as map(*)) {
    $model?institution-id
};

(:~
 : Outputs institution details as a list of rows.
 :)
declare function app:institution-details($node as node(), $model as map(*)) {
    let $details := (
        map { "key": "name", "value": $model?institution-name },
        map { "key": "affiliates", "value": $model?institution-affiliates },
        map { "key": "place", "value": $model?institution-place },
        map { "key": "normDataGND", "value": $model?institution-gnd, "condition": $model?institution-gnd != '' },
        map { "key": "normDataVIAF", "value": $model?institution-viaf, "condition": $model?institution-viaf != '' }
    )
    
    return
        for $detail in $details
        let $value := $detail?value
        let $condition := if (exists($detail?condition)) then $detail?condition else exists($value) and $value != ''
        where $condition
        return
            <div class="row">
                <div class="col-5">{shared:translate('institution.' || $detail?key)}</div>
                <div class="col">{$value}</div>
            </div>
};

(:~
 : Outputs the institution's references.
 :)
declare function app:institution-references($node as node(), $model as map(*)) {
    $model?institution-references
};

(:~
 : Outputs the institution's XML data.
 :)
declare function app:institution-xml($node as node(), $model as map(*)) {
    serialize(
        app:process-xml-for-display($model?institution), 
        <output:serialization-parameters>
            <output:method>xml</output:method>
            <output:media-type>application/xml</output:media-type>
            <output:indent>no</output:indent>
        </output:serialization-parameters>
    )
};

(:~
 : Fetches and displays GND/VIAF/Wikidata information for an institution.
 :)
declare function app:institution-gnd-info($node as node(), $model as map(*)) {
    let $institution := $model?institution
    let $gndId := $institution//tei:idno[@type='gnd']/string()
    let $viafId := $institution//tei:idno[@type='viaf']/string()
    return
        if (($gndId and $gndId != '') or ($viafId and $viafId != '')) then
            er:get-authority-info($gndId, $viafId)
        else ()
};

(:~
 : Loads sources collection into the model map for registry view.
 :)
declare function app:load-registry-sources($node as node(), $model as map(*)) {
    map:merge((
        $model,
        map {
            "sources": $app:collectionSourcesMusic//mei:manifestationList/mei:manifestation,
            "genres": distinct-values($app:collectionSourcesMusic//mei:term[@type="source"])
        }
    ))
};

(:~
 : Outputs the complete sources registry content with tabs.
 :)
declare function app:registry-sources-content($node as node(), $model as map(*)) {
    let $lang := shared:get-lang()
    let $sources := $model?sources
    let $genres := $model?genres
    
    return
    <div class="container">
         <ul class="nav nav-pills" role="tablist">
         <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">{shared:translate('registry.sources.all')} ({count($sources)})</a></li>
            {for $genre in $genres[not(. = 'part') and not(. = 'collection') and not(. = 'reprint')]
                let $genreCount := count($sources[.//mei:term[@type='source'][. = $genre]])
                let $nav-itemGenre := <li class="nav-item"><a class="nav-link" data-toggle="tab" href="{concat('#',$genre)}">{shared:translate(concat('registry.sources.',$genre))} ({$genreCount})</a></li>
                order by shared:translate(concat('registry.sources.',$genre))
                return
                    $nav-itemGenre
             }
    </ul>
    <hr/>
    <!-- Tab panels -->
    <div class="container  overflow-auto" style="max-height: 500px;">
    <div class="tab-content">
    {for $genre at $pos in ($genres,'main')
        let $cards := for $source in $sources[if($genre='main')then(.)else(.//mei:term[@type='source' and . = $genre])]
                         
                         let $id := $source/ancestor::mei:mei/@xml:id/normalize-space(data(.))
                         let $isSourceCollection := exists($source//mei:term[@type='source' and .='collection'])
                         let $title := source:getManifestationTitle($source,'uniform')
                         let $titleSort := $title[1]
                         let $titleSub := source:getManifestationTitle($source,'sub')
                         let $titleSub2 := $source//mei:titlePart[@type='ediromSourceWindow']/normalize-space(text()[1])
                         let $numberOpus := $source/ancestor::mei:mei//mei:title[@type='uniform' and @xml:lang=$lang]/mei:titlePart[@type='number' and @codedval='opus']
                         let $numberOpusCount := $source/ancestor::mei:mei//mei:title[@type='uniform' and @xml:lang=$lang]/mei:titlePart[@type='counter']/text()
                         let $numberOpusCounter := if($numberOpusCount)
                                                   then(concat(' ',shared:translate('registry.sources.opus.no'),' ',$numberOpusCount))
                                                   else()
                         let $perfMedium := source:getManifestationPerfResWithAmbitus($source, 'full')
                         let $composer := $source//mei:composer
                         let $lyricist := $source//mei:lyricist
                         let $componentSources := for $componentSource in $source//mei:componentList/mei:manifestation
                                                    let $componentId := $componentSource/mei:identifier/string()
                                                    return
                                                        $componentId
                         let $sourceRelationID := $source//mei:relation[not(@type='edirom')]/@corresp
                         let $termWorkGroup := for $tag in $source//mei:term[@type='workGroup']/string()
                                                let $label := <label class="btn btn-outline-primary btn-sm disabled">{shared:translate(concat('registry.tag.',$tag))}</label>
                                                return $label
                         let $termGenre := for $tag in $source//mei:term[@type='genre']/string()
                                               let $label := <label class="btn btn-outline-secondary btn-sm disabled">{shared:translate(concat('registry.tag.',$tag))}</label>
                                               return $label
                         let $termSource := for $tag in $source//mei:term[@type='source']/string()
                                                let $label := <label class="btn btn-outline-danger btn-sm disabled">{shared:translate(concat('registry.tag.',$tag))}</label>
                                                return $label
                         let $tags := for $each in ($termSource|$termGenre|$termWorkGroup)
                                        order by $each
                                        return ($each,'&#160;')
                         let $order := lower-case(normalize-space(if($titleSort)then($titleSort)else($title)))
                         let $status := $source/ancestor::mei:mei/@status/string()
                         let $statusSymbol := shared:get-status-symbol($status)
                         order by $order
                         return
                             if ($isSourceCollection)
                             then(
                             <div class="card bg-light mb-3" name="{$status}">
                                 <div class="card-body">
                                   <div class="row justify-content-between">
                                        <div class="col">
                                            <h5 class="card-title">{source:getManifestationTitle($source,'uniform')}</h5>
                                            {if(source:getManifestationTitle($source,'sub'))then(<h6 class="card-subtitle mb-2">{$titleSub}</h6>)else()}
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                   </div>
                                    {if(count($componentSources)>=1)
                                     then(<p class="card-text"><i>{shared:translate('registry.sources.components'), concat(' (', count($componentSources), ')')}</i></p>)
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
                                        {if(not(contains($sourceRelationID, '-02-')))
                                        then(<h6 class="text-muted">{shared:translate('noWorkRelation')}</h6>)
                                        else()}
                                            <h5 class="card-title">{source:getManifestationTitle($source, 'main')}</h5>
                                            {if($titleSub != '')then(<h6 class="card-subtitle mb-2">{source:getManifestationTitle($source, 'sub')}</h6>)else()}
                                            {if($titleSub2 != '')then(<h6 class="card-subtitle mb-2">{$titleSub2}</h6>)else()}
                                            {if(source:getManifestationTitle($source, 'perf'))then(<h6 class="card-subtitle-baudi text-muted">{source:getManifestationTitle($source, 'perf')}</h6>)else()}
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                   </div>
                                   <p class="card-text">
                                    {if($composer)
                                     then(shared:translate('registry.sources.composer'),': ',$composer,<br/>)
                                     else()}
                                    {if($lyricist)
                                     then(shared:translate('registry.sources.lyricist'),': ',$lyricist)
                                     else()}
                                    {if(count($componentSources)>=1)
                                     then(<i>{shared:translate('registry.sources.components'), concat(' (', count($componentSources), ')')}</i>)
                                     else()}
                                   </p>
                                   {if(count($source/ancestor::mei:mei//mei:manifestation) gt 1)
                                    then($id)
                                    else(<a href="/{$id}" class="card-link">{$id}</a>)}
                                   
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
};

declare function app:viewSource($node as node(), $model as map(*)) {

let $id := request:get-parameter("source-id", "error")
let $lang := shared:get-lang()
let $source := $app:collectionSourcesMusic[@xml:id=$id]
let $manifestations := $source//mei:manifestation[not(parent::mei:componentList)]
for $manifestation in $manifestations
return
    <div class="container">{
        let $fileURI := document-uri($source/root())
        let $sourceType := $source//mei:term[@type='source'][1]/string()
        let $sourceWorkGroup := $source//mei:term[@type='workGroup'][1]/string()
        let $sourceOrig := er:get-source-url($source/@xml:id)
        let $sourceTitleUniform := source:getManifestationTitle($manifestation,'uniform')
        let $sourceTitleMain := source:getManifestationTitle($manifestation,'main')
        let $sourceTitleSub := source:getManifestationTitle($manifestation,'sub')
        let $sourceTitlePerf := source:getManifestationTitle($manifestation,'perf')
        
        let $sourceComposer := source:getManifestationPersona($id,'composer')
        let $sourceArranger := source:getManifestationPersona($id,'arranger')
        let $sourceEditor := source:getManifestationPersona($id,'editor')
        let $sourceLyricist := source:getManifestationPersona($id,'lyricist')
        
        let $relatedWorks := $source//mei:relation[@rel="isEmbodimentOf"]
        let $relatedWorkID := $source//mei:relation[@rel="isEmbodimentOf"]/string(@corresp)
        let $relatedWorkTitle := work:getWorkTitle($app:collectionWorks/id($relatedWorkID))
        
        let $sourceEditionStmt := source:getSourceEditionStmt($id, $lang)
        
        let $sourceTitlePage := if($source//mei:titlePage/mei:p/text())
                                then(source:renderTitlePage($source))
                                else()
        
        let $sourcePerfRes := source:getManifestationPerfResWithAmbitus($source, 'full')
        
        let $msIdentifiers := source:getManifestationIdentifiers($id)
        
        let $msCondition := $source//mei:condition/mei:p/text()
        
        let $msPaperSpecs := source:getManifestationPaperSpecs($id)
        
        let $msHands := source:getManifestationHands($id)
        let $msPaperNotes := source:getManifestationPaperNotes($id)
        let $msStamps := if($source//mei:annot[@type="stamp"])
                         then(source:getManifestationStamps($source//mei:annot[@type="stamp"]))
                         else()
        let $msNotes := if($source//mei:annot[not(@type)]/text())
                        then(source:getManifestationNotes($id))
                        else()
        
        let $msScoreFormat := $source//mei:scoreFormat/text()
        let $sourcePlateNum := if($source//mei:plateNum/text())
                               then(<tr>
                                        <td>{shared:translate('registry.sources.msDesc.plateNum')}</td>
                                        <td>{$source//mei:plateNum/text()}</td>
                                    </tr>)
                                else()
        
        let $usedLang := for $lang in $source//mei:langUsage/mei:language/@codedval
                            return
                                shared:translate(concat('lang.',$lang))
        let $key := for $each in $source//mei:key
                      let $keyPname := $each/@pname
                      let $keyMode := $each/@mode
                      let $keyAccid := $each/@accid
                      let $keyPnameFull := concat($keyPname,$keyAccid)
                      return
                          if($keyMode = 'major')
                          then(concat(
                                        functx:capitalize-first(shared:translate(concat('registry.works.pname.',$keyPnameFull))),
                                        shared:translate('registry.delimiter.key'),
                                        shared:translate(concat('registry.works.',$keyMode))
                                     )
                                )
                          else if($keyMode = 'minor')
                          then(concat(
                                        shared:translate(concat('registry.works.pname.',$keyPnameFull)),
                                        shared:translate('registry.delimiter.key'),
                                        shared:translate(concat('registry.works.',$keyMode))
                                     )
                              )
                          else()
        let $meter := for $each in $source//mei:meter
                        let $meterCount := $each/@count
                        let $meterUnit := $each/@unit
                        let $meterSym := $each/@sym
                        let $meterSymbol := if($meterSym = 'common')
                                           then(er:get-smufl-char('timeSigCommon'))
                                           else if($meterSym = 'cut')
                                           then(er:get-smufl-char('timeSigCutCommon'))
                                           else()
                        return
                            if($meterSymbol)
                            then($meterSymbol)
                            else(concat($meterCount, '/', $meterUnit))
        let $tempo := $source//mei:work/mei:tempo/text()
        
        let $sourceHasLyrics := exists($source//mei:div[@type="songtext"])
        
        return
        (
            <div class="container">
                <br/>
                <div class="page-header">
                    <h1>{$sourceTitleUniform}</h1>
                    {if(count($source//mei:manifestation) gt 1) then(<h3>{count($source//mei:manifestation) - 1 || ' ' || shared:translate('hasSeveralManifestations')}</h3>) else()}
                    <h5>ID: {$id}</h5>
                </div>
                <br/>
                <div class="row">
               {if(exists($source//mei:facsimile/mei:surface))
               then(source:getFacsimilePreview($id))
                else()}
            <div class="{if(exists($source//mei:facsimile/mei:surface)) then 'col-md-8 col-lg-8' else 'col-12'}">
              <ul class="nav nav-pills" role="tablist">
                  <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">{shared:translate('registry.sources.tab.main')}</a></li>  
                  <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#detail">{shared:translate('registry.sources.tab.detail')}</a></li>
                  {if($sourceHasLyrics)then(<li class="nav-item"><a class="nav-link" data-toggle="tab" href="#lyrics">{shared:translate('registry.sources.tab.lyrics')}</a></li>)else()}
                  <!--<li class="nav-item"><a class="nav-link" data-toggle="tab" href="#verovio">Verovio</a></li>-->
                  <li class="nav-item">
                 <a class="nav-link" id="pills-edition-tab" data-toggle="pill" href="#pills-xml" role="tab" aria-controls="pills-xml" aria-selected="false">XML</a>
               </li>
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
                               <td>{shared:translate('registry.sources.sourceType')}</td>
                               <td>{shared:translate(concat('registry.sources.',$sourceType))}</td>
                            </tr>
                             {if($sourceTitleMain != '')
                             then(<tr>
                                    <td>{shared:translate('registry.sources.titleMain')}</td>
                                    <td>{$sourceTitleMain}</td>
                                  </tr>)
                             else()}
                             {if($sourceTitleSub != '')
                             then(<tr>
                                    <td>{shared:translate('registry.sources.titleSub')}</td>
                                    <td>{$sourceTitleSub}</td>
                                  </tr>)
                             else()}
                             </table>
                             <table class="sourceView">
                                {if(exists($relatedWorkID))
                                then(<tr>
                                       <td>{shared:translate('registry.sources.relation')}</td>
                                       <td>{if(exists($relatedWorkID))then(<a href="{$relatedWorkID}">{$relatedWorkTitle}</a>)else(shared:translate('unknown'))}</td>
                                     </tr>)
                                else()}
                             {if($sourceComposer)
                             then(<tr>
                                    <td>{shared:translate('registry.sources.composer')}</td>
                                    <td>{$sourceComposer}</td>
                                  </tr>)
                             else()}
                             {if($sourceArranger)
                             then(<tr>
                                    <td>{shared:translate('registry.sources.arranger')}</td>
                                    <td>{$sourceArranger}</td>
                                  </tr>)
                             else()}
                             {if($sourceLyricist or $sourceWorkGroup = 'vocal')
                             then(<tr>
                                    <td>{shared:translate('registry.sources.lyricist')}</td>
                                    <td>{if($sourceLyricist) then($sourceLyricist)
                                        else if ($source//mei:manifestation//mei:lyricist/text() != '') then($source//mei:manifestation//mei:lyricist/text()) else(shared:translate('unknown'))}</td>
                                  </tr>)
                             else()}
                             {if($sourceEditor)
                             then(<tr>
                                    <td>{shared:translate('registry.sources.editor')}</td>
                                    <td>{$sourceEditor}</td>
                                  </tr>)
                             else()}
                         </table>
                         <table class="sourceView">
                             {if(not($usedLang/data(.) = ''))
                             then(<tr>
                                    <td>{if(count($usedLang) = 1)
                                         then(shared:translate('registry.works.langUsed'))
                                         else if(count($usedLang) > 1)
                                         then(shared:translate('registry.works.langsUsed'))
                                         else()}</td>
                                    <td>{string-join($usedLang,', ')}</td>
                                  </tr>)
                             else()}
                             
                             {if(count($key) > 0)
                             then(<tr>
                                    <td>{shared:translate('registry.works.key')}</td>
                                    <td>{normalize-space(string-join($key, ' | '))}</td>
                                  </tr>)
                             else()}
                             {if(count($meter) > 0)
                             then(<tr>
                                    <td>{shared:translate('registry.works.meter')}</td>
                                    <td>{$meter}</td>
                                  </tr>)
                             else()}
                             {if($tempo)
                             then(<tr>
                                    <td>{shared:translate('registry.works.tempo')}</td>
                                    <td><i>{normalize-space($tempo)}</i></td>
                                  </tr>)
                             else()}
                             {if($sourcePerfRes)
                             then(<tr>
                                    <td>{shared:translate('registry.sources.perfRes')}</td>
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
                         {if ($msNotes != '')
                         then ($msNotes)
                         else ()}
                         {if ($msCondition)
                         then (<table class="sourceView">
                                   <tr>
                                     <th/>
                                     <th/>
                                   </tr>
                                   <tr>
                                     <td>{shared:translate('registry.sources.msDesc.condition')}</td>
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
                                 {source:getLyrics($id)}
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
                  <div class="tab-pane fade" id="pills-xml" role="tabpanel" aria-labelledby="pills-xml-tab">
                    <div class="card xml-view-card">
                        <div class="card-body">
                            <pre><code>{serialize(app:process-xml-for-display($source), <output:serialization-parameters><output:method>xml</output:method><output:media-type>application/xml</output:media-type><output:indent>no</output:indent></output:serialization-parameters>)}</code></pre>
                        </div>
                    </div>
                </div>
              </div>
            </div>
            </div>
        </div>
    )
    }</div>
};


declare function app:aboutProject($node as node(), $model as map(*)) {

let $doc := doc(concat($app:collStrTexts,'/portal/aboutProject.xml'))/tei:TEI


return
(
    <div class="container">
    <br/>
        {transform:transform(shared:getI18nText($doc), doc($config:app-root || "/resources/xslt/formattingText.xsl"), ())}
    </div>
)
};

declare function app:aboutBaumann($node as node(), $model as map(*)) {

let $doc := doc(concat($app:collStrTexts, "/portal/aboutBaumann.xml"))/tei:TEI

return
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>Ludwig Baumann <span class="text-muted" style="font-size: x-large;">(1866–1944)</span></h1>
        <hr/>
        </div>
            {transform:transform(shared:getI18nText($doc), doc($config:app-root || "/resources/xslt/formattingText.xsl"), ())}
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
            {transform:transform($text,doc($config:app-root || "/resources/xslt/formattingText.xsl"), ())}
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
            {transform:transform($text,doc($config:app-root || "/resources/xslt/formattingText.xsl"), ())}
        </div>
    </div>
)
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
        {transform:transform($codingGuidelines,doc($config:app-root || "/resources/xslt/contentCodingGuidelines.xsl"), ())}
        </div>
        <div class="tab-pane fade" id="edition" >
        {transform:transform($editiorialGuidelines,doc($config:app-root || "/resources/xslt/contentEditorialGuidelines.xsl"), ())}
        </div>
        <div class="tab-pane fade" id="sourceDesc" >
        {transform:transform($sourceDescGuidelines,doc($config:app-root || "/resources/xslt/contentSourceDescGuidelines.xsl"), ())}
        </div>
   </div>
    </div>
)
};

(:~
 : Loads works collection into the model map for registry view.
 :)
declare function app:load-registry-works($node as node(), $model as map(*)) {
    (: Loads XML data and returns map for template engine.
       The map serves only as transport - all processing works with XML nodes. :)
    map:merge((
        $model,
        map {
            "works": $app:collectionWorks[not(parent::mei:componentList)],
            "genres": distinct-values($app:collectionWorks//mei:term[@type="genre"]/text() | $app:collectionWorks//mei:titlePart[@type='main' and not(@class)]/@type)
        }
    ))
};

(:~
 : Outputs the complete works registry content with tabs.
 : Works with XML nodes from the model map.
 :)
declare function app:registry-works-content($node as node(), $model as map(*)) {
    (: Extract XML data from model :)
    let $works := $model?works
    let $genres := $model?genres
    
    return
    <div class="container">
         <ul class="nav nav-pills" role="tablist">
            <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">{shared:translate('registry.works.all')} ({count($works)})</a></li>
            {for $genre at $pos in $genres[. != 'main']
                let $workCount := count($works//mei:term[@type='genre' and . = $genre])
                let $nav-itemGenre := <li class="nav-item"><a class="nav-link" data-toggle="tab" href="{concat('#',$genre)}">{shared:translate(concat('registry.works.',$genre))} ({$workCount})</a></li>
                order by shared:translate(concat('registry.works.',$genre))
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
                                                   then(concat(' ',shared:translate('registry.works.opus.no'),' ',$numberOpusCount))
                                                   else()
                         let $workID := $work/@xml:id/string()
                         let $composerID := $work//mei:composer//@codedval
                         let $composer := if($work//mei:composer//@codedval)
                                          then(shared:getPersName($composerID, 'short', 'yes'))
                                          else($work//mei:composer/string())
                         let $arrangerID := $work//mei:arranger//@codedval
                         let $arranger := if($work//mei:arranger//@codedval)
                                          then(shared:getPersName($arrangerID, 'short', 'yes'))
                                          else($work//mei:arranger/string())
                         let $lyricistID := $work//mei:lyricist//@codedval
                         let $lyricist := if($work//mei:lyricist//@codedval)
                                          then(shared:getPersName($lyricistID, 'short', 'yes'))
                                          else($work//mei:lyricist/string())
                         let $editorID := $work//mei:editor//@codedval
                         let $editor := if($editorID)
                                        then(shared:getPersName($editorID, 'short', 'yes'))
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
                                                let $label := <label class="btn btn-outline-primary btn-sm disabled">{shared:translate(concat('registry.works.',$tag))}</label>
                                                return $label
                         let $termGenre := for $tag in $work//mei:term[@type='genre']/text()
                                               let $label := <label class="btn btn-outline-secondary btn-sm disabled">{shared:translate(concat('registry.works.',$tag))}</label>
                                               return $label
                         let $tags := for $each in ($termGenre|$termWorkGroup)
                                        return ($each,'&#160;')
                         let $order := lower-case(normalize-space(if($titleSort)then($titleSort)else($title)))
                         let $status := $work/@status/string()
                         let $statusSymbol := shared:get-status-symbol($status)
                         order by $order
                         return
                             <div class="card bg-light mb-3" name="{$status}">
                                 <div class="card-body">
                                    <div class="row justify-content-between">
                                        <div class="col">
                                            <h5 class="card-title">{work:getWorkTitle($work)}</h5>
                                            {if($titleSub !='')then(<h6>{$titleSub}</h6>)else()}
                                            <h6 class="card-subtitle-baudi text-muted">{shared:translate('conjunction.for'), ' ', work:getPerfRes($work, 'short')}</h6>
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                    </div>
                                    <p class="card-text">{if($composer)
                                                         then(shared:translate(concat('registry.works.composer',shared:checkGenderforLangValues($composerID))),': ',$composer,<br/>)
                                                         else()}
                                                         {if($arranger)
                                                         then(shared:translate(concat('registry.works.arranger',shared:checkGenderforLangValues($arrangerID))),': ',$arranger,<br/>)
                                                         else()}
                                                        {if($lyricist)
                                                         then(shared:translate(concat('registry.works.lyricist',shared:checkGenderforLangValues($lyricistID))),': ',$lyricist,<br/>)
                                                         else()}
                                                         {if($editor)
                                                         then(shared:translate(concat('registry.works.editor',shared:checkGenderforLangValues($editorID))),': ',$editor,<br/>)
                                                         else()}
                                                        {if($componentWorksCount >= 1)
                                                         then(concat(shared:translate('registry.works.components'),': ',
                                                                $componentWorksCount),<br/>)
                                                         else()}
                                                         {if($relatedItemsCount >= 1)
                                                         then(concat(shared:translate('registry.works.relSources'), ': ',
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
};
       
declare function app:viewWork($node as node(), $model as map(*)) {

let $workID := request:get-parameter("work-id", "error")
let $lang := shared:get-lang()
let $work := $app:collectionWorks[@xml:id=$workID]
let $fileURI := document-uri($work/root())
let $title := $work/mei:title[@type='uniform']/mei:titlePart[@type='main' and not(@class)]
let $subtitle := $work/mei:title[@type='uniform']/mei:titlePart[@type = 'subordinate']/normalize-space(.)
let $numberOpus := $work/mei:title[@type='uniform']/mei:titlePart[@type='number' and @codedval='opus']
let $titlePerfMedium := $work/mei:title[@type='uniform']/mei:titlePart[@type = 'perfmedium']
let $titleMainAlt := $work/mei:titlePart[@type = 'mainAlt']
let $titleSubAlt := $work/mei:title[@type='uniform']/mei:titlePart[@type = 'subAlt']
let $composer := $work/mei:composer
let $composerID := $composer/mei:persName/@codedval
let $composerEntry := $app:collectionPersons/id($composerID)
let $composerName := shared:getPersName($composerID, 'short', 'yes')
let $composerGender := if($composerEntry[@sex="female"]) then('composer.female') else('composer')
let $arranger := $work/mei:arranger
let $arrangerID := $arranger/mei:persName/@codedval
let $arrangerEntry := $app:collectionPersons/id($arrangerID)
let $arrangerName := if($arrangerID)then(shared:getPersName($arrangerID, 'short', 'yes'))else($arranger//text()/normalize-space())
let $arrangerGender := if($arrangerEntry[@sex="female"]) then('arranger.female') else('arranger')
let $lyricist := $work/mei:lyricist
let $lyricistID := $lyricist/mei:persName/@codedval
let $lyricistEntry := $app:collectionPersons/id($lyricistID)
let $lyricistName := if($lyricistID)then(shared:getPersName($lyricistID, 'short', 'yes'))else($lyricist//text()/normalize-space())
let $lyricistGender := if($lyricistEntry[@sex="female"])
                       then('lyricist.female')
                       else('lyricist')

let $usedLang := for $lang in $work/mei:langUsage/mei:language/@codedval
                    return
                        shared:translate(concat('lang.',$lang))
let $key := for $each in $work/mei:key
              let $keyPname := $each/@pname
              let $keyMode := $each/@mode
              let $keyAccid := $each/@accid
              let $keyPnameFull := concat($keyPname,$keyAccid)
              return
                  if($keyMode = 'major')
                  then(concat(
                                functx:capitalize-first(shared:translate(concat('registry.works.pname.',$keyPnameFull))),
                                shared:translate('registry.delimiter.key'),
                                shared:translate(concat('registry.works.',$keyMode))
                             )
                        )
                  else if($keyMode = 'minor')
                  then(concat(
                                shared:translate(concat('registry.works.pname.',$keyPnameFull)),
                                shared:translate('registry.delimiter.key'),
                                shared:translate(concat('registry.works.',$keyMode))
                             )
                      )
                  else()
let $meter := for $each in $work/mei:meter
                let $meterCount := $each/@count
                let $meterUnit := $each/@unit
                let $meterSym := $each/@sym
                let $meterSymbol := if($meterSym = 'common')
                                           then(er:get-smufl-char('timeSigCommon'))
                                           else if($meterSym = 'cut')
                                           then(er:get-smufl-char('timeSigCutCommon'))
                                           else()
                return
                    if($meterSymbol)
                    then($meterSymbol)
                    else if($meterCount and $meterUnit)
                    then(concat($meterCount, '/', $meterUnit))
                    else()
let $tempo := $work/mei:tempo/text()

let $incipText := $work/mei:incip/mei:incipText//text() => string-join(' ')

let $workgroup := $work/mei:classification/mei:termList/mei:term[@type='workGroup']/text()
let $genre := $work/mei:classification/mei:termList/mei:term[@type='genre']/text()

let $perfMedium := work:getPerfRes($work, 'detailShort')

let $relatedSourcesCards := for $source in $app:collectionSourcesMusic
                let $sourceId := $source/@xml:id/string()
                let $sourceType := $source//mei:term[@type='source'][1]/string()
                let $sourceTypeTranslated := shared:translate(concat('registry.sources.',$sourceType))
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
                    <h5 class="card-title">{work:getWorkTitle($work)}</h5>
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
       {if(editions:hasEditions($workID))
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
                    <td>{shared:translate('registry.works.perfmedium')}</td>
                    <td>{normalize-space($titlePerfMedium)}</td>
                  </tr>)
             else()}
             {if($titleMainAlt)
             then(<tr>
                    <td>{shared:translate('registry.works.titleAlt')}</td>
                    <td>{normalize-space($titleMainAlt)}</td>
                  </tr>)
             else()}
             {if($titleSubAlt)
             then(<tr>
                    <td>{shared:translate('registry.works.subtitleAlt')}</td>
                    <td>{normalize-space($titleSubAlt)}</td>
                  </tr>)
             else()}
             {if($composerName != '')
             then(<tr>
                    <td>{shared:translate($composerGender)}</td>
                    <td>{$composerName}</td>
                  </tr>)
             else()}
             {if($arrangerName != '')
             then(<tr>
                    <td>{shared:translate($arrangerGender)}</td>
                    <td>{$arrangerName}</td>
                  </tr>)
             else()}
             {if($lyricistName != '')
             then(<tr>
                    <td>{shared:translate($lyricistGender)}</td>
                    <td>{$lyricistName}</td>
                  </tr>)
             else()}
             {if($usedLang/data(.) != '')
             then(<tr>
                    <td>{if(count($usedLang) = 1)
                         then(shared:translate('registry.works.langUsed'))
                         else if(count($usedLang) > 1)
                         then(shared:translate('registry.works.langsUsed'))
                         else()}</td>
                    <td>{string-join($usedLang,', ')}</td>
                  </tr>)
             else()}
             <!-- {if($incipText != '')
             then(<tr>
                    <td>{shared:translate('registry.works.incipit.text')}</td>
                    <td><em>{$incipText}</em></td>
                  </tr>)
             else()} -->
             {if(exists($key))
             then(<tr>
                    <td>{shared:translate('registry.works.key')}</td>
                    <td>{normalize-space(string-join($key, ' | '))}</td>
                  </tr>)
             else()}
             {if($meter)
             then(<tr>
                    <td>{shared:translate('registry.works.meter')}</td>
                    <td>{$meter}</td>
                  </tr>)
             else()}
             {if($tempo)
             then(<tr>
                    <td>{shared:translate('registry.works.tempo')}</td>
                    <td><i>{normalize-space($tempo)}</i></td>
                  </tr>)
             else()}
             {if($workgroup)
             then(<tr>
                    <td>Werkklasse</td>
                    <td>{string-join(for $each in $workgroup return shared:translate(concat('registry.works.',$each)),' | ')}</td>
                  </tr>)
             else()}
             {if($genre)
             then(<tr>
                    <td>Werkgruppe</td>
                    <td>{shared:translate(concat('registry.works.',$genre))}</td>
                  </tr>)
             else()}
             {if($perfMedium != '')
             then(<tr>
                    <td style="vertical-align: top;">{shared:translate('registry.works.perfRes')}</td>
                    <td>{work:getPerfRes($work,'detailShort')}</td>
                  </tr>)
             else()}
             </table>
         <!--{if(work:hasIncipitMusic($workID))
         then(<br/>,
              <h4>{shared:translate('registry.works.incipit')}</h4>,
              <br/>,
              work:getIncipitMusic($workID))
         else()}-->
        {if($relatedSourcesCards)
        then(
        <div>
           <br/>
           <h4>{shared:translate('registry.works.relSources')}</h4>
           <br/>
           <div class="container overflow-auto" style="max-height: 500px;">
            {$relatedSourcesCards}
            </div>
           <br/>
        </div>)
        else()}
        </div>
        {if(work:hasStemma($workID))
        then(<div class="tab-pane fade" id="pills-stemma" role="tabpanel" aria-labelledby="pills-stemma-tab">
            {work:getStemma($workID, '', '')}
        </div>)
        else()}
        {if(editions:hasEditions($workID))
        then(<div class="tab-pane fade" id="pills-edition" role="tabpanel" aria-labelledby="pills-edition-tab">
            {$editionsContent}
        </div>)
        else()}
        <div class="tab-pane fade" id="pills-xml" role="tabpanel" aria-labelledby="pills-xml-tab">
            <div class="card xml-view-card">
                <div class="card-body">
                    <pre><code>{serialize(app:process-xml-for-display($work), <output:serialization-parameters><output:method>xml</output:method><output:media-type>application/xml</output:media-type><output:indent>no</output:indent></output:serialization-parameters>)}</code></pre>
                </div>
            </div>
        </div>
    </div>
</div>
)
};

(:~
 : Loads editions collection into the model map for registry view.
 :)
declare function app:load-registry-editions($node as node(), $model as map(*)) {
    map:merge((
        $model,
        map {
            "editions": $app:collectionEditions//edirom:work
        }
    ))
};

(:~
 : Outputs the complete editions registry content.
 :)
declare function app:registry-editions-content($node as node(), $model as map(*)) {
    let $editions := $model?editions
    
    return
    <div class="container">
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
                                                   then(concat(' ',shared:translate('registry.works.opus.no'),' ',$numberOpusCount))
                                                   else()
                         let $composer := if($work//mei:composer//@codedval)
                                          then(shared:getPersName($work//mei:composer//@codedval, 'short', 'yes'))
                                          else($work//mei:composer/string())
                         let $arranger := if($work//mei:arranger//@codedval)
                                          then(shared:getPersName($work//mei:arranger//@codedval, 'short', 'yes'))
                                          else($work//mei:arranger/string())
                         let $lyricist := if($work//mei:lyricist//@codedval)
                                          then(shared:getPersName($work//mei:lyricist//@codedval, 'short', 'yes'))
                                          else($work//mei:lyricist/string())
                         let $editor := if($work//mei:editor//@codedval)
                                        then(shared:getPersName($work//mei:editor//@codedval, 'short', 'yes'))
                                        else($work//mei:editor/string())
                         let $order := lower-case(normalize-space(if($titleSort)then($titleSort)else($title)))
                         let $status := $work/@status/string()
                         let $statusSymbol := shared:get-status-symbol($status)
                         order by $order
                         return
                             <div class="card bg-light mb-3" name="{$status}">
                                 <div class="card-body">
                                    <div class="row justify-content-between">
                                        <div class="col">
                                            <h5 class="card-title">{work:getWorkTitle($work)}</h5>
                                            {if($titleSub !='')then(<h6>{$titleSub}</h6>)else()}
                                          <h6 class="card-subtitle-baudi text-muted">{shared:translate('conjunction.for'), ' ', work:getPerfRes($work, 'short')}</h6>
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                    </div>
                                    <p class="card-text">{if($composer)
                                                         then(shared:translate('registry.works.composer'),': ',$composer,<br/>)
                                                         else()}
                                                         {if($arranger)
                                                         then(shared:translate('registry.works.arranger'),': ',$arranger,<br/>)
                                                         else()}
                                                        {if($lyricist)
                                                         then(shared:translate('registry.works.lyricist'),': ',$lyricist,<br/>)
                                                         else()}
                                                         {if($editor)
                                                         then(shared:translate('registry.works.editor'),': ',$editor,<br/>)
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
};

(:~
 : Loads edition data into the model map.
 : This is the main data loading function for the edition view.
 :)
declare function app:load-edition($node as node(), $model as map(*)) {
    let $editionID := request:get-parameter("edition-id", "error")
    let $edition := $app:collectionEditions[@xml:id=$editionID]
    
    return
        if ($edition) then
            map:merge((
                $model,
                map {
                    "edition-id": $editionID,
                    "edition": $edition,
                    "edition-title": $edition//edirom:editionName//text(),
                    "edition-works": $edition//edirom:work
                }
            ))
        else
            $model
};

(:~
 : Outputs the edition's title.
 :)
declare function app:edition-title($node as node(), $model as map(*)) {
    $model?edition-title
};

(:~
 : Outputs the edition's ID.
 :)
declare function app:edition-id($node as node(), $model as map(*)) {
    $model?edition-id
};

(:~
 : Outputs the edition's works as cards.
 :)
declare function app:edition-works($node as node(), $model as map(*)) {
    for $work in $model?edition-works
        let $workID := $work/@xml:id/string()
        let $workFile := $app:collectionWorks//mei:work[@xml:id=$workID]
        let $title := work:getWorkTitle($workFile)
        let $composerID := $workFile//mei:composer//@codedval
        let $composer := if($workFile//mei:composer//@codedval)
                          then(shared:getPersName($composerID, 'short', 'yes'))
                          else($workFile//mei:composer/string())
         let $arrangerID := $workFile//mei:arranger//@codedval
         let $arranger := if($workFile//mei:arranger//@codedval)
                          then(shared:getPersName($arrangerID, 'short', 'yes'))
                          else($workFile//mei:arranger/string())
         let $lyricistID := $workFile//mei:lyricist//@codedval
         let $lyricist := if($workFile//mei:lyricist//@codedval)
                          then(shared:getPersName($lyricistID, 'short', 'yes'))
                          else($workFile//mei:lyricist/string())
         let $editorID := $workFile//mei:editor//@codedval
         let $editor := if($editorID)
                        then(shared:getPersName($editorID, 'short', 'yes'))
                        else($workFile//mei:editor/string())
            return
                 <div class="card bg-light mb-3">
                     <div class="card-body">
                        <div class="row justify-content-between">
                            <div class="col">
                                <h5 class="card-title">{$title}</h5>
                            </div>
                        </div>
                        <p class="card-text">
                            {if($composer)
                             then(shared:translate(concat('registry.works.composer',shared:checkGenderforLangValues($composerID))),': ',$composer,<br/>)
                             else()}
                             {if($arranger)
                             then(shared:translate(concat('registry.works.arranger',shared:checkGenderforLangValues($arrangerID))),': ',$arranger,<br/>)
                             else()}
                            {if($lyricist)
                             then(shared:translate(concat('registry.works.lyricist',shared:checkGenderforLangValues($lyricistID))),': ',$lyricist,<br/>)
                             else()}
                             {if($editor)
                             then(shared:translate(concat('registry.works.editor',shared:checkGenderforLangValues($editorID))),': ',$editor,<br/>)
                             else()}
                        </p>
                       <a href="/{$workID}" class="card-link">{$workID}</a>
                     </div>
                 </div>
};

(:~
 : Outputs the edition's XML data.
 :)
declare function app:edition-xml($node as node(), $model as map(*)) {
    serialize(
        app:process-xml-for-display($model?edition), 
        <output:serialization-parameters>
            <output:method>xml</output:method>
            <output:media-type>application/xml</output:media-type>
            <output:indent>no</output:indent>
        </output:serialization-parameters>
    )
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
 let $package := doc($config:app-root || '/expath-pkg.xml')
 let $version := $package//pkg:package/@version/string()
 let $versionStr := substring-before($version, '-')
 let $versionHash := substring-after($version, '-')
    return
        <p class="text-muted">{concat('Version ',$versionStr, ' | Hash: ',$versionHash)}</p>
};

declare function app:registryFilterBar($node as node(), $model as map(*)){
   <div class="alert alert-dark" role="alert">
       <div class="row flex-row-reverse">
           <div class="custom-control custom-switch" >
               <input class="custom-control-input" type="checkbox" id="ampel_rot" oninput="ampel_rot()"/>
               <label class="custom-control-label" style="padding-right:20px;" for="ampel_rot">{shared:translate('proposed')}</label>
           </div>
           <div class="custom-control custom-switch">
               <input class="custom-control-input" type="checkbox" id="ampel_gelb" oninput="ampel_gelb()"/>
               <label class="custom-control-label" style="padding-right:20px;" for="ampel_gelb">{shared:translate('candidate')}</label>
           </div>
           <div class="custom-control custom-switch">
               <input class="custom-control-input" type="checkbox" id="ampel_gruen" oninput="ampel_gruen()"/>
               <label class="custom-control-label" style="padding-right:20px;" for="ampel_gruen">{shared:translate('approved')}</label>
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