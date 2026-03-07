xquery version "3.1";

(:~
 : XQuery module for querying external service providers
 : (e.g., Digilib, GND, VIAF, BLB Karlsruhe)
 :
 : @author Baumann Digital Portal Team
 : @version 1.0
 :)
module namespace er="http://baumann-digital.de/portal-app/ns/external-requests";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace config="https://exist-db.org/xquery/config" at "config.xqm";
import module namespace functx="http://www.functx.com";

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
