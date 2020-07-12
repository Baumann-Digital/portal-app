xquery version "3.0";

module namespace app="http://baumann-digital.de/ns/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://baumann-digital.de/ns/config" at "config.xqm";
(:import module namespace baudiVersions="http://baumann-digital.de/ns/versions" at "versions.xqm";:)
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace functx = "http://www.functx.com";

declare function functx:is-node-in-sequence-deep-equal
  ( $node as node()? ,
    $seq as node()* )  as xs:boolean {

   some $nodeInSeq in $seq satisfies deep-equal($nodeInSeq,$node)
 };
 
declare function functx:distinct-deep
  ( $nodes as node()* )  as node()* {

    for $seq in (1 to count($nodes))
    return $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(.,$nodes[position() < $seq]))]
 };
 
declare function app:registryLetters($node as node(), $model as map(*)) {
   
    let $letters := collection("/db/apps/baudiSources/data/documents/letters")//tei:TEI
    let $datum := $letters//tei:correspAction[@type="sent"]//tei:date/@when/xs:date(.)
    let $datum-first := min($datum)
    let $datum-last := max($datum)

(:
    TODO:
    - filtern nach absender, empfänger, datum  
:)
return
(
    <div class="container">
      <p>Das Briefeverzeichnis enthält zur Zeit { count($letters) } transkribierte Briefe.</p>
      <p>Die erfassten Briefe wurden in den Jahren {
        substring($datum-first,1,4)
        } bis {
        substring($datum-last,1,4)
        } geschrieben.</p>
        
        <ul class="nav nav-pills" role="tablist">
        <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#briefe">Briefe</a></li>  
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#adressaten">Adressaten</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#absender">Absender</a></li>
    </ul>
    <!-- Tab panels -->
    <div class="tab-content">
        <div class="tab-pane fade show active" id="briefe" >
        <br/>
        {
        for $letter in $letters
        let $titel := $letter//tei:fileDesc/tei:titleStmt/tei:title
        let $id := $letter/@xml:id
        let $datumSent := $letter//tei:correspAction[@type="sent"]/tei:date/@when
        order by $datumSent
        return
        <li><a href="letter/{$id}">{$titel/normalize-space(data(.))}</a> <span> </span> ({$id/normalize-space(data(.))})</li>
        }
      
        </div>
        <div class="tab-pane fade" id="adressaten" >
        
        <p><ul>{
      let $valuesRec := distinct-values($letters//tei:correspAction[@type="received"]/tei:persName[@key])
      for $valueRec in $valuesRec
      order by $valueRec
      return
      <li>{$valueRec}</li>
        }</ul>
        </p>
        </div>
        <div class="tab-pane fade" id="absender" >
        
      <p><ul>{
      let $valuesSent := distinct-values($letters//tei:correspAction[@type="sent"]/tei:persName/normalize-space(data(.)))
      for $valueSent in $valuesSent
      order by $valueSent
      return
      <li>{$valueSent}</li>
        }</ul>
        </p>
        </div>
   </div>
        
      
    </div>
)
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
   
    let $dokumente := collection("/db/apps/baudiSources/data/documents")//tei:TEI[@type='certificate' or @type='Bericht']
    let $datum := $dokumente//tei:correspAction[@type="sent"]//tei:date/@when/xs:date(.)
    let $datum-first := min($datum)
    let $datum-last := max($datum)
(:    order by $title :)

return
    <div class="container">
      <p>Das Dokumentenverzeichnis enthält zur Zeit { count($dokumente) } Inhalte.</p>
      <p>Die erfassten Schriften wurden in den Jahren {
        substring($datum-first,1,4)
        } bis {
        substring($datum-last,1,4)
        } verfasst.</p>
      <ul>
        {
        for $dokument in $dokumente
        let $titel := $dokument//tei:fileDesc/tei:titleStmt/tei:title
        let $id := $dokument/@xml:id
        let $datumVerfasst := $dokument//tei:correspAction[@type="sent"]/tei:date/@when
        order by $titel
        return
        <li><a href="document/{$id}">{$titel/normalize-space(data(.))}</a> <span> </span> ({$id/normalize-space(data(.))})</li>
        }
      </ul>
    </div>

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

    let $personen := collection("/db/apps/baudiPersons/data")//tei:person
    let $namedPersonsDist := functx:distinct-deep(collection("/db/apps/baudiSources/data")//tei:text//tei:persName[normalize-space(.)])
    let $namedPersons := collection("/db/apps/baudiSources/data")//tei:text//tei:persName[normalize-space(.)]
    
return
(
<div class="container">
    <ul class="nav nav-pills" role="tablist">
        <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#tab1">Personendateien</a></li>  
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#tab2">Alle Erwähnungen</a></li>
    </ul>
    <div class="tab-content">
    <div class="tab-pane fade show active" id="tab1">
        <p>Das Personenverzeichnis enthält weiterfündende Informationen zu {count($personen)} Personen.</p>
      <ul>
        {
        for $person in $personen
        let $surname := $person//tei:surname[1]
        let $forename := $person//tei:forename[1]
        let $id := $person/@id
        order by $surname, $forename
        return
        <li><a href="person/{$id}">{concat(normalize-space(data($surname)),', ',normalize-space(data($forename)))}</a> ({normalize-space($id)})</li>
        }
      </ul>
    </div>
    <div class="tab-pane fade" id="tab2" >
        <p>Alle Vorkommen von Personen in alphabetischer Reihenfolge</p>
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
        </div>
    </div>
)
};

declare function app:person($node as node(), $model as map(*)) {
 
let $id := request:get-parameter("person-id", "Fehler")
let $person := collection("/db/apps/baudiPersons/data")//tei:person[@id=$id]
let $name := $person//tei:title/normalize-space(data(.))
(:let $namedPersons := collection("/db/apps/baudiSources/data")//tei:text//tei:persName[@key=$id]:)
(:let $namedPersonsDist := functx:distinct-deep(collection("/db/apps/baudiSources/data")//tei:text//tei:persName[@key=$id]):)

return
(
<div class="row">
    <div class="page-header">
        <a href="../registryPersons.html">&#8592; zum Personenverzeichnis</a>
        <h1>{$name}</h1>
        <h5>{$id}</h5>
    </div>
    <div class="container">
            <ul class="nav nav-pills" role="tablist">
                <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#tab1">Zur Person</a></li>  
                <!--<li class="nav-item"><a class="nav-link" data-toggle="tab" href="#tab2">Erwähnungen</a></li>-->
            </ul>
          <div class="tab-content">
            <div class="tab-pane fade show active" id="tab1">
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
</div>
)
};

declare function app:registryPlaces($node as node(), $model as map(*)) {

    let $orte := collection("/db/apps/baudiLoci/data")//tei:place

return
(
    <div class="container">
        <p>Im Orteverzeichnis sind {count($orte)} Orte.</p>
      <ul>
        {
        for $ort in $orte
        let $name := $ort/tei:placeName
        let $id := $ort/@id
        order by $name
        return
        <li><a href="locus/{$id}">{$name/normalize-space(data(.))}</a> <span> </span> ({$id/normalize-space(data(.))})</li>
        }
      </ul>
    </div>
)
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
    let $institutionen := collection("/db/apps/baudiInstitutions/data")//tei:institution

return
(
    <div class ="container">
        <p>Im Institutionenverzeichnis sind {count($institutionen)} Institutionen verzeichnet.</p>
      <ul>
        {
        for $institution in $institutionen
        let $name := $institution/tei:orgName[@type="used"]
        let $id := $institution/@id
        order by $name
        return
        <li><a href="institution/{$id}">{$name/normalize-space(data(.))}</a> ({$id/normalize-space(data(.))})</li>
        }
      </ul>
    </div>
)
};

declare function app:institution($node as node(), $model as map(*)) {

let $id := request:get-parameter("institution-id", "Fehler")
let $institution := collection("/db/apps/baudiInstitutions/data")/tei:institution[@id=$id]
let $name := $institution/tei:orgName[@type="used"]

return
(
    <div class="container">
    <a href="../registryInstitutions.html">&#8592; zum Institutionenverzeichnis</a>
        <div class="page-header">
            <h1>{$name}</h1>
            <h5>{$id}</h5>
        </div>
        {transform:transform($institution,doc("/db/apps/baudiApp/resources/xslt/metadataInstitution.xsl"), ())}
    </div>
)
};

declare function app:registrySources($node as node(), $model as map(*)) {
    
    let $sourcesToDo := collection("/db/apps/baudiSources/data/music")//mei:mei//mei:term[@type='todo']/ancestor::mei:mei
    let $sources-manuscripts := collection("/db/apps/baudiSources/data/music")/mei:mei//mei:manifestationList/mei:manifestation[1][contains(@class,'#ms') and not(contains(@class,'#coll'))]/ancestor::mei:mei
    let $sources-manuscripts-Coll := collection("/db/apps/baudiSources/data/music/collections")/mei:mei//mei:manifestationList/mei:manifestation[1][contains(@class,'#ms') and contains(@class,'#coll')]/ancestor::mei:mei
    let $sources-prints := collection("/db/apps/baudiSources/data/music")/mei:mei//mei:manifestationList/mei:manifestation[1][contains(@class,'#pr') and not(contains(@class,'#coll'))]/ancestor::mei:mei
    let $sources-songs := collection("/db/apps/baudiSources/data/music")/mei:mei//mei:term[@type='genre' and .='song']/ancestor::mei:mei
    let $sources-choirs := collection("/db/apps/baudiSources/data/music")/mei:mei//mei:term[@type='genre' and .='choir']/ancestor::mei:mei
    
return
(
    <div class="container">
         <ul class="nav nav-pills" role="tablist">
        <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#manuscripts">Manuskripte ({count($sources-manuscripts)})</a></li>  
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#prints">Drucke ({count($sources-prints)})</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#songs">Lieder ({count($sources-songs)})</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#choirs">Chöre ({count($sources-choirs)})</a></li>
        <li class="nav-item"><a class="nav-link" data-toggle="tab" href="#todos">ToDos ({count($sourcesToDo)})</a></li>
    </ul>
    <!-- Tab panels -->
    <div class="tab-content">
        <div class="tab-pane fade show active" id="manuscripts" >
        <br/>
            <ul>
        {
        for $manuscript in $sources-manuscripts
        let $name :=
            $manuscript//mei:fileDesc/mei:titleStmt/mei:title[@type='uniform' and @xml:lang='de']/mei:titlePart[@type='main']/normalize-space(text())
        
        let $id := $manuscript/@xml:id/normalize-space(data(.))
        order by $name ascending
        return
            <li>
                {$name} (<a href="sources/manuscript/{$id}">{$id}</a>)<br/>
            </li>
        }
            </ul>
            <br/>
            <h2>Sammelquellen</h2>
            <br/>
            <ul>
        {
        for $manuscript in $sources-manuscripts-Coll
        let $name := $manuscript//mei:fileDesc/mei:titleStmt/mei:title[@type="uniform" and @xml:lang='de']/normalize-space(text())
        
        let $id := $manuscript/@xml:id/normalize-space(data(.))
        order by $name ascending
        return
            <li>
                {$name} (<a href="sources/manuscript/{$id}">{$id}</a>)<br/>
            </li>
        }
            </ul>
        </div>
        <div class="tab-pane fade" id="prints" >
         <br/>
            <ul>
        {
        for $print in $sources-prints
        let $name :=
            if(exists($print//mei:term[@type='source' and @subtype='special' and contains(./text(),'Sammelquelle')]))
            then($print//mei:fileDesc/mei:titleStmt/mei:title[@type="uniform" and @xml:lang='de']/mei:titlePart[@type='main']/normalize-space(text()))
            else($print//mei:fileDesc/mei:titleStmt/mei:title[@type='uniform' and @xml:lang='de']/mei:titlePart[@type='main']/normalize-space(text()))
        
        let $id := $print/@xml:id/normalize-space(data(.))
        order by $name ascending
        return
            <li>
                {$name} (<a href="sources/print/{$id}">{$id}</a>)<br/>
            </li>
        }
            </ul>
        </div>
        <div class="tab-pane fade" id="songs" >
        <br/>
            <ul>
        {
        for $song in $sources-songs
        let $name :=
            if(exists($song//mei:term[@type='source' and @subtype='special' and contains(./text(),'Sammelquelle')]))
            then($song//mei:fileDesc/mei:titleStmt/mei:title[@type="uniform" and @xml:lang='de']/mei:titlePart[@type='main']/normalize-space(text()))
            else($song//mei:fileDesc/mei:titleStmt/mei:title[@type='uniform' and @xml:lang='de']/mei:titlePart[@type='main']/normalize-space(text()))
        
        let $id := $song/@xml:id/normalize-space(data(.))
        order by $name ascending
        return
        (
            if($song//mei:term[@type='source']/contains(.,'Manuskript') = true()) 
            then(
            <li>
                {$name} (<a href="sources/manuscript/{$id}">{$id}</a>)<br/>
            </li>
            )
            else if($song//mei:term[@type='source']/contains(.,'Druck') = true())
            then(
            <li>
                {$name} ({if($song//mei:manifestation[contains(@class,'#ms')])then(<a href="sources/manuscript/{$id}">{$id}</a>)else if($song//mei:manifestation[contains(@class,'#pr')])then(<a href="sources/print/{$id}">{$id}</a>)else('error')})<br/>
            </li>
            )
            else()
            )
        }
            </ul>
        </div>
        <div class="tab-pane fade" id="choirs" >
         <br/>
            <ul>
        {
        for $choir in $sources-choirs
        let $name :=
            if(exists($choir//mei:term[@type='source' and @subtype='special' and contains(./text(),'Sammelquelle')]))
            then($choir//mei:fileDesc/mei:titleStmt/mei:title[@type="uniform" and @xml:lang='de']/normalize-space(data(.)))
            else($choir//mei:sourceDesc/mei:source[1]/mei:titleStmt/mei:title[@type="main"]/normalize-space(data(.)))
        
        let $id := $choir/@xml:id/normalize-space(data(.))
        order by $name ascending
        return
            <li>
                {$name} ({if($choir//mei:manifestation[contains(@class,'#ms')])then(<a href="sources/manuscript/{$id}">{$id}</a>)else if($choir//mei:manifestation[contains(@class,'#pr')])then(<a href="sources/print/{$id}">{$id}</a>)else('error')})<br/>
            </li>
        }
            </ul>
        </div>
         <div class="tab-pane fade" id="todos" >
         <br/>
            <ul>
        {
        for $source in $sourcesToDo
        let $name :=
            if(exists($source//mei:term[contains(@type,'source') and contains(@type,'collection')]))
            then($source//mei:fileDesc/mei:titleStmt/mei:title[@type="uniform" and @xml:lang='de']/text())
            else($source//mei:sourceDesc/mei:source[1]/mei:titleStmt/mei:title[@type="main"]/normalize-space(data(.)))
        
        let $id := $source/@xml:id/normalize-space(data(.))
        order by $name ascending
        return
            <li>
                {$name} ({if($source//mei:manifestation[contains(@class,'#ms')])then(<a href="sources/manuscript/{$id}">{$id}</a>)else if($source//mei:manifestation[contains(@class,'#pr')])then(<a href="sources/print/{$id}">{$id}</a>)else('error')})<br/>
            </li>
        }
            </ul>
        </div>
   </div>
        
        
    </div>
)
};

declare function app:sources-manuscript($node as node(), $model as map(*)) {

let $id := request:get-parameter("source-id", "Fehler")
let $manuscript := collection("/db/apps/baudiSources/data/music")//mei:mei[@xml:id=$id]
let $fileURI := document-uri($manuscript/root())
let $name := $manuscript//mei:manifestation/mei:titleStmt/mei:title[@type="main"]/normalize-space(data(.))
let $manuscriptOrig := concat('../../../../../baudi-images/music/',$manuscript/@xml:id)
let $manuscriptOrigBLB := "https://digital.blb-karlsruhe.de/blbihd/image/view/"
let $manuscriptDigitalisatBLB := "https://digital.blb-karlsruhe.de/blbihd/content/pageview/"

return
(
    <div class="container">
        <a href="../../registrySources.html">&#8592; zum Quellenverzeichnis</a>
        <div class="page-header">
            <h1>{$name}</h1>
            <h5>{$id}</h5>
        </div>
        <div class="row">
       {if(exists($manuscript//mei:facsimile/mei:surface))
       then(
        <div class="col">
                {
                if(doc-available(concat($manuscriptOrig,'_001','.jpeg')))
                then(<img src="{concat($manuscriptOrig,'_001','.jpeg')}" width="400"/>)
                else if($manuscript//mei:graphic[@targettype="blb-vlid"])
                then(<a href="{concat($manuscriptDigitalisatBLB,$manuscript//mei:facsimile/mei:surface[@n="1"]/mei:graphic/@target)}" target="_blank"><img src="{concat($manuscriptOrigBLB,$manuscript//mei:facsimile/mei:surface[@n="1"]/mei:graphic/@target)}" width="400"/></a>)
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
            <p/>
                {transform:transform($manuscript,doc("/db/apps/baudiApp/resources/xslt/metadataSourceManuscript.xsl"), ())}
            <p/>
            <div class="card">
                <div class="card-body">
                    {if(exists($manuscript//mei:work/mei:incip/mei:score))
                    then('Incipit soon',<span onload="myIncipit({concat('http://localhost:8080/exist/rest',$fileURI)})"> </span>,<div id="output-verovio"/>)
                    else(<b>No incipit available</b>)}
                </div>
            </div>
        </div>
        <div class="tab-pane fade" id="detail">
            <p/>
            {transform:transform($manuscript,doc("/db/apps/baudiApp/resources/xslt/metadataSourceManuscriptDetailed.xsl"), ())}
        </div>
        <div class="tab-pane fade" id="lyrics">
            <p/>
                {transform:transform($manuscript,doc("/db/apps/baudiApp/resources/xslt/contentLyrics.xsl"), ())}
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

declare function app:sources-print($node as node(), $model as map(*)) {

let $id := request:get-parameter("source-id", "Fehler")
let $print := collection("/db/apps/baudiSources/data/music")/mei:mei[@xml:id=$id]
let $name := $print//mei:title[@type="main"]/normalize-space(data(.))
let $printOrig := "PFAD"

return
(
    <div class="container">
        <a href="../../registrySources.html">&#8592; zum Quellenverzeichnis</a>
        <div class="page-header">
            <h1>{$name}</h1>
        </div>
        <div class="row">
      <div class="col">
                <strong>Link zum Digitalisat der Quelle </strong>
                <img src="{concat($printOrig,'_001','.jpeg')}" width="400"/>
                </div>  
    <div class="col">
    <strong>Quellenbeschreibung</strong>
        {transform:transform($print,doc("/db/apps/baudiApp/resources/xslt/print.xsl"), ())}
    </div>
    </div>
    </div>
)
};

declare function app:aboutProject($node as node(), $model as map(*)) {

let $text := doc("/db/apps/baudiTexts/data/portal/aboutProject.xml")/tei:TEI


return
(
    <div class="container">
        {transform:transform($text,doc("/db/apps/baudiApp/resources/xslt/portal.xsl"), ())}
    </div>
)
};

declare function app:aboutBaumann($node as node(), $model as map(*)) {

let $text := doc("/db/apps/baudiTexts/data/portal/aboutBaumann.xml")/tei:TEI

return
(
    <div class="container">
    <!--<p>TEST: {$baudiVersions:versions}</p>-->
        {transform:transform($text,doc("/db/apps/baudiApp/resources/xslt/portal.xsl"), ())}
    </div>
)
};

declare function app:statusBearb($node as node(), $model as map(*)) {

let $object := doc("/db/contents/baudi/register/bearbStatusBLB-HS.xml")

return
(
<div class="container">
<div class="page-header">
<a href="../index.html">&#8592; zurück zur Startseite</a>
            <h1>Status der Bestandsbearbeitung (HS: D-KA, D-KAsa)</h1>
        </div>
        <div class="container">
        {transform:transform($object,doc("/db/apps/baudiApp/resources/xslt/rismxml2html.xsl"), ())}
    </div>
    </div>
)
};

declare function app:indexPage($node as node(), $model as map(*)) {

let $text := doc('/db/apps/baudiTexts/data/portal/index.xml')

return
(
    <div class="container">
        {transform:transform($text,doc("/db/apps/baudiApp/resources/xslt/portal.xsl"), ())}
    </div>
)
};

declare function app:zeitungsarchiv($node as node(), $model as map(*)) {

let $text := doc('/db/contents/baudi/register/zeitungsarchiv.xml')

return
(
<div class="container">
        <a href="../index.html">← zurück zur Startseite</a>
        <div class="page-header">
            <h1>Zeitungarchiv</h1>
        </div>
    <div class="container">
        {transform:transform($text,doc("/db/apps/baudiApp/resources/xslt/zeitungsarchiv.xsl"), ())}
    </div>
    </div>
)
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
    
    let $works := collection("/db/apps/baudiWorks/data")//mei:work
    let $genres := distinct-values(collection("/db/apps/baudiWorks/data")//mei:work//mei:term[@type="genre"]/@subtype)
    let $dict := collection("/db/apps/baudiResources/data")
    let $content := <div class="container">
    <br/>
         <ul class="nav nav-pills" role="tablist">
            <li class="nav-item"><a class="nav-link active" data-toggle="tab" href="#main">Alle Werke ({count($works)})</a></li>
            {for $genre in $genres
                let $genreDict := $dict//tei:name[@type=$genre]/text()
                let $workCount := count($works//mei:term[@type='genre' and @subtype = $genre])
                let $nav-item := <li class="nav-item"><a class="nav-link" data-toggle="tab" href="{concat('#',$genre)}">{$genreDict} ({$workCount})</a></li>
                return
                    $nav-item
             }
    </ul>
    <!-- Tab panels -->
    <div class="tab-content">
        <div class="tab-pane fade show active" id="main" >
        <br/>
        {
        for $work in $works
        let $title := $work//mei:title[@type='uniform']/mei:titlePart[@type='main']/normalize-space(text()[1])
        let $titleSort := $work//mei:title[@type='uniform']/mei:titlePart[@type='mainSort']/normalize-space(text()[1])
        let $titleSub := $work//mei:title[@type='uniform']/mei:titlePart[@type='subordinate']/normalize-space(text()[1])
        let $numberOpus := $work//mei:title[@type='uniform']/mei:titlePart[@type='number' and @auth='opus']
        let $id := $work/@xml:id/normalize-space(data(.))
        let $perfMedium := $work//mei:title[@type='uniform']/mei:titlePart[@type='perfmedium']/normalize-space(text()[1])
        let $composer := $work//mei:composer
        let $lyricist := $work//mei:lyricist
        let $termWorkGroup := $work//mei:term[@type='workGroup']/@subtype/string()
        let $termGenre := $work//mei:term[@type='genre']/@subtype/string()
        
        let $order := lower-case(if($titleSort)then($titleSort)else($title))
        
        order by $order
        return
            <div class="card bg-light mb-3" style="max-width: 75%;">
                <div class="card-body">
                  <h5 class="card-title">{$title}</h5>
                  <h6>{$titleSub}</h6>
                  <h6 class="card-subtitle mb-2 text-muted">{$perfMedium}</h6>
                  <p class="card-text">{if($composer)then('Komponist: ',$composer,<br/>)else()}{if($lyricist)then('Textdichter: ',$lyricist)else()}</p>
                  <a href="work/{$id}" class="card-link">{$id}</a>
                  <hr/>
                  <p>Tags: {$termWorkGroup}&#160;<button type="button" class="btn btn-outline-secondary">{$termGenre}</button></p>
                </div>
            </div>
        }
        </div>
        {for $genre in $genres
           return
            <div class="tab-pane fade" id="{$genre}">
                <br/>
                {
                for $work in $works//mei:term[@type="genre" and @subtype=$genre]/ancestor::mei:work
                    let $title := $work//mei:title[@type='uniform']/mei:titlePart[@type='main']/normalize-space(text()[1])
                    let $numberOpus := $work//mei:title[@type='uniform']/mei:titlePart[@type='number' and @auth='opus']
                    let $id := $work/@xml:id/normalize-space(data(.))
                    let $perfMedium := $work//mei:title[@type='uniform']/mei:titlePart[@type='perfmedium']/normalize-space(text()[1])
                    let $composer := $work//mei:composer
                    let $lyricist := $work//mei:lyricist
                    order by $title ascending
                    return
                        <div class="card bg-light mb-3" style="max-width: 75%;">
                            <div class="card-body">
                              <h5 class="card-title">{if($numberOpus)then(concat($title,', Op. ',$numberOpus))else($title)}</h5>
                              <h6 class="card-subtitle mb-2 text-muted">{$perfMedium}</h6>
                              <p class="card-text">
                                {if($composer)then('Komponist: ',$composer,<br/>)else()}
                                {if($lyricist)then('Textdichter: ',$lyricist)else()}
                              </p>
                              <a href="work/{$id}" class="card-link">{$id}</a>
                            </div>
                        </div>
                }
            </div>
             }
        </div>
   </div>
       
       return
        $content
       };
       
declare function app:work($node as node(), $model as map(*)) {

let $id := request:get-parameter("work-id", "Fehler")
let $work := collection("/db/apps/baudiWorks/data")/mei:work[@xml:id=$id]
let $title := $work//mei:title[@type='uniform']/mei:titlePart[@type='main']/normalize-space(text()[1])
let $numberOpus := $work//mei:title[@type='uniform']/mei:titlePart[@type='number' and @auth='opus']

return
(
    <div class="container">
        <br/>
        <div class="page-header">
            <h1>{if($numberOpus)then(concat($title,', Op. ',$numberOpus))else($title)}</h1>
            <h5>ID: {$id}</h5>
        </div>
        <br/>
    <div class="col">
        {transform:transform($work,doc("/db/apps/baudiApp/resources/xslt/metadataWork.xsl"), ())}
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
