xquery version "3.1";

(:~
 : XQuery module for querying external service providers
 : (e.g., Digilib, GND, VIAF, BLB Karlsruhe, Wikidata)
 :
 : @author Baumann Digital Portal Team
 : @version 1.0
 :)
module namespace er="http://baumann-digital.de/portal-app/ns/external-requests";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace gndo="https://d-nb.info/standards/elementset/gnd#";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace schema="http://schema.org/";

import module namespace config="https://exist-db.org/xquery/config" at "config.xqm";
import module namespace functx="http://www.functx.com";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

(: Cache configuration :)
declare variable $er:cache-collection := '/db/system/cache/external-requests';
declare variable $er:cache-expiry-days := 7;

(:~
 : Initialize cache collection if it doesn't exist
 :)
declare %private function er:init-cache() as xs:boolean {
    if (not(xmldb:collection-available($er:cache-collection))) then
        try {
            xmldb:create-collection('/db/system/cache', 'external-requests'),
            true()
        } catch * {
            false()
        }
    else true()
};

(:~
 : Check if cached document is still valid
 : 
 : @param $cacheDoc the cached document
 : @return true if cache is valid, false otherwise
 :)
declare %private function er:is-cache-valid($cacheDoc as document-node()?) as xs:boolean {
    if (not($cacheDoc)) then false()
    else
        let $cacheDate := $cacheDoc/*/er:cached/@date cast as xs:dateTime
        let $now := current-dateTime()
        let $expiryDate := $cacheDate + xs:dayTimeDuration('P' || $er:cache-expiry-days || 'D')
        return $expiryDate > $now
};

(:~
 : Store data in cache
 : 
 : @param $cacheKey unique identifier for the cached resource
 : @param $data the data to cache
 : @return empty sequence
 :)
declare %private function er:store-in-cache($cacheKey as xs:string, $data as item()*) as empty-sequence() {
    let $init := er:init-cache()
    let $cacheFileName := encode-for-uri($cacheKey) || '.xml'
    let $cacheWrapper := 
        <er:cache xmlns:er="http://baumann-digital.de/portal-app/ns/external-requests">
            <er:cached date="{current-dateTime()}"/>
            <er:data>{$data}</er:data>
        </er:cache>
    return
        if ($init and $data) then
            try {
                xmldb:store($er:cache-collection, $cacheFileName, $cacheWrapper),
                ()
            } catch * {
                ()
            }
        else ()
};

(:~
 : Get data from cache if valid
 : 
 : @param $cacheKey unique identifier for the cached resource
 : @return the cached data or empty sequence
 :)
declare %private function er:get-from-cache($cacheKey as xs:string) as item()* {
    let $init := er:init-cache()
    let $cacheFileName := encode-for-uri($cacheKey) || '.xml'
    let $cachePath := $er:cache-collection || '/' || $cacheFileName
    let $cacheDoc := 
        if ($init and doc-available($cachePath)) 
        then doc($cachePath)
        else ()
    
    return
        if (er:is-cache-valid($cacheDoc)) then
            $cacheDoc/*/er:data/*
        else ()
};

(:~
 : Get a linked or plain norm data identifier (GND, VIAF)
 : 
 : @param $object the TEI/MEI node containing idno elements
 : @param $identifierType the type of identifier ('gnd' or 'viaf')
 : @param $linking whether to return a linked HTML anchor element
 : @return linked anchor element or plain string identifier
 :)
declare function er:get-norm-data-link($object as node(), $identifierType as xs:string, $linking as xs:boolean) as item()? {
    let $idno := $object//tei:idno[@type=$identifierType]/text()
    let $idnoLinked := if($identifierType = 'gnd')
        then(<a href="https://d-nb.info/gnd/{$idno}" target="_blank">{$idno}</a>)
        else if($identifierType = 'viaf')
        then(<a href="http://viaf.org/viaf/{$idno}" target="_blank">{$idno}</a>)
        else()
    return
        if($linking = true())
        then($idnoLinked)
        else($idno)
};

(:~
 : Construct a Digilib URL for a given resource
 : 
 : @param $sourceChiffre the source type identifier (e.g., '01', '07')
 : @param $resourcePath the path to the resource
 : @param $params optional URL parameters (e.g., '?dw=500')
 : @return the complete Digilib URL
 :)
declare function er:get-digilib-url($sourceChiffre as xs:string, $resourcePath as xs:string, $params as xs:string?) as xs:string {
    let $digilibBasePath := config:get-option('digilibPath')
    let $fullPath := concat($digilibBasePath, '/BauDi/', $sourceChiffre, '/', $resourcePath)
    return
        if($params)
        then(concat($fullPath, $params))
        else($fullPath)
};

(:~
 : Get Digilib URL for a letter page facsimile
 : 
 : @param $letter the letter document
 : @param $page the page number
 : @return the Digilib URL for the facsimile
 :)
declare function er:get-letter-facsimile-url($letter as node(), $page as xs:string) as xs:string {
    let $facPath := $letter//tei:div[@type='page' and @n=$page]/@facs
    return concat(config:get-option('digilibPath'), '/BauDi/07/', $facPath)
};

(:~
 : Get Digilib URL for a letter page with thumbnail parameters
 : 
 : @param $id the letter ID
 : @param $page the page number
 : @return the Digilib URL with dw=500 parameter
 :)
declare function er:get-letter-thumbnail-url($id as xs:string, $page as xs:string) as xs:string {
    concat(config:get-option('digilibPath'), '/BauDi/07/', $id, '-', $page, '?dw=500')
};

(:~
 : Get Digilib URL for a source document by ID
 : 
 : @param $sourceId the source document xml:id
 : @return the Digilib base URL for the source
 :)
declare function er:get-source-url($sourceId as xs:string) as xs:string {
    concat(config:get-option('digilibPath'), $sourceId)
};

(:~
 : Fetch GND data from d-nb.info as RDF/XML with timeout and error handling
 : 
 : @param $gndId the GND identifier (without prefix)
 : @return the RDF/XML document or empty sequence on error
 :)
declare %private function er:fetch-gnd-data-raw($gndId as xs:string) as document-node()? {
    let $url := 'https://d-nb.info/gnd/' || $gndId || '/about/lds.rdf'
    return
        try {
            let $doc := doc($url)
            return
                if ($doc) then $doc
                else ()
        } catch * {
            ()
        }
};

(:~
 : Fetch GND data with caching
 : 
 : @param $gndId the GND identifier (without prefix)
 : @return the RDF/XML document or empty sequence on error
 :)
declare function er:fetch-gnd-data($gndId as xs:string) as document-node()? {
    let $cacheKey := 'gnd-' || $gndId
    let $cached := er:get-from-cache($cacheKey)
    
    return
        if ($cached) then
            $cached
        else
            let $freshData := er:fetch-gnd-data-raw($gndId)
            return (
                er:store-in-cache($cacheKey, $freshData),
                $freshData
            )[last()]
};

(:~
 : Fetch VIAF data from viaf.org as RDF/XML with timeout and error handling
 : 
 : @param $viafId the VIAF identifier
 : @return the RDF/XML document or empty sequence on error
 :)
declare %private function er:fetch-viaf-data-raw($viafId as xs:string) as document-node()? {
    let $url := 'https://viaf.org/viaf/' || $viafId || '/rdf.xml'
    return
        try {
            let $doc := doc($url)
            return
                if ($doc) then $doc
                else ()
        } catch * {
            ()
        }
};

(:~
 : Fetch VIAF data with caching
 : 
 : @param $viafId the VIAF identifier
 : @return the RDF/XML document or empty sequence on error
 :)
declare function er:fetch-viaf-data($viafId as xs:string) as document-node()? {
    let $cacheKey := 'viaf-' || $viafId
    let $cached := er:get-from-cache($cacheKey)
    
    return
        if ($cached) then
            $cached
        else
            let $freshData := er:fetch-viaf-data-raw($viafId)
            return (
                er:store-in-cache($cacheKey, $freshData),
                $freshData
            )[last()]
};

(:~
 : Fetch Wikidata SPARQL results via GND identifier
 : 
 : @param $gndId the GND identifier
 : @return SPARQL XML results or empty sequence
 :)
declare %private function er:fetch-wikidata-by-gnd-raw($gndId as xs:string) as document-node()? {
    let $sparql-query := encode-for-uri(
        'SELECT ?item ?itemLabel ?viaf ?gnd ?image ?articleDE ?articleEN WHERE { ' ||
        '?item wdt:P227 "' || $gndId || '". ' ||
        'OPTIONAL { ?item wdt:P214 ?viaf. } ' ||
        'OPTIONAL { ?item wdt:P18 ?image. } ' ||
        'OPTIONAL { ?articleDE schema:about ?item ; schema:isPartOf <https://de.wikipedia.org/> ; schema:name ?articleDE . } ' ||
        'OPTIONAL { ?articleEN schema:about ?item ; schema:isPartOf <https://en.wikipedia.org/> ; schema:name ?articleEN . } ' ||
        'SERVICE wikibase:label { bd:serviceParam wikibase:language "de,en". } ' ||
        '}'
    )
    let $url := 'https://query.wikidata.org/sparql?format=xml&amp;query=' || $sparql-query
    return
        try {
            let $doc := doc($url)
            return
                if ($doc) then $doc
                else ()
        } catch * {
            ()
        }
};

(:~
 : Fetch Wikidata data with caching
 : 
 : @param $gndId the GND identifier
 : @return SPARQL XML results or empty sequence
 :)
declare function er:fetch-wikidata-by-gnd($gndId as xs:string) as document-node()? {
    let $cacheKey := 'wikidata-gnd-' || $gndId
    let $cached := er:get-from-cache($cacheKey)
    
    return
        if ($cached) then
            $cached
        else
            let $freshData := er:fetch-wikidata-by-gnd-raw($gndId)
            return (
                er:store-in-cache($cacheKey, $freshData),
                $freshData
            )[last()]
};

(:~
 : Parse VIAF data and extract relevant information
 : 
 : @param $viafDoc the VIAF RDF/XML document
 : @return a map with structured VIAF information
 :)
declare function er:parse-viaf-data($viafDoc as document-node()?) as map(*)? {
    if (not($viafDoc)) then ()
    else
        let $desc := $viafDoc//rdf:Description[1]
        return map {
            'viafId': $desc/@rdf:about/string(),
            'names': $desc//*[local-name()='mainHeadingEl']//text()/string(),
            'sources': distinct-values($desc//*[local-name()='sources']/*/@rdf:resource/string())
        }
};

(:~
 : Parse Wikidata SPARQL results
 : 
 : @param $wikidataDoc the Wikidata SPARQL XML document
 : @return a map with structured Wikidata information
 :)
declare function er:parse-wikidata($wikidataDoc as document-node()?) as map(*)? {
    if (not($wikidataDoc)) then ()
    else
        let $result := $wikidataDoc//sr:result[1]
        return map {
            'item': $result/sr:binding[@name='item']/sr:uri/string(),
            'label': $result/sr:binding[@name='itemLabel']/sr:literal/string(),
            'viaf': $result/sr:binding[@name='viaf']/sr:literal/string(),
            'image': $result/sr:binding[@name='image']/sr:uri/string(),
            'articleDE': $result/sr:binding[@name='articleDE']/sr:literal/string(),
            'articleEN': $result/sr:binding[@name='articleEN']/sr:literal/string()
        }
};

(:~
 : Parse GND data and extract relevant information
 : 
 : @param $gndDoc the GND RDF/XML document
 : @return a map with structured GND information
 :)
declare function er:parse-gnd-data($gndDoc as document-node()?) as map(*)? {
    if (not($gndDoc)) then ()
    else
        let $desc := $gndDoc//rdf:Description[1]
        return map {
            'preferredName': $desc/gndo:preferredNameForThePerson/string(),
            'preferredNameEntity': $desc/gndo:preferredNameForTheCorporateBody/string(),
            'variantNames': $desc/gndo:variantNameForThePerson/string(),
            'dateOfBirth': $desc/gndo:dateOfBirth/string(),
            'dateOfDeath': $desc/gndo:dateOfDeath/string(),
            'placeOfBirth': $desc/gndo:placeOfBirth/*/gndo:preferredNameForThePlaceOrGeographicName/string(),
            'placeOfDeath': $desc/gndo:placeOfDeath/*/gndo:preferredNameForThePlaceOrGeographicName/string(),
            'professions': $desc/gndo:professionOrOccupation/*/gndo:preferredNameForTheSubjectHeading/string(),
            'gender': $desc/gndo:gender/@rdf:resource/string(),
            'biographicalInfo': $desc/gndo:biographicalOrHistoricalInformation/string(),
            'sameAs': $desc/gndo:sameAs/@rdf:resource/string()
        }
};

(:~
 : Get comprehensive authority data combining GND, VIAF, and Wikidata
 : 
 : @param $gndId the GND identifier
 : @param $viafId optional VIAF identifier
 : @return a combined map with all available information
 :)
declare function er:get-combined-authority-data($gndId as xs:string?, $viafId as xs:string?) as map(*) {
    let $gndData := 
        if ($gndId and $gndId != '') then
            er:parse-gnd-data(er:fetch-gnd-data($gndId))
        else ()
    
    let $viafData :=
        if ($viafId and $viafId != '') then
            er:parse-viaf-data(er:fetch-viaf-data($viafId))
        else ()
    
    let $wikidataData :=
        if ($gndId and $gndId != '') then
            er:parse-wikidata(er:fetch-wikidata-by-gnd($gndId))
        else ()
    
    return map:merge((
        if (exists($gndData)) then map { 'gnd': $gndData } else (),
        if (exists($viafData)) then map { 'viaf': $viafData } else (),
        if (exists($wikidataData)) then map { 'wikidata': $wikidataData } else ()
    ))
};

(:~
 : Get formatted authority information for display (enhanced version)
 : 
 : @param $gndId the GND identifier
 : @param $viafId optional VIAF identifier
 : @return HTML div with authority information
 :)
declare function er:get-authority-info($gndId as xs:string?, $viafId as xs:string?) as element(div)? {
    let $combinedData := er:get-combined-authority-data($gndId, $viafId)
    let $gndData := $combinedData?gnd
    let $wikidataData := $combinedData?wikidata
    
    return
        if (exists($gndData) or exists($wikidataData)) then
            <div class="authority-info" xmlns="http://www.w3.org/1999/xhtml">
                <h4>Normdaten-Informationen</h4>
                
                {(: Preferred Name from GND :)}
                {
                    let $name := ($gndData?preferredName, $gndData?preferredNameEntity)[1]
                    return
                        if ($name) then
                            <div class="row">
                                <div class="col-sm-3"><strong>Bevorzugter Name (GND):</strong></div>
                                <div class="col-sm-9">{$name}</div>
                            </div>
                        else ()
                }
                
                {(: Variant Names :)}
                {
                    if (exists($gndData?variantNames) and $gndData?variantNames != '') then
                        <div class="row">
                            <div class="col-sm-3"><strong>Variante Namen:</strong></div>
                            <div class="col-sm-9">{string-join($gndData?variantNames, '; ')}</div>
                        </div>
                    else ()
                }
                
                {(: Life Dates :)}
                {
                    if ($gndData?dateOfBirth or $gndData?dateOfDeath) then
                        <div class="row">
                            <div class="col-sm-3"><strong>Lebensdaten:</strong></div>
                            <div class="col-sm-9">
                                {$gndData?dateOfBirth}
                                {if ($gndData?dateOfBirth and $gndData?dateOfDeath) then ' – ' else ()}
                                {$gndData?dateOfDeath}
                            </div>
                        </div>
                    else ()
                }
                
                {(: Places :)}
                {
                    if ($gndData?placeOfBirth or $gndData?placeOfDeath) then
                        <div class="row">
                            <div class="col-sm-3"><strong>Lebensstationen:</strong></div>
                            <div class="col-sm-9">
                                {if ($gndData?placeOfBirth) then concat('* ', $gndData?placeOfBirth) else ()}
                                {if ($gndData?placeOfBirth and $gndData?placeOfDeath) then ', ' else ()}
                                {if ($gndData?placeOfDeath) then concat('† ', $gndData?placeOfDeath) else ()}
                            </div>
                        </div>
                    else ()
                }
                
                {(: Professions :)}
                {
                    if (exists($gndData?professions) and $gndData?professions != '') then
                        <div class="row">
                            <div class="col-sm-3"><strong>Berufe:</strong></div>
                            <div class="col-sm-9">{string-join($gndData?professions, ', ')}</div>
                        </div>
                    else ()
                }
                
                {(: Biographical Info :)}
                {
                    if (exists($gndData?biographicalInfo) and $gndData?biographicalInfo != '') then
                        <div class="row">
                            <div class="col-sm-3"><strong>Biographische Info:</strong></div>
                            <div class="col-sm-9">{string-join($gndData?biographicalInfo, ' ')}</div>
                        </div>
                    else ()
                }
                
                {(: Wikidata Image :)}
                {
                    if ($wikidataData?image) then
                        <div class="row">
                            <div class="col-sm-3"><strong>Bild (Wikidata):</strong></div>
                            <div class="col-sm-9">
                                <img src="{$wikidataData?image}" alt="Wikidata" style="max-width: 200px; height: auto;"/>
                            </div>
                        </div>
                    else ()
                }
                
                {(: Wikipedia Links from Wikidata :)}
                {
                    if ($wikidataData?articleDE or $wikidataData?articleEN) then
                        <div class="row">
                            <div class="col-sm-3"><strong>Wikipedia:</strong></div>
                            <div class="col-sm-9">
                                {
                                    if ($wikidataData?articleDE) then
                                        <a href="https://de.wikipedia.org/wiki/{encode-for-uri($wikidataData?articleDE)}" target="_blank">
                                            Deutscher Artikel
                                        </a>
                                    else ()
                                }
                                {if ($wikidataData?articleDE and $wikidataData?articleEN) then ' | ' else ()}
                                {
                                    if ($wikidataData?articleEN) then
                                        <a href="https://en.wikipedia.org/wiki/{encode-for-uri($wikidataData?articleEN)}" target="_blank">
                                            English Article
                                        </a>
                                    else ()
                                }
                            </div>
                        </div>
                    else
                        (: Fallback to GND sameAs links :)
                        let $wikiLinks := $gndData?sameAs[contains(., 'wikipedia.org')]
                        return
                            if (exists($wikiLinks) and $wikiLinks != '') then
                                <div class="row">
                                    <div class="col-sm-3"><strong>Wikipedia:</strong></div>
                                    <div class="col-sm-9">
                                    {
                                        for $link in $wikiLinks
                                        return <a href="{$link}" target="_blank">{$link}</a>
                                    }
                                    </div>
                                </div>
                            else ()
                }
                
                {(: Wikidata Link :)}
                {
                    if ($wikidataData?item) then
                        <div class="row">
                            <div class="col-sm-3"><strong>Wikidata:</strong></div>
                            <div class="col-sm-9">
                                <a href="{$wikidataData?item}" target="_blank">
                                    {$wikidataData?item}
                                </a>
                            </div>
                        </div>
                    else ()
                }
                
                {(: VIAF Link :)}
                {
                    let $viaf := ($wikidataData?viaf, $viafId)[1]
                    return
                        if ($viaf) then
                            <div class="row">
                                <div class="col-sm-3"><strong>VIAF:</strong></div>
                                <div class="col-sm-9">
                                    <a href="https://viaf.org/viaf/{$viaf}" target="_blank">
                                        {$viaf}
                                    </a>
                                </div>
                            </div>
                        else ()
                }
            </div>
        else ()
};

(:~
 : Get formatted GND information for display (backward compatible wrapper)
 : 
 : @param $gndId the GND identifier
 : @return HTML div with GND information
 :)
declare function er:get-gnd-info($gndId as xs:string) as element(div)? {
    er:get-authority-info($gndId, ())
};

(:~
 : Get facsimile preview for a source
 : 
 : @param $id the document ID
 : @param $collectionSourcesMusic the music sources collection
 : @param $collectionDocuments the documents collection
 : @return HTML div with facsimile preview or "no graphic" message
 :)
declare function er:get-facsimile-preview(
    $id as xs:string,
    $collectionSourcesMusic as node()*,
    $collectionDocuments as node()*
) as element(div) {
    let $sourceChiffre := subsequence(tokenize($id, '-'), 2, 1)
    
    let $source := if($sourceChiffre = '01')
                   then($collectionSourcesMusic[@xml:id= $id])
                   else if($sourceChiffre = '07')
                   then($collectionDocuments[@xml:id= $id])
                   else()
    
    let $digilibBasicPath := concat(config:get-option('digilibPath'), '/BauDi/', $sourceChiffre, '/')
    
    let $facsimileTarget := if($sourceChiffre = '01')
                            then($collectionSourcesMusic[@xml:id= $id]//mei:facsimile[1]/mei:surface[if(@n='1')then(@n='1')else(1)][1]/mei:graphic/@target)
                            else if($sourceChiffre = '07')
                            then($collectionDocuments[@xml:id= $id]//tei:div[@type='page' and @n='1']/@facs)
                            else()
    
    let $facsimileTargetPath := if(starts-with($facsimileTarget, 'https://digital.blb-karlsruhe.de'))
                                then(functx:substring-after-last($facsimileTarget,'/'))
                                else($facsimileTarget)
    let $digilibFacPath := concat($digilibBasicPath, $facsimileTargetPath)
    
    let $BLBfacPath := concat(config:get-option('BLBfacPath'), $facsimileTargetPath)
    let $BLBfacPathImage := concat(config:get-option('BLBfacPathImage'), $facsimileTargetPath)
    
    let $graphicLocal := if(starts-with($facsimileTargetPath, 'baudi-'))
                         then(<img src="{concat($digilibFacPath, '?dw=500')}" class="img-thumbnail" width="400"/>)
                         else()
    let $graphicBLB := if($source//mei:graphic[@targettype="blb-vlid"] or starts-with($facsimileTarget, 'https://digital.blb-karlsruhe.de'))
                       then(<a href="{$BLBfacPath}" target="_blank" data-toggle="tooltip" data-placement="top" title="Zum vollständigen Digitalisat unter digital.blb-karlsruhe.de">
                                <img class="img-thumbnail" src="{$BLBfacPathImage}" width="400"/>
                            </a>)
                       else()
    let $graphicBLBLabel := <div xmlns="http://www.w3.org/1999/xhtml">
                                <br/>
                                Quelle: Badische Landesbibliothek Karlsruhe
                            </div>
    
    return
        <div class="col-md-4 col-lg-4" xmlns="http://www.w3.org/1999/xhtml">
        {
            if($graphicLocal) 
            then $graphicLocal
            else if($graphicBLB) 
            then ($graphicBLB, $graphicBLBLabel)
            else 'kein Digitalisat verfügbar'
        }
        </div>
};
