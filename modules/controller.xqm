xquery version "3.1";

module namespace controller="http://baumann-digital.de/ns/controller";

import module namespace i18n = "http://exist-db.org/xquery/i18n" at "modules/i18n.xql";

import module namespace functx = "http://www.functx.com"; 
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

(:~
 : Creates the forwarding, the parameters and the error handler for given objects
 : @param $controller pass the $exist:controller variable here
 : @param $resource pass the $exist:resource variable here
 : @param $objectType pass the object type here as string() (e.g., 'document','work') 
:)
declare function controller:dispatch-object($controller, $resource, $objectType) as node() {
<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward
        url="{$controller}/templates/view{functx:capitalize-first($objectType)}.html">
        <add-parameter
            name="{$objectType}-id"
            value="{$resource}"/>
    </forward>
    <view>
        <forward
            url="{$controller}/modules/view.xql">
            <add-parameter
                name="{$objectType}-id"
                value="{$resource}"/>
        </forward>
    </view>
    <error-handler>
        <forward
            url="{$controller}/templates/error-page.html"
            method="get"/>
        <forward
            url="{$controller}/modules/view.xql"/>
    </error-handler>
</dispatch>
};