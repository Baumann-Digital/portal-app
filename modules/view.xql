(:~
 : This is the main XQuery which will (by default) be called by controller.xql
 : to process any URI ending with ".html". It receives the HTML from
 : the controller and passes it to the templating system.
 :)
xquery version "3.0";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace i18n="http://exist-db.org/xquery/i18n-templates" at "/db/apps/baudiApp/modules/i18n-templates.xql";
(: 
 : The following modules provide functions which will be called by the 
 : templating.
 :)
import module namespace config="https://exist-db.org/xquery/config" at "/db/apps/baudiApp/modules/config.xqm";
import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace baudiShared = "http://baumann-digital.de/ns/baudiShared" at "/db/apps/baudiApp/modules/baudiShared.xqm";
import module namespace baudiWork = "http://baumann-digital.de/ns/baudiWork" at "/db/apps/baudiApp/modules/baudiWork.xqm";
import module namespace baudiSource = "http://baumann-digital.de/ns/baudiSource" at "/db/apps/baudiApp/modules/baudiSource.xqm";
import module namespace baudiLocus = "http://baumann-digital.de/ns/baudiLocus" at "/db/apps/baudiApp/modules/baudiLocus.xqm";
import module namespace baudiPersons="http://baumann-digital.de/ns/baudiPersons" at "/db/apps/baudiApp/modules/baudiPersons.xqm";


declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

(:let $log-in := xmldb:login("/db", "Baumann", "Ludwig"):)
let $config := map {
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR : true()
}
(:
 : We have to provide a lookup function to templates:apply to help it
 : find functions in the imported application modules. The templates
 : module cannot see the application modules, but the inline function
 : below does see them.
 :)
let $lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
(:
 : The HTML is passed in the request from the controller.
 : Run it through the templating system and return the result.
 :)
let $content := request:get-data()

return
    templates:apply($content, $lookup, (), $config)
    