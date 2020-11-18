xquery version "3.0";

module namespace app="http://baumann-digital.de/ns/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://exist-db.org/xquery/config" at "config.xqm";
(:import module namespace baudiVersions="http://baumann-digital.de/ns/versions" at "versions.xqm";:)
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace i18n="http://exist-db.org/xquery/i18n" at "i18n.xql";
import module namespace baudiShared="http://baumann-digital.de/ns/baudiShared" at "baudiShared.xqm";
import module namespace baudiWork="http://baumann-digital.de/ns/baudiWork" at "baudiWork.xqm";
import module namespace baudiSource="http://baumann-digital.de/ns/baudiSource" at "baudiSource.xqm";
import module namespace functx = "http://www.functx.com" at "functx.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

declare variable $app:dbRoot as xs:string := '/exist/apps/baudiApp';
declare variable $app:digilibPath as xs:string := 'https://digilib.baumann-digital.de';
declare variable $app:BLBfacPath as xs:string := 'https://digital.blb-karlsruhe.de/blbihd/content/pageview/';
declare variable $app:BLBfacPathImage as xs:string := 'https://digital.blb-karlsruhe.de/blbihd/image/view/';

declare variable $app:collectionWorks := collection('/db/apps/baudiWorks/data')//mei:work;
declare variable $app:collectionSourcesMusic := collection('/db/apps/baudiSources/data/music')//mei:mei;
declare variable $app:collectionPersons := collection('/db/apps/baudiPersons/data')//tei:person;
declare variable $app:collectionInstitutions := collection('/db/apps/baudiInstitutions/data')//tei:org;
declare variable $app:collectionPeriodicals := collection('/db/apps/baudiPeriodicals/data')//tei:TEI;

declare function app:langSwitch($node as node(), $model as map(*)) {
    let $supportedLangVals := ('de', 'en')
    for $lang in $supportedLangVals
        return
            <li class="nav-item">
                <a id="{concat('lang-switch-', $lang)}" class="nav-link" style="{if (baudiShared:get-lang() = $lang) then ('color: white!important;') else ()}" href="?lang={$lang}" onclick="{response:set-cookie('forceLang', $lang)}">{upper-case($lang)}</a>
            </li>
};

declare function app:registryLetters($node as node(), $model as map(*)) {

let $lang := baudiShared:get-lang()
let $letters := collection("/db/apps/baudiSources/data/documents/letters")//tei:TEI
let $datum := $letters//tei:correspAction[@type="sent"]//tei:date/@when/xs:date(.)
let $datum-first := min($datum)
let $datum-last := max($datum)

let $content :=    <div class="container">
                        <br/>
                
                        <div class="container" style=" height: 600px; overflow-y: scroll;">
                            <div class="tab-content">
                                {let $cards := for $letter in $letters
                                                let $titel := $letter//tei:fileDesc/tei:titleStmt/tei:title/data()
                                                let $id := $letter/@xml:id/string()
                                                let $datumSent := $letter//tei:correspAction[@type="sent"]/tei:date/@when
                                                let $status := $letter/@status/string()
                                                let $statusSymbol := if($status='checked')
                                                                     then(<img src="/exist/apps/baudiApp/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                                                     else if($status='public')
                                                                     then(<img src="/exist/apps/baudiApp/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                                                     else(<img src="/exist/apps/baudiApp/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                                                                      
                                                order by $datumSent
                                                 
                                                return
                                                     <div class="card bg-light mb-3">
                                                         <div class="card-body">
                                                           <div class="row justify-content-between">
                                                                <div class="col">
                                                                    <h6 class="card-subtitle mb-2 text-muted">{format-date($datumSent, '[D]. [MI]. [Y]', $lang, (), ())}</h6>
                                                                    <h5 class="card-title">{$titel}</h5>
                                                                    <h6 class="card-subtitle mb-2 text-muted"></h6>
                                                                </div>
                                                                <div class="col-2">
                                                                    <p class="text-right">{$statusSymbol}</p>
                                                                </div>
                                                           </div>
                                                           <p class="card-text"/>
                                                           <a href="{concat($app:dbRoot,'/letter/',$id)}" class="card-link">{$id}</a>
                                                           <hr/>
                                                           <p>Tags</p>
                                                         </div>
                                                     </div>
                               
                                    return
                                        $cards}
                             </div>
                          </div>
                   </div>
       
return
   $content

};

declare function app:letter($node as node(), $model as map(*)) {

let $id := request:get-parameter("letter-id", "Fehler")
let $letter := collection("/db/apps/baudiSources/data/documents/letters")//tei:TEI[@xml:id=$id]
let $pages := $letter/tei:text/tei:body/tei:div[@type='page']/@n/normalize-space(data(.))

return
(
<div class="container">
    <div class="page-header">
        <a href="../registryLetters.html">&#8592; zum Briefeverzeichnis</a>
            <h1>{$letter//tei:fileDesc/tei:titleStmt/tei:title/normalize-space(data(.))}</h1>
            <h5><a href="{document-uri($letter)}" download="{concat($id,'.xml')}">{$id}</a></h5>
    </div>
 <ul class="nav nav-pills" role="tablist">
    <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#datenblatt" role="tab" aria-controls="home" aria-selected="true">Datenblatt</a></li>
    { 
        for $tab in $pages
        let $tabCounted := $tab
        let $tabID := concat('#seite-',$tabCounted)
        
        return
    <li class="nav-item"><a class="nav-link" data-toggle="tab" href="{$tabID}" role="tab" aria-controls="{$tabCounted}" aria-selected="false">[Seite {$tabCounted}]</a></li>
    }
  </ul>
    <!-- Tab panels -->
    <div class="tab-content">
    <div class="tab-pane fade show active" id="datenblatt" role="tabpanel">
        {transform:transform($letter//tei:teiHeader,doc("/db/apps/baudiApp/resources/xslt/metadataLetter.xsl"), ())}
    </div>
    
    {if (count($pages)=1)
    then(
    <div class="tab-pane fade" id="seite-1" role="tabpanel">
    <div class="row">
        <div class="col">
            <br/>
                <div class="col">
                <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#bigPicture">
  Vollansicht
</button>
</div>
                <br/><br/>
                <img src="{
                if (exists($letter//tei:div[@type='page' and @n='1' and @facs]))
                then(concat('https://digilib.baumann-digital.de/documents/',$letter//tei:div[@type='page' and @n='1']/@facs))
                else(concat('https://digilib.baumann-digital.de/documents/',$id,'-1','?dw=500'))}" class="img-thumbnail" width="400"/>
            </div>
        <div class="col">
                <br/>
                <strong>Transkription</strong>
                <br/><br/>
                {transform:transform($letter//tei:div[@type='page' and @n='1'],doc("/db/apps/baudiApp/resources/xslt/contentLetter.xsl"), ())}
        </div>
        <!-- Modal -->
    <div class="modal fade bd-example-modal-lg" id="bigPicture" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
  <div class="modal-header">
        <h5 class="modal-title" id="exampleModalCenterTitle">Seite 1 von 1</h5>
      </div>
      <div class="modal-body">
        <img src="{
                if (exists($letter//tei:div[@type='page' and @n='1' and @facs]))
                then(concat('https://digilib.baumann-digital.de/documents/',$letter//tei:div[@type='page' and @n='1']/@facs))
                else(concat('https://digilib.baumann-digital.de/documents/',$id,'-1','?dw=1000'))}" class="img-thumbnail center"/>
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
        for $page in $pages
        let $letterOrigFacs := concat('https://digilib.baumann-digital.de/documents/',$letter//tei:div[@type='page' and @n=$page]/@facs)
        let $letterOrigLink := concat('https://digilib.baumann-digital.de/documents/',$id,'-',$page,'?dw=500')
     
        return
        
    <div class="tab-pane fade" id="{concat('seite-',$page)}" role="tabpanel">
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

declare function app:registryDocuments($node as node(), $model as map(*)) {

let $lang := baudiShared:get-lang()
let $documents := collection("/db/apps/baudiSources/data/documents")//tei:TEI[@type='certificate' or @type='Bericht']

let $content :=    <div class="container">
                        <br/>
                
                        <div class="container" style=" height: 600px; overflow-y: scroll;">
                            <div class="tab-content">
                                {let $cards := for $document in $documents
                                                let $titel := $document//tei:fileDesc/tei:titleStmt/tei:title
                                                let $id := $document/@xml:id/string()
                                                let $status := $document/@status/string()
                                                let $statusSymbol := if($status='checked')
                                                                     then(<img src="/exist/apps/baudiApp/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                                                     else if($status='published')
                                                                     then(<img src="/exist/apps/baudiApp/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                                                     else(<img src="/exist/apps/baudiApp/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                                                                      
                                                order by $titel
                                                return
                                                     <div class="card bg-light mb-3">
                                                         <div class="card-body">
                                                           <div class="row justify-content-between">
                                                                <div class="col">
                                                                    <h5 class="card-title">{$titel/normalize-space(data(.))}</h5>
                                                                </div>
                                                                <div class="col-2">
                                                                    <p class="text-right">{$statusSymbol}</p>
                                                                </div>
                                                           </div>
                                                           <p class="card-text"/>
                                                           <a href="{concat($app:dbRoot,'/document/',$id)}" class="card-link">{$id}</a>
                                                           <hr/>
                                                           <p>Tags</p>
                                                         </div>
                                                     </div>
                               
                                    return
                                        $cards}
                             </div>
                          </div>
                   </div>
       
return
   $content
};

declare function app:document($node as node(), $model as map(*)) {
let $id := request:get-parameter("document-id", "Fehler")
let $dokument := collection("/db/apps/baudiSources/data/documents")/tei:TEI[@xml:id=$id]
let $pages := $dokument/tei:text/tei:body/tei:div[@type='page']/@n/normalize-space(data(.))

return
(
<div class="container">
    <div class="page-header">
        <a href="../registryDocuments.html">&#8592; zum Dokumentenverzeichnis</a>
            <h1>{$dokument//tei:fileDesc/tei:titleStmt/tei:title/normalize-space(data(.))}</h1>
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
        {transform:transform($dokument//tei:text,doc("/db/apps/baudiApp/resources/xslt/contentDocument.xsl"), ())}
        </div>
        <div class="tab-pane fade" id="daten" >
        {transform:transform($dokument,doc("/db/apps/baudiApp/resources/xslt/namedDate.xsl"), ())}
        </div>
        <div class="tab-pane fade" id="personen" >
        {transform:transform($dokument,doc("/db/apps/baudiApp/resources/xslt/namedPers.xsl"), ())}
        </div>
         <div class="tab-pane fade" id="institutionen" >
        {transform:transform($dokument,doc("/db/apps/baudiApp/resources/xslt/namedInst.xsl"), ())}
        </div>
        <div class="tab-pane fade" id="orte" >
        {transform:transform($dokument,doc("/db/apps/baudiApp/resources/xslt/namedPlace.xsl"), ())}
        </div>
   </div>
</div>
)
};

declare function app:registryPersons($node as node(), $model as map(*)) {
    
    let $lang := baudiShared:get-lang()
    let $persons := collection("/db/apps/baudiPersons/data")//tei:person
      
    let $content := <div class="container">
    <br/>

    <div class="container" style=" height: 600px; overflow-y: scroll;">
    <div class="tab-content">
    {let $cards := for $person in $persons
                    let $surname := $person//tei:surname[1]
                    let $forename := string-join($person//tei:forename,' ')
                    let $name := baudiShared:getPersNameShort($person)
                    let $id := $person/@xml:id/string()
                    
                    let $status := $person/@status/string()
                    let $statusSymbol := if($status='checked')
                                         then(<img src="/exist/apps/baudiApp/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                         else if($status='published')
                                         then(<img src="/exist/apps/baudiApp/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                         else(<img src="/exist/apps/baudiApp/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                                          
                    order by $name
                     
                    return
                         <div class="card bg-light mb-3">
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
                               
                               <a href="{concat($app:dbRoot,'/person/',$id)}" class="card-link">{$id}</a>
                               <hr/>
                               <p>Tags</p>
                             </div>
                         </div>
   
        return
            $cards}
        </div>
      </div>
   </div>
       
       return
        $content

};

declare function app:person($node as node(), $model as map(*)) {
 
let $id := request:get-parameter("person-id", "Fehler")
let $person := collection("/db/apps/baudiPersons/data")//tei:person[@xml:id=$id]
let $surname := $person//tei:surname[1]
let $forename := string-join($person//tei:forename,' ')
let $name := if($surname and $forename)
             then(concat($forename,' ',$surname))
             else if($surname and not($forename))
             then($surname)
             else if (not($surname) and $forename)
             then($forename)
             else($person/tei:persName)

return
(
<div class="container">
    <br/>
    <div class="page-header">
        <h3>{$name}</h3>
        <h5>{$id}</h5>
    </div>
    <hr/>

    <ul class="nav nav-pills" role="tablist">
        <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#tab1">Zur Person</a></li>  
        <!--<li class="nav-item"><a class="nav-link" data-toggle="tab" href="#tab2">Erwähnungen</a></li>-->
    </ul>
  <div class="tab-content">
    <div class="tab-pane fade show active" id="tab1">
    <br/>
        {transform:transform($person,doc("/db/apps/baudiApp/resources/xslt/metadataPerson.xsl"), ())}
        <!--
        <h4>Bezeichnungen</h4>
        <ul>
        {
        for $persName in $namedPersonsDist
        let $persNameDist := $persName/normalize-space(data(.))
        let $Quelle := $persName/ancestor::tei:TEI/@xml:id/data(.)
        order by lower-case($persNameDist)
        return
        (
        <li>{$persNameDist}</li>
        )
        }
        </ul>
        -->
    </div>
    <!--
    <div class="tab-pane fade" id="tab2" >
        <ul>
        {
            for $persName in $namedPersons
            let $persNameDist := $persName/normalize-space(data(.))
            let $Quelle := $persName/ancestor::tei:TEI/@xml:id/data(.)
            order by lower-case($persNameDist)
            return
            <li>{$persNameDist} (in: <b>{concat($Quelle,'.xml')}</b>)</li>
            }
        </ul>
    </div>
    -->
    </div>
</div>
)
};

declare function app:registryPlaces($node as node(), $model as map(*)) {

    let $lang := baudiShared:get-lang()
    let $orte := collection("/db/apps/baudiLoci/data")//tei:place

let $content := 
    <div class="container">
        <br/>

        <div class="container" style=" height: 600px; overflow-y: scroll;">
            <div class="tab-content">
                {let $cards := for $ort in $orte
                                let $name := $ort/tei:placeName[1]
                                let $id := $ort/@xml:id/string()
                                let $status := $ort/@status/string()
                                let $statusSymbol := if($status='checked')
                                                     then(<img src="/exist/apps/baudiApp/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                                     else if($status='published')
                                                     then(<img src="/exist/apps/baudiApp/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                                     else(<img src="/exist/apps/baudiApp/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                                                      
                                order by $name
                                 
                                return
                                     <div class="card bg-light mb-3">
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
                                           
                                           <a href="{concat($app:dbRoot,'/locus/',$id)}" class="card-link">{concat($name, ' (', $id, ')')}</a>
                                           <hr/>
                                           <p>Tags</p>
                                         </div>
                                     </div>
               
                    return
                        $cards}
             </div>
          </div>
   </div>
       
return
   $content
};

declare function app:place($node as node(), $model as map(*)) {

let $id := request:get-parameter("locus-id", "Fehler")
let $ort := collection("/db/apps/baudiLoci/data")/tei:place[@id=$id]
let $name := $ort//tei:title/normalize-space(data(.))

return
(
    <div class="container">
    <a href="../registryPlaces.html">&#8592; zum Ortsverzeichnis</a>
        <div class="page-header">
            <h1>{$name}</h1>
            <h5>{$id}</h5>
        </div>
        Hier wirds irgendwann noch ein paar Infos zu <br/>{$name}<br/> geben.
        {transform:transform($ort,doc("/db/apps/baudiApp/resources/xslt/metadataPlace.xsl"), ())}
    </div>
)
};

declare function app:registryInstitutions($node as node(), $model as map(*)) {
    let $lang := baudiShared:get-lang()
    let $orgs := collection("/db/apps/baudiInstitutions/data")//tei:org
      
    let $content := <div class="container">
    <br/>

    <div class="container" style=" height: 600px; overflow-y: scroll;">
    <div class="tab-content">
    {let $cards := for $org in $orgs
                    let $name := baudiShared:getOrgNameFull($org)
                    let $id := $org/@xml:id/string()
                    
                    let $status := $org/@status/string()
                    let $statusSymbol := if($status='checked')
                                         then(<img src="/exist/apps/baudiApp/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                         else if($status='published')
                                         then(<img src="/exist/apps/baudiApp/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                         else(<img src="/exist/apps/baudiApp/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                                          
                    order by $name
                     
                    return
                         <div class="card bg-light mb-3">
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
                               
                               <a href="{concat($app:dbRoot,'/institution/',$id)}" class="card-link">{$id}</a>
                               <hr/>
                               <p>Tags</p>
                             </div>
                         </div>
   
        return
            $cards}
        </div>
      </div>
   </div>
       
       return
        $content

};

declare function app:institution($node as node(), $model as map(*)) {

let $id := request:get-parameter("institution-id", "Fehler")
let $org := collection("/db/apps/baudiInstitutions/data")//tei:org[@xml:id=$id]
let $name := baudiShared:getOrgNameFull($org)
let $place := $org/tei:location/string()
let $affiliates := for $person in $org//tei:listPerson/tei:person
                    let $persID := $person/tei:persName/@key
                    let $name := $person/tei:persName
                    return
                        <li><a href="{concat($app:dbRoot,'/person/',$persID)}">{$name}</a></li>
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
    let $sources := collection("/db/apps/baudiSources/data/music")/mei:mei//mei:manifestationList/mei:manifestation (:[1]/ancestor::mei:mei:)
    
    let $genres := distinct-values(collection("/db/apps/baudiSources/data/music")//mei:term[@type="source"] | collection("/db/apps/baudiSources/data/music")//mei:titlePart[@type='main' and not(@class)]/@type)
    
    let $content :=<div class="container">
    <br/>
         <ul class="nav nav-pills" role="tablist">
            {for $genre at $pos in $genres
                let $genreCount := count($sources[.//mei:term[@type='source'][. = $genre]])
                let $nav-itemMain := <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">{baudiShared:translate('baudi.catalog.sources.all')} ({count($sources)})</a></li>
                let $nav-itemGenre := <li class="nav-item"><a class="nav-link" data-toggle="tab" href="{concat('#',$genre)}">{baudiShared:translate(concat('baudi.catalog.sources.',$genre))} ({$genreCount})</a></li>
                return
                    if($pos=1)
                    then($nav-itemMain)
                    else($nav-itemGenre)
             }
    </ul>
    <!-- Tab panels -->
    <div class="container" style=" height: 600px; overflow-y: scroll;">
    <div class="tab-content">
    {for $genre at $pos in $genres
        let $cards := for $source in $sources[if($genre='main')then(.)else(.//mei:term[@type='source' and . = $genre])]
                         let $status := if($source/ancestor::mei:mei//mei:availability/text())
                                        then($source/ancestor::mei:mei//mei:availability/text())
                                        else('unchecked')
                         let $statusSymbol := if($status='unchecked')
                                              then(<img src="http://localhost:8080/exist/apps/baudiApp/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                                              else if($status='checked')
                                              then(<img src="http://localhost:8080/exist/apps/baudiApp/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                              else if($status='published')
                                              then(<img src="http://localhost:8080/exist/apps/baudiApp/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                              else($status)
                         let $title := $source//mei:titlePart[@type='main' and not(@class) and not(./ancestor::mei:componentList)]/normalize-space(text()[1])
                         let $titleSort := $title[1]
                         let $titleSub := $source//mei:titlePart[@type='subordinate']/normalize-space(text()[1])
                         let $titleSub2 := $source//mei:titlePart[@type='ediromSourceWindow']/normalize-space(text()[1])
                         let $numberOpus := $source/ancestor::mei:mei//mei:title[@type='uniform' and @xml:lang=$lang]/mei:titlePart[@type='number' and @auth='opus']
                         let $numberOpusCount := $source/ancestor::mei:mei//mei:title[@type='uniform' and @xml:lang=$lang]/mei:titlePart[@type='counter']/text()
                         let $numberOpusCounter := if($numberOpusCount)
                                                   then(concat(' ',baudiShared:translate('baudi.catalog.sources.opus.no'),' ',$numberOpusCount))
                                                   else()
                         let $id := $source/ancestor::mei:mei/@xml:id/normalize-space(data(.))
                         let $perfMedium := baudiSource:getManifestationPerfRes($id)
                         let $composer := $source//mei:composer
                         let $lyricist := $source//mei:lyricist
                         let $componentSources := for $componentSource in $source//mei:componentList/mei:manifestation
                                                    let $componentId := $componentSource/mei:identifier/string()
                                                    return
                                                        $componentId
                         let $termWorkGroup := for $tag in $source//mei:term[@type='workGroup']/string()
                                                let $label := <label class="btn btn-outline-primary btn-sm disabled">{baudiShared:translate(concat('baudi.catalog.tag.',$tag))}</label>
                                                return $label
                         let $termGenre := for $tag in $source//mei:term[@type='genre']/string()
                                               let $label := <label class="btn btn-outline-secondary btn-sm disabled">{baudiShared:translate(concat('baudi.catalog.tag.',$tag))}</label>
                                               return $label
                         let $termSource := for $tag in $source//mei:term[@type='source']/string()
                                                let $label := <label class="btn btn-outline-danger btn-sm disabled">{baudiShared:translate(concat('baudi.catalog.tag.',$tag))}</label>
                                                return $label
                         let $tags := for $each in ($termSource|$termGenre|$termWorkGroup)
                                        order by $each
                                        return ($each,'&#160;')
                         
                         order by $titleSort
                         return
                             <div class="card bg-light mb-3">
                                 <div class="card-body">
                                   <div class="row justify-content-between">
                                        <div class="col">
                                        <h6 class="text-muted">Werk zugewiesen: {if($source//mei:relation[not(@type='edirom')]/@corresp)then(<i>{baudiShared:getWorkTitle($app:collectionWorks[@xml:id=$source//mei:relation/@corresp])}</i>, '&#160;', $source//mei:relation[@rel='isEmbodimentOf' and not(@type='edirom')]/@corresp/string()) else('noch nicht erfolgt!')}</h6>
                                            <h5 class="card-title">{if($numberOpus)then(concat($title,' op. ',$numberOpus,$numberOpusCounter))else($title)}</h5>
                                            {if($titleSub != '')then(<h6 class="card-subtitle mb-2">{$titleSub}</h6>)else()}
                                            {if($titleSub2 != '')then(<h6 class="card-subtitle mb-2">{$titleSub2}</h6>)else()}
                                            <h6 class="card-subtitle-baudi text-muted">{baudiShared:translate('baudi.conjunction.for'), ' ', $perfMedium}</h6>
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                   </div>
                                   <p class="card-text">
                                    {if($composer)
                                     then(baudiShared:translate('baudi.catalog.sources.composer'),': ',$composer,<br/>)
                                     else()}
                                    {if($lyricist)
                                     then(baudiShared:translate('baudi.catalog.sources.lyricist'),': ',$lyricist)
                                     else()}
                                    {if(count($componentSources)>=1)
                                     then(<i>{baudiShared:translate('baudi.catalog.sources.components'), concat(' (', count($componentSources), ')')}</i>)
                                     else()}
                                   </p>
                                   <a href="{concat($app:dbRoot,'/sources/', $source//mei:term[@type='source'][1]/string(), '/',$id)}" class="card-link">{$id}</a>
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
   </div>
       
       return
        $content
       };

declare function app:sources-manuscript($node as node(), $model as map(*)) {

let $id := request:get-parameter("source-id", "Fehler")
let $lang := baudiShared:get-lang()
let $manuscript := collection("/db/apps/baudiSources/data/music")//mei:mei[@xml:id=$id]
let $fileURI := document-uri($manuscript/root())
let $name := $manuscript//mei:manifestation//mei:title/mei:titlePart[@type="main"]/normalize-space(data(.))
let $manuscriptOrig := concat($app:digilibPath,$manuscript/@xml:id)
let $manuscriptTitleUniform := baudiSource:getManifestationTitle($id,'uniform')
let $manuscriptTitleMain := baudiSource:getManifestationTitle($id,'main')
let $manuscriptTitleSub := baudiSource:getManifestationTitle($id,'sub')
let $manuscriptTitlePerf := baudiSource:getManifestationTitle($id,'perf')

let $manuscriptComposer := baudiSource:getManifestationPersona($id,'composer')
let $manuscriptArranger := baudiSource:getManifestationPersona($id,'arranger')
let $manuscriptEditor := baudiSource:getManifestationPersona($id,'editor')
let $manuscriptLyricist := baudiSource:getManifestationPersona($id,'lyricist')

let $manuscriptPerfRes := baudiSource:getManifestationPerfResWithAmbitus($id)

let $facsimileTarget := concat($app:BLBfacPath,$manuscript//mei:facsimile/mei:surface[@n="1"]/mei:graphic/@target)
let $facsimileImageTarget := concat($app:BLBfacPathImage,$manuscript//mei:facsimile/mei:surface[@n="1"]/mei:graphic/@target)

let $msIdentifiers := baudiSource:getManifestationIdentifiers($id)

let $msCondition := $manuscript//mei:condition/mei:p/text()

let $msPaperSpecs := baudiSource:getManifestationPaperSpecs($id)

let $msHands := baudiSource:getManifestationHands($id)
let $msPaperNotes := baudiSource:getManifestationPaperNotes($id)
let $msStamps := baudiSource:getManifestationStamps($id)
let $msNotes := baudiSource:getManifestationNotes($id)

let $msScoreFormat := $manuscript//mei:scoreFormat/text()

let $usedLang := for $lang in $manuscript//mei:langUsage/mei:language/@auth
                    return
                        baudiShared:translate(concat('baudi.lang.',$lang))
let $key := for $each in $manuscript//mei:key
              let $keyPname := $each/@pname
              let $keyMode := $each/@mode
              let $keyAccid := $each/@accid
              let $keyPnameFull := concat($keyPname,$keyAccid)
              return
                  if($keyMode = 'major')
                  then(concat(
                                functx:capitalize-first(baudiShared:translate(concat('baudi.catalog.works.pname.',$keyPnameFull))),
                                baudiShared:translate('baudi.catalog.delimiter.key'),
                                baudiShared:translate(concat('baudi.catalog.works.',$keyMode))
                             )
                        )
                  else if($keyMode = 'minor')
                  then(concat(
                                baudiShared:translate(concat('baudi.catalog.works.pname.',$keyPnameFull)),
                                baudiShared:translate('baudi.catalog.delimiter.key'),
                                baudiShared:translate(concat('baudi.catalog.works.',$keyMode))
                             )
                      )
                  else()
let $meter := for $each in $manuscript//mei:meter
                let $meterCount := $each/@count
                let $meterUnit := $each/@unit
                let $meterSym := $each/@sym
                let $meterSymbol := if($meterSym = 'common')
                                   then(<img src="/exist/apps/baudiApp/resources/img/timeSignature_common.png" width="20px"/>)
                                   else if($meterSym = 'cut')
                                   then(<img src="/exist/apps/baudiApp/resources/img/timeSignature_cut.png" width="20px"/>)
                                   else()
                return
                    if($meterSymbol)
                    then($meterSymbol)
                    else(concat($meterCount, '/', $meterUnit))
let $tempo := $manuscript//mei:work/mei:tempo/text()

return
(
    <div class="container">
        <br/>
        <div class="page-header"/>
        <br/>
        <div class="row">
       {if(exists($manuscript//mei:facsimile/mei:surface))
       then(
        <div class="col">
                {
                if(doc-available(concat($manuscriptOrig,'_001','.jpeg')))
                then(<img src="{concat($manuscriptOrig,'_001','.jpeg')}" width="400"/>)
                else if($manuscript//mei:graphic[@targettype="blb-vlid"])
                then(<a href="{$facsimileTarget}" target="_blank" data-toggle="tooltip" data-placement="top" title="Zum vollständigen Digitalisat unter digital.blb-karlsruhe.de"><img class="img-thumbnail" src="{$facsimileImageTarget}" width="400"/></a>)
                else()
                }
                
                <div>
                <br/>
                {baudiShared:translate('baudi.catalog.sources.facsimile.source')}: Badische Landesbibliothek Karlsruhe</div>
        </div>
        )
        else()}
    <div class="col">
      <ul class="nav nav-pills" role="tablist">
          <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">{baudiShared:translate('baudi.catalog.sources.tab.main')}</a></li>  
          <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#detail">{baudiShared:translate('baudi.catalog.sources.tab.detail')}</a></li>
          <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#lyrics">{baudiShared:translate('baudi.catalog.sources.tab.lyrics')}</a></li>
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
               <td>ID:</td>
               <td>{$id}</td>
            </tr>
             {if($manuscriptTitleUniform)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.sources.titleUniform')}</td>
                    <td>{$manuscriptTitleUniform}</td>
                  </tr>)
             else()}
             {if($manuscriptTitleMain)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.sources.title')}</td>
                    <td>{$manuscriptTitleMain}</td>
                  </tr>)
             else()}
             {if($manuscriptTitleSub)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.sources.titleSub')}</td>
                    <td>{$manuscriptTitleSub}</td>
                  </tr>)
             else()}
             </table>
             <table class="sourceView">
             {if($manuscriptComposer)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.sources.composer')}</td>
                    <td>{$manuscriptComposer}</td>
                  </tr>)
             else()}
             {if($manuscriptArranger)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.sources.arranger')}</td>
                    <td>{$manuscriptArranger}</td>
                  </tr>)
             else()}
             {if($manuscriptLyricist)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.sources.lyricist')}</td>
                    <td>{$manuscriptLyricist}</td>
                  </tr>)
             else()}
             {if($manuscriptEditor)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.sources.editor')}</td>
                    <td>{$manuscriptEditor}</td>
                  </tr>)
             else()}
             </table>
             <table class="sourceView">
             {if(not($usedLang/data(.) = ''))
             then(<tr>
                    <td>{if(count($usedLang) = 1)
                         then(baudiShared:translate('baudi.catalog.works.langUsed'))
                         else if(count($usedLang) > 1)
                         then(baudiShared:translate('baudi.catalog.works.langsUsed'))
                         else()}</td>
                    <td>{string-join($usedLang,', ')}</td>
                  </tr>)
             else()}
             
             {if(count($key) > 0)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.key')}</td>
                    <td>{normalize-space(string-join($key, ' | '))}</td>
                  </tr>)
             else()}
             {if(count($meter) > 0)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.meter')}</td>
                    <td>{$meter}</td>
                  </tr>)
             else()}
             {if($tempo)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.tempo')}</td>
                    <td><i>{normalize-space($tempo)}</i></td>
                  </tr>)
             else()}
             {if($manuscriptPerfRes)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.sources.perfRes')}</td>
                    <td>{$manuscriptPerfRes}</td>
                  </tr>)
             else()}
             </table>
              </div>
          </div>
          <div class="tab-pane fade" id="detail">
              <div class="container">
              <br/>
                {$msIdentifiers}
                {if ($msPaperSpecs)
                 then ($msPaperSpecs)
                 else ()}
                 {if ($msHands)
                 then ($msHands)
                 else ()}
                 {if ($msPaperNotes)
                 then ($msPaperNotes)
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
                             <td>{baudiShared:translate('baudi.catalog.sources.msDesc.scoreFormat')}</td>
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
                             <td>{baudiShared:translate('baudi.catalog.sources.msDesc.condition')}</td>
                             <td>
                               {$msCondition}
                             </td>
                           </tr>
                       </table>)
                 else ()}
              </div>
          </div>
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
          </div>
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

declare function app:sources-print($node as node(), $model as map(*)) {

let $id := request:get-parameter("source-id", "Fehler")
let $print := collection("/db/apps/baudiSources/data/music")/mei:mei[@xml:id=$id]
let $fileURI := document-uri($print/root())
let $name := $print//mei:manifestation/mei:titleStmt/mei:title[@type="main"]/normalize-space(data(.))
let $printOrig := concat('../../../../../baudi-images/music/',$print/@xml:id)
let $printOrigBLB := "https://digital.blb-karlsruhe.de/blbihd/image/view/"
let $printDigitalisatBLB := "https://digital.blb-karlsruhe.de/blbihd/content/pageview/"

return
(
    <div class="container">
        <div class="page-header">
            <h1>{$name}</h1>
            <h5>{$id}</h5>
        </div>
        <div class="row">
       {if(exists($print//mei:facsimile/mei:surface))
       then(
        <div class="col">
                {
                if(doc-available(concat($printOrig,'_001','.jpeg')))
                then(<img src="{concat($printOrig,'_001','.jpeg')}" width="400"/>)
                else if($print//mei:graphic[@targettype="blb-vlid"])
                then(<a href="{concat($printDigitalisatBLB,$print//mei:facsimile/mei:surface[@n="1"]/mei:graphic/@target)}" target="_blank"><img src="{concat($printOrigBLB,$print//mei:facsimile/mei:surface[@n="1"]/mei:graphic/@target)}" width="400"/></a>)
                else()
                }
        </div>
        )
        else()}

    <div class="col">
    <ul class="nav nav-pills" role="tablist">
        <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">Überblick</a></li>  
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#detail">Im Detail</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#lyrics">Liedtext</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#verovio">Verovio</a></li>
    </ul>
    <!-- Tab panels -->
    <div class="tab-content">
        <div class="tab-pane fade show active" id="main">
            <hr/>
            <p>
                Zugehöriges Werk: {baudiShared:getWorkTitle($app:collectionWorks[@xml:id=$print//mei:relation/@corresp])} (<a href="{concat('../../work/',$print//mei:relation/@corresp)}">{$print//mei:relation[@rel='isEmbodimentOf']/@corresp/string()}</a>)
            </p>
            <hr/>
            <p/>
                {transform:transform($print,doc("/db/apps/baudiApp/resources/xslt/metadataSourcePrint.xsl"), ())}
            <p/>
            <div class="card">
                <div class="card-body">
                    {if(exists($print//mei:work/mei:incip/mei:score))
                    then('Incipit soon',<span onload="myIncipit({concat('http://localhost:8080/exist/rest',$fileURI)})"> </span>,<div id="output-verovio"/>)
                    else(<b>No incipit available</b>)}
                </div>
            </div>
        </div>
        <div class="tab-pane fade" id="detail">
            <p/>
            {transform:transform($print,doc("/db/apps/baudiApp/resources/xslt/metadataSourcePrintDetailed.xsl"), ())}
        </div>
        <div class="tab-pane fade" id="lyrics">
            <p/>
                {transform:transform($print,doc("/db/apps/baudiApp/resources/xslt/contentLyrics.xsl"), ())}
        </div>
        <div class="tab-pane fade" id="verovio">
            <div class="panel-body">
                <div id="app" class="panel" style="border: 1px solid lightgray; min-height: 800px;"/>
            </div>
        </div>
    </div>
    </div>
    </div>
    </div>
)
};

declare function app:aboutProject($node as node(), $model as map(*)) {

let $text := doc("/db/apps/baudiTexts/data/portal/aboutProject.xml")/tei:TEI//tei:body


return
(
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>Was ist <i>BauDi</i>?</h1>
        </div>
        <hr/>
        <div class="container">
            {transform:transform($text,doc("/db/apps/baudiApp/resources/xslt/formattingText.xsl"), ())}
        </div>
    </div>
)
};

declare function app:aboutBaumann($node as node(), $model as map(*)) {

let $text := doc("/db/apps/baudiTexts/data/portal/aboutBaumann.xml")/tei:TEI//tei:text

return
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>Ludwig Baumann <span class="text-muted" style="font-size: x-large;">(1866–1944)</span></h1>
        </div>
        <hr/>
        <div class="container">
            {transform:transform($text,doc("/db/apps/baudiApp/resources/xslt/formattingText.xsl"), ())}
        </div>
    </div>
};

declare function app:impressum($node as node(), $model as map(*)) {

let $text := doc("/db/apps/baudiTexts/data/portal/impressum.xml")//tei:body

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

let $text := doc('/db/apps/baudiTexts/data/portal/index.xml')

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
                                              then(<img src="http://localhost:8080/exist/apps/baudiApp/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                              else if($status='published')
                                              then(<img src="http://localhost:8080/exist/apps/baudiApp/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                              else(<img src="http://localhost:8080/exist/apps/baudiApp/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)

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
                            <a href="{concat($app:dbRoot,'/periodical/',$id)}" class="card-link">{$id}</a>
                        </div>
                    </div>
        
return
(
<div class="container">
        <br/>
        <div class="page-header">
            <h1><i18n:text key="baudi.catalog.periodocals"/></h1>
        </div>
        <hr/>
        <div class="container">
            {$cards}
        </div>
    </div>
)
};

declare function app:periodical($node as node(), $model as map(*)) {
 
let $id := request:get-parameter("periodical-id", "Fehler")
let $issue := collection("/db/apps/baudiPeriodicals/data")//tei:TEI[@xml:id=$id]
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

let $codingGuidelines := doc('/db/apps/baudiTexts/data/documentation/codingGuidelines.xml')
let $editiorialGuidelines := doc('/db/apps/baudiTexts/data/documentation/editorialGuidelines.xml')
let $sourceDescGuidelines := doc('/db/apps/baudiTexts/data/documentation/sourceDescGuidelines.xml')

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
    
    let $works := collection("/db/apps/baudiWorks/data")//mei:work[not(parent::mei:componentList)]
    let $genres := distinct-values(collection("/db/apps/baudiWorks/data")//mei:work//mei:term[@type="genre"]/text() | collection("/db/apps/baudiWorks/data")//mei:work//mei:titlePart[@type='main' and not(@class)]/@type)
    let $dict := collection("/db/apps/baudiResources/data")
    let $content := <div class="container">
    <br/>
         <ul class="nav nav-pills" role="tablist">
            {for $genre at $pos in $genres
                let $genreDict := if($dict//tei:name[@type=$genre]/text())then($dict//tei:name[@type=$genre]/text())else($genre)
                let $workCount := count($works//mei:term[@type='genre' and . = $genre])
                let $nav-itemMain := <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">{baudiShared:translate('baudi.catalog.works.all')} ({count($works)})</a></li>
                let $nav-itemGenre := <li class="nav-item"><a class="nav-link" data-toggle="tab" href="{concat('#',$genre)}">{baudiShared:translate(concat('baudi.catalog.works.',$genre))} ({$workCount})</a></li>
                return
                    if($pos=1)
                    then($nav-itemMain)
                    else($nav-itemGenre)
             }
    </ul>
    <br/>
    <!-- Tab panels -->
    <div class="container" >
    <div class="tab-content" style=" height: 600px; overflow-y: scroll;">
    {for $genre at $pos in $genres
        let $cards := for $work in $works[if($pos=1)then(.)else(.//mei:term[@type='genre' and . = $genre])]
                         let $title := $work//mei:title[@type='uniform']/mei:titlePart[@type='main' and not(@class)]/normalize-space(text()[1])
                         let $titleSort := $work//mei:title[@type='uniform']/mei:titlePart[@type='mainSort']/text()
                         let $titleSub := $work//mei:title[@type='uniform']/mei:titlePart[@type='subordinate']/normalize-space(text()[1])
                         let $numberOpus := $work//mei:title[@type='uniform']/mei:titlePart[@type='number' and @auth='opus']
                         let $numberOpusCount := $work//mei:title[@type='uniform']/mei:titlePart[@type='counter']/text()
                         let $numberOpusCounter := if($numberOpusCount)
                                                   then(concat(' ',baudiShared:translate('baudi.catalog.works.opus.no'),' ',$numberOpusCount))
                                                   else()
                         let $id := $work/@xml:id/string()
                         let $composer := if($work//mei:composer//@auth)
                                          then(baudiShared:getName($work//mei:composer/mei:persName/@auth/string(), 'short'))
                                          else($work//mei:composer/string())
                         let $arranger := if($work//mei:arranger//@auth)
                                          then(baudiShared:getName($work//mei:arranger/mei:persName/@auth/string(), 'short'))
                                          else($work//mei:arranger/string())
                         let $lyricist := if($work//mei:lyricist//@auth)
                                          then(baudiShared:getName($work//mei:lyricist/mei:persName/@auth/string(), 'short'))
                                          else($work//mei:lyricist/string())
                         let $editor := if($work//mei:editor//@auth)
                                        then(baudiShared:getName($work//mei:editor/mei:persName/@auth/string(), 'short'))
                                        else($work//mei:editor/string())
                         let $componentWorks := for $componentWork in $work//mei:componentList/mei:work
                                                    let $componentId := $componentWork/mei:identifier[@type="baudiWork"]/string()
                                                    return
                                                        $works[@xml:id=$componentId]
                         let $relatedItems := for $rel in $work//mei:relationList/mei:relation
                                                return
                                                    $app:collectionSourcesMusic[@xml:id=$rel/@target]//mei:work
                         let $termWorkGroup := for $tag in $work//mei:term[@type='workGroup']/text()
                                                let $label := <label class="btn btn-outline-primary btn-sm disabled">{baudiShared:translate(concat('baudi.catalog.works.',$tag))}</label>
                                                return $label
                         let $termGenre := for $tag in $work//mei:term[@type='genre']/text()
                                               let $label := <label class="btn btn-outline-secondary btn-sm disabled">{baudiShared:translate(concat('baudi.catalog.works.',$tag))}</label>
                                               return $label
                         let $tags := for $each in ($termGenre|$termWorkGroup)
                                        return ($each,'&#160;')
                         let $order := lower-case(normalize-space(if($titleSort)then($titleSort)else($title)))
                         let $status := $work/@status/string()
                         let $statusSymbol := if($status='checked')
                                              then(<img src="http://localhost:8080/exist/apps/baudiApp/resources/img/ampel_gelb.png" alt="{$status}" width="10px"/>)
                                              else if($status='published')
                                              then(<img src="http://localhost:8080/exist/apps/baudiApp/resources/img/ampel_gruen.png" alt="{$status}" width="10px"/>)
                                              else(<img src="http://localhost:8080/exist/apps/baudiApp/resources/img/ampel_rot.png" alt="{$status}" width="10px"/>)
                         order by $order
                         return
                             <div class="card bg-light mb-3" status="{$status}">
                                 <div class="card-body">
                                    <div class="row justify-content-between">
                                        <div class="col">
                                            <h5 class="card-title">{baudiShared:getWorkTitle($work)}</h5>
                                            {if($titleSub !='')then(<h6>{$titleSub}</h6>)else()}
                                            <h6 class="card-subtitle-baudi text-muted">{baudiShared:translate('baudi.conjunction.for'), ' ', if($id)then(baudiWork:getPerfRes($id))else(concat('IDnotFound!',document-uri($work/root())))}</h6>
                                        </div>
                                        <div class="col-2">
                                            <p class="text-right">{$statusSymbol}</p>
                                        </div>
                                    </div>
                                    <p class="card-text">{if($composer)
                                                         then(baudiShared:translate('baudi.catalog.works.composer'),': ',$composer,<br/>)
                                                         else()}
                                                         {if($arranger)
                                                         then(baudiShared:translate('baudi.catalog.works.arranger'),': ',$arranger,<br/>)
                                                         else()}
                                                        {if($lyricist)
                                                         then(baudiShared:translate('baudi.catalog.works.lyricist'),': ',$lyricist,<br/>)
                                                         else()}
                                                         {if($editor)
                                                         then(baudiShared:translate('baudi.catalog.works.editor'),': ',$editor,<br/>)
                                                         else()}
                                                        {if(count($componentWorks)>=1)
                                                         then(baudiShared:translate('baudi.catalog.works.components'),': ',
                                                                <ul>{for $each in $componentWorks
                                                                return <li>{baudiShared:getWorkTitle($each)}</li>}</ul>,<br/>)
                                                         else()}
                                                         {if(count($relatedItems)>=1)
                                                         then(baudiShared:translate('baudi.catalog.works.relSources'),': ',
                                                                <ul>{for $each in $relatedItems
                                                                        let $relId := substring-before($each/@xml:id/string(),'-work')
                                                                        let $sourceType := switch ($each/ancestor::mei:meiHead//mei:manifestation[1]/@class)
                                                                        case '#ms' return 'manuscript'
                                                                        case '#pr' return 'print'
                                                                        default return ''
                                                                return <li>{baudiShared:getWorkTitle($each)} (<a href="{$app:dbRoot}/sources/{$sourceType}/{$relId}">{$relId}</a>)</li>}</ul>,<br/>)
                                                         else()}</p>
                                   <a href="{concat($app:dbRoot,'/work/',$id)}" class="card-link">{$id}</a>
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
   </div>
       
       return
        $content
       };
       
declare function app:work($node as node(), $model as map(*)) {

let $id := request:get-parameter("work-id", "Fehler")
let $lang := baudiShared:get-lang()
let $work := collection("/db/apps/baudiWorks/data")//mei:work[@xml:id=$id]
let $fileURI := document-uri($work/root())
let $title := $work//mei:title[@type='uniform']/mei:titlePart[@type='main' and not(@class)]/normalize-space(.)
let $subtitle := $work//mei:title[@type='uniform']/mei:titlePart[@type = 'subordinate']/normalize-space(.)
let $numberOpus := $work//mei:title[@type='uniform']/mei:titlePart[@type='number' and @auth='opus']
let $perfMedium := $work//mei:title[@type='uniform']/mei:titlePart[@type = 'perfmedium']
let $titleMainAlt := $work//mei:titlePart[@type = 'mainAlt']
let $titleSubAlt := $work//mei:title[@type='uniform']/mei:titlePart[@type = 'subAlt']
let $composer := $work//mei:composer
let $composerID := $composer/mei:persName/@auth
let $composerEntry := if($composerID)
                      then($app:collectionPersons[matches(@xml:id,$composerID)])
                      else($composer)
let $composerName := baudiShared:getPersNameShortLinked($composerEntry)
let $composerGender := if($composerEntry[@sex="female"]) then('composer.female') else('composer')
let $lyricist := $work//mei:lyricist
let $lyricistID := $lyricist/mei:persName/@auth
let $lyricistEntry := if($lyricistID)
                      then($app:collectionPersons[matches(@xml:id,$lyricistID)])
                      else($lyricist)
let $lyricistName := if($lyricistID)
                      then(baudiShared:getPersNameShortLinked($lyricistEntry))
                      else($lyricist)
let $lyricistGender := if($lyricistEntry)
                       then('lyricist.female')
                       else('lyricist')

let $usedLang := for $lang in $work//mei:langUsage/mei:language/@auth
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
                                functx:capitalize-first(baudiShared:translate(concat('baudi.catalog.works.pname.',$keyPnameFull))),
                                baudiShared:translate('baudi.catalog.delimiter.key'),
                                baudiShared:translate(concat('baudi.catalog.works.',$keyMode))
                             )
                        )
                  else if($keyMode = 'minor')
                  then(concat(
                                baudiShared:translate(concat('baudi.catalog.works.pname.',$keyPnameFull)),
                                baudiShared:translate('baudi.catalog.delimiter.key'),
                                baudiShared:translate(concat('baudi.catalog.works.',$keyMode))
                             )
                      )
                  else()
let $meter := for $each in $work//mei:meter
                let $meterCount := $each/@count
                let $meterUnit := $each/@unit
                let $meterSym := $each/@sym
                let $meterSymbol := if($meterSym = 'common')
                                   then(<img src="/exist/apps/baudiApp/resources/img/timeSignature_common.png" width="20px"/>)
                                   else if($meterSym = 'cut')
                                   then(<img src="/exist/apps/baudiApp/resources/img/timeSignature_cut.png" width="20px"/>)
                                   else()
                return
                    if($meterSymbol)
                    then($meterSymbol)
                    else(concat($meterCount, '/', $meterUnit))
let $tempo := $work//mei:work/mei:tempo/text()

let $workgroup := $work//mei:term[@type='workGroup']/text()
let $genre := $work//mei:term[@type='genre']/text()

let $perfResLists := $work//mei:perfResList
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

let $incipURI := concat('http://localhost:8080/exist/rest',$fileURI) (: '?_query=//incip' :)

return
(
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>{if($numberOpus)then(concat($title,' op. ',$numberOpus))else($title)}</h1>
            {if($subtitle)then(<h4 class="text-muted">{$subtitle}</h4>)else()}
            <h5>ID: {$id}</h5>
        </div>
        <br/>
    <div class="col">
        <table class="workView">
            <tr>
                <th/>
                <th/>
            </tr>
            {if($perfMedium)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.perfmedium')}</td>
                    <td>{normalize-space($perfMedium)}</td>
                  </tr>)
             else()}
             {if($titleMainAlt)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.titleAlt')}</td>
                    <td>{normalize-space($titleMainAlt)}</td>
                  </tr>)
             else()}
             {if($titleSubAlt)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.subtitleAlt')}</td>
                    <td>{normalize-space($titleSubAlt)}</td>
                  </tr>)
             else()}
             {if(not($composerName = ''))
             then(<tr>
                    <td>{baudiShared:translate(concat('baudi.catalog.works.',$composerGender))}</td>
                    <td>{$composerName}</td>
                  </tr>)
             else()}
             {if(not($lyricistName = ''))
             then(<tr>
                    <td>{baudiShared:translate(concat('baudi.catalog.works.',$lyricistGender))}</td>
                    <td>{$lyricistName}</td>
                  </tr>)
             else()}
             {if(not($usedLang/data(.) = ''))
             then(<tr>
                    <td>{if(count($usedLang) = 1)
                         then(baudiShared:translate('baudi.catalog.works.langUsed'))
                         else if(count($usedLang) > 1)
                         then(baudiShared:translate('baudi.catalog.works.langsUsed'))
                         else()}</td>
                    <td>{string-join($usedLang,', ')}</td>
                  </tr>)
             else()}
             
             {if(count($key) > 0)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.key')}</td>
                    <td>{normalize-space(string-join($key, ' | '))}</td>
                  </tr>)
             else()}
             {if(count($meter) > 0)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.meter')}</td>
                    <td>{$meter}</td>
                  </tr>)
             else()}
             {if($tempo)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.tempo')}</td>
                    <td><i>{normalize-space($tempo)}</i></td>
                  </tr>)
             else()}
             {if($workgroup)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.category')}</td>
                    <td>{baudiShared:translate(concat('baudi.catalog.works.',$workgroup))}</td>
                  </tr>)
             else()}
             {if($genre)
             then(<tr>
                    <td>{baudiShared:translate('baudi.catalog.works.genre')}</td>
                    <td>{baudiShared:translate(concat('baudi.catalog.works.',$genre))}</td>
                  </tr>)
             else()}
             {if($perfResList)
             then(<tr>
                    <td style="vertical-align: top;">{baudiShared:translate('baudi.catalog.works.perfRes')}</td>
                    <td>{baudiWork:getPerfResDetail($id)}</td>
                  </tr>)
             else()}
             </table>
        
        {if(exists($work//mei:incip/mei:score))
                      then(<div class="panel-body" onload="myIncipit({$incipURI})">
                               <!--  $manuscript//mei:work/mei:incip myIncipit('https://www.verovio.org/editor/brahms.mei') -->
                               <div id="verovioIncipit"/> <!-- style="border: 1px solid lightgray; max-width: 50%; max-height: 300px;" -->
                           </div>)
                      else()}
        
        <table class="workView">
        <tr>
           <td colspan="2">Zugehörige Quellen:</td>
        </tr>
        <tr>
            <td colspan="2">
                <ul style="list-style-type: square;">
                    {for $source in $app:collectionSourcesMusic
                        let $sourceId := $source/@xml:id/string()
                        let $sourceType := $source//mei:term[@type='source'][1]/string()
                        let $sourceTypeTranslated := baudiShared:translate(concat('baudi.catalog.sources.',$sourceType))
                        let $sort := switch ($sourceType)
                                        case 'manuscript' return '01'
                                        case 'msCopy' return '02'
                                        case 'print' return '03'
                                        case 'prCopy' return '04'
                                        case 'copy' return '05'
                                        case 'edition' return '06'
                                        default return '00'
                        let $correspWork := $source//mei:relation[@corresp=$id]/@corresp
                        let $correspWorkLabel := $source//mei:relation[@corresp=$id]/@label/string()
                        let $sourceTitle := $source//mei:manifestation//mei:titlePart[@type='main' and not(@class) and not(./ancestor::mei:componentList)]/normalize-space(text()[1])
                        where $correspWork = $id
                        order by $sort
                        return
                            <li>{$sourceTitle} [{$sourceTypeTranslated}] (<a href="{concat('../sources/', $sourceType, '/', $sourceId)}">{$sourceId}</a>)</li>
                    }
                </ul>
            </td>
        </tr>
        </table>
        
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
