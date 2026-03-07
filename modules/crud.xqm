xquery version "3.1";

(:~
 : CRUD (Create, Read, Update, Delete) functions for BauDi
 : Provides dynamic data collection access instead of static variables
 : Based on WeGA-WebApp pattern
 :)
module namespace crud="http://baumann-digital.de/ns/crud";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace edirom="http://www.edirom.de/ns/1.3";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace config="https://exist-db.org/xquery/config" at "config.xqm";

(:~
 : Get a document by ID
 : 
 : @param $docID the ID of the document
 : @return the document node of the resource, or empty sequence if not found
 :)
declare function crud:doc($docID as xs:string?) as document-node()? {
    if($docID) then
        let $collectionPath := crud:get-collection-path-for-id($docID)
        let $docURL := $collectionPath || '/' || $docID || '.xml'
        return 
            if(doc-available($docURL)) then doc($docURL)
            else ()
    else ()
};

(:~
 : Returns documents from a data collection
 : 
 : @param $collectionName the name of the collection (relative to data-collection-path)
 : @return document-node()*
 :)
declare function crud:data-collection($collectionName as xs:string) as document-node()* {
    let $collectionPath := $config:data-collection-path || '/' || $collectionName
    let $collectionPathExists := xmldb:collection-available($collectionPath) and ($collectionPath ne '')
    return 
        if ($collectionPathExists) then collection($collectionPath)
        else ()
};

(:~
 : Get collection path for a given collection name
 : 
 : @param $collectionName the name of the collection (relative to data-collection-path)
 : @return xs:string the full collection path
 :)
declare function crud:get-collection-path($collectionName as xs:string) as xs:string {
    $config:data-collection-path || '/' || $collectionName
};

(:~
 : Helper function to determine collection path based on ID pattern
 : This is a simplified version - extend as needed
 : 
 : @param $docID the document ID
 : @return xs:string the collection path, or empty if not determinable
 :)
declare %private function crud:get-collection-path-for-id($docID as xs:string) as xs:string? {
    (: Add ID pattern matching here based on your ID conventions :)
    (: For now, return empty - extend this based on your needs :)
    ()
};
