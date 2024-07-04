xquery version "3.0";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="https://exist-db.org/xquery/config";
declare namespace templates="http://exist-db.org/xquery/html-templating";

declare namespace repo="http://exist-db.org/xquery/repo";

declare namespace expath="http://expath.org/ns/pkg";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace request="http://exist-db.org/xquery/request";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root as xs:string := 
    let $rawPath := replace(system:get-module-load-path(), '/null/', '//')
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else if (contains($rawPath, "/xmlrpc/")) then
                substring-after($rawPath, "/xmlrpc")
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:catalogues-collection-path as xs:string := $config:app-root || '/catalogues';
declare variable $config:options-file-path as xs:string := $config:catalogues-collection-path || '/options.xml';
declare variable $config:options-file as document-node() := doc($config:options-file-path);
(: provide quick access to the options by pushing them to a map object :)
declare variable $config:options as map(xs:string, xs:string*) := map:merge($config:options-file//entry ! map:entry(./string(@xml:id), normalize-space(.)));
declare variable $config:data-collection-path as xs:string := config:get-option('dataCollectionPath');
declare variable $config:isDevelopment as xs:boolean := $config:options-file/id('environment') eq 'development';

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;
declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

(:~
 :  Returns the requested option value from an option file given by the variable $wega:optionsFile
 :  This function is a simple wrapper for accessing the options map object   
 :  
 : @author Peter Stadler
 : @param $key the key to look for in the options file
 : @return xs:string the option value as string identified by the key otherwise the empty sequence
 :)
declare function config:get-option($key as xs:string?) as xs:string? {
    let $result := $config:options?($key)
    return
        if($result) then $result
        else ()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};
