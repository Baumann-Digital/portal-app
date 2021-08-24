xquery version "3.1";

module namespace baudiPersons="http://baumann-digital.de/ns/baudiPersons";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace request="http://exist-db.org/xquery/request";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";

import module namespace i18n="http://exist-db.org/xquery/i18n" at "/db/apps/baudiApp/modules/i18n.xql";


declare function baudiPersons:getNameUniform($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $personName := if($person/tei:persName[@role='uniform'])
                       then($person/tei:persName[@role='uniform']//text() => string-join(' '))
                       else($person/tei:persName[1]//text() => string-join(' '))
    return
        $personName
};

declare function baudiPersons:getTitle($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $personTitle := $person//tei:addName[matches(@type,"title")]/text()
    return
        $personTitle
};

declare function baudiPersons:getFornames($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $forenames := $person//tei:forename => string-join(' ')
    return
        $forenames
};

declare function baudiPersons:getNameLink($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $nameLink := $person//tei:nameLink/text()
    return
        $nameLink
};

declare function baudiPersons:getSurnames($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $surnames := $person//tei:surname => string-join(' ')
    return
        $surnames
};

declare function baudiPersons:getGenName($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $genName := $person//tei:genName/text()
    return
        $genName
};

declare function baudiPersons:getEpithet($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $epithet := $person//tei:addName[matches(@type,"^epithet")]/text()
    return
        $epithet
};

declare function baudiPersons:getRoleName($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $roleNames := $person//tei:roleName/text() => string-join(' | ')
    return
        $roleNames
};

declare function baudiPersons:getNickName($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $nickName := $person//tei:addName[matches(@type,"^nick")] => string-join(' ')
    return
        $nickName
};

declare function baudiPersons:getNameUnspec($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $nameUnspec := $person//tei:name[matches(@type,'^unspecified')]/text()
    return
        $nameUnspec
};

declare function baudiPersons:getAffiliations($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $hasAffiliation := if($person//tei:affiliation[. != '']) then(true()) else(false())
    let $affiliations := <ul>{for $affiliation in $person//tei:affiliation[. != '']
                                return
                                    <li>{$affiliation/text()}</li>
                              }</ul>
    return
        if($hasAffiliation)
        then($affiliations)
        else()
};
