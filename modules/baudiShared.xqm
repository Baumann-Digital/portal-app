xquery version "3.1";

module namespace baudiShared="http://baumann-digital.de/ns/baudiShared";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace console="http://exist-db.org/xquery/console";

import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";
import module namespace baudiPersons="http://baumann-digital.de/ns/baudiPersons" at "/db/apps/baudiApp/modules/baudiPersons.xqm";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="https://exist-db.org/xquery/config" at "/db/apps/baudiApp/modules/config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace range="http://exist-db.org/xquery/range";
import module namespace transform="http://exist-db.org/xquery/transform";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";

import module namespace i18n="http://exist-db.org/xquery/i18n" at "i18n.xql";

declare variable $baudiShared:xsltTEI as document-node() := doc('xmldb:exist:///db/apps/baudiApp/resources/xslt/tei/html5/html5.xsl');
declare variable $baudiShared:xsltFormattingText as document-node() := doc('xmldb:exist:///db/apps/baudiApp/resources/xslt/formattingText.xsl');
declare variable $baudiShared:xsltFormattingTextWithoutLinks as document-node() := doc('xmldb:exist:///db/apps/baudiApp/resources/xslt/formattingTextWithoutLinks.xsl');
(:~ 
: MRP Main Nav lang switch
:
: @param $node the processed node
: @param $model the model
:
: @return html <li/>-Elements
:)

declare function baudiShared:get-lang() as xs:string? {
  let $lang := if(string-length(request:get-parameter("lang", "")) gt 0) then
      (: use http parameter lang as selected language :)
      request:get-parameter("lang", "")
  else
     if(string-length(request:get-cookie-value("forceLang")) gt 0) then
       request:get-cookie-value("forceLang")
     else
       baudiShared:get-browser-lang()
  (: limit to de and en; en default :)
  return if($lang != "en" and $lang != "de") then "en" else $lang
};


(:~ 
: i18n text from a TEI file
:
: @param $doc the docuemtent node to process
:
: @return html
:)

declare function baudiShared:getI18nText($doc) {
    let $lang := baudiShared:get-lang()
    let $log := console:log(concat('lang: ', $lang))
    return
            if(exists($doc//tei:text[@xml:lang]))
            then(
                if($doc//tei:text[@xml:lang = $lang])
                then(transform:transform($doc//tei:text[@xml:lang = $lang], $baudiShared:xsltFormattingTextWithoutLinks, ()))
                else(transform:transform($doc//tei:text[1], $baudiShared:xsltFormattingTextWithoutLinks, ()))
                )
            
            (: Is there tei:div[@xml:lang] ?:)
            else if (exists($doc//tei:text/tei:body/tei:div[@xml:lang]))
            then(
                if($doc//tei:text/tei:body/tei:div[@xml:lang = $lang])
                then(transform:transform($doc//tei:text/tei:body/tei:div[@xml:lang = $lang], $baudiShared:xsltFormattingTextWithoutLinks, ()))
                else(transform:transform($doc//tei:text[1], $baudiShared:xsltFormattingTextWithoutLinks, ()))
                )
                
                (: There is no other tei:div than 'de' :)
            else (transform:transform($doc//tei:text[1], $baudiShared:xsltFormattingTextWithoutLinks, ()))
};


declare function baudiShared:translate($content) {
    let $content := element i18n:text {
                        attribute key {$content}
                    }
    return
        i18n:process($content, '', '/db/apps/baudiApp/resources/lang', 'en')
};


(: DATES:)


(:~
: Return month names from month numbers in dates
:
: @param $monthNo the number of month (1…12)
: @param $lang the requested language
:
: @return a month name.
:
:)

declare function baudiShared:monthName($monthNo as xs:integer) as xs:string {
    let $lang := baudiShared:get-lang()

    return
    if ($lang = 'de')
    then (
        ('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember')[$monthNo]
    )
    else (
        ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')[$monthNo]
    )
};


(:~
: Format our custom dates
:
: @param $dateVal the string with custom date to be analyzed, picture 0000-00-00
:
: @return a date string.
:
:)

declare function baudiShared:customDate($dateVal as xs:string) as xs:string {
    let $dateValT := tokenize($dateVal, '-')
    let $hasDay := if (number($dateValT[3]) > 0)
                    then (number($dateValT[3]))
                    else ()
    let $hasMonth := if (number($dateValT[2]) > 0)
                        then (number($dateValT[2]))
                        else ()
    let $hasYear := if (number($dateValT[1]) > 0)
                    then (number($dateValT[1]))
                    else ()
    return
        if ($hasDay and $hasMonth and $hasYear)
        then (xs:date($dateVal))
        else if ($hasMonth and $hasYear)
        then (
            concat(
                baudiShared:monthName($dateValT[2]),
                ' ',
                $dateValT[1],
                ' [',
                baudiShared:translate('mriCat.entry.postalObject.date.day'),
                ' ',
                baudiShared:translate('unknown'),
                ']'
            )
        )
        else if ($hasDay and $hasMonth)
        then (
            concat(
                format-number($dateValT[3], '0'),
                '.&#160;',
                baudiShared:monthName($dateValT[2]),
                ', [',
                baudiShared:translate('mriCat.entry.postalObject.date.year'),
                ' ',
                baudiShared:translate('unknown'),
                ']'
            )
        )
        else if ($hasMonth)
        then (
            concat(
                baudiShared:monthName($dateValT[2]),
                ', [',
                baudiShared:translate('mriCat.entry.postalObject.date.day'),
                '/',
                baudiShared:translate('mriCat.entry.postalObject.date.year'),
                ' ',
                baudiShared:translate('unknown'),
                ']'
            )
        )
        else if ($hasDay)
        then (
            concat(
                format-number($dateValT[3], '0'),
                '., [',
                baudiShared:translate('mriCat.entry.postalObject.date.month'),
                '/',
                baudiShared:translate('mriCat.entry.postalObject.date.year'),
                ' ',
                baudiShared:translate('unknown'),
                ']'
            )
        )
        else if ($hasYear)
        then (
            concat(
                $dateValT[1],
                ', [',
                baudiShared:translate('mriCat.entry.postalObject.date.day'),
                '/',
                baudiShared:translate('mriCat.entry.postalObject.date.month'),
                ' ',
                baudiShared:translate('unknown'),
                ']'
            )
        )
        else (baudiShared:translate('mriCat.entry.postalObject.date.type.undated'))

};


(:~
: Format xs:date with respect to language and desired form
:
: @param $date the date
: @param $form the form (e.g. full, short, …)
: @param $lang the requested language
:
: @return a i18n date string.
:
: ToDo: find the right type of $date for baudiShared:getBirthDeathDates
:
:)

declare function baudiShared:formatDate($date, $form as xs:string, $lang as xs:string) as xs:string {
    let $date := if (functx:atomic-type($date) = 'xs:date')
                    then ($date)
                    else ($date/@when/string())
    return
        if ($form = 'full')
        then (format-date($date, "[D1o]&#160;[MNn]&#160;[Y]", $lang, (), ()))
        else (format-date($date, "[D].[M].[Y]", $lang, (), ()))
};


(:~
: Shorten (if possible) and format two xs:date with respect to language and desired form
:
: @param $dateFrom the start date
: @param $dateTo the end date
: @param $form the form (e.g. full, short, …)
: @param $lang the requested language
:
: @return a i18n date string.
:
: ToDo: find the right type of $date for baudiShared:getBirthDeathDates
:
:)

declare function baudiShared:shortenAndFormatDates($dateFrom, $dateTo, $form as xs:string, $lang as xs:string) as xs:string {
    if ($form = 'full' and (month-from-date($dateFrom) = month-from-date($dateTo)) and (year-from-date($dateFrom) = year-from-date($dateTo)))
    then (
        concat(
            day-from-date($dateFrom), '.–', day-from-date($dateTo), '. ',
            format-date($dateFrom, "[MNn] [Y]", $lang, (), ())
        )
    )
    else if ($form = 'full' and (year-from-date($dateFrom) = year-from-date($dateTo)))
    then (
        concat(
            day-from-date($dateFrom), '. ', format-date($dateFrom, "[MNn]", $lang, (), ()),
            '–',
            day-from-date($dateTo), '. ', format-date($dateTo, "[MNn] ", $lang, (), ()),
            year-from-date($dateFrom)
        )
    )
    else if ($form = 'full')
    then (
        concat(
            format-date($dateFrom, "[D]. [MNn] [Y]", $lang, (), ()),
            '–',
            format-date($dateTo, "[D]. [MNn] [Y]", $lang, (), ())
        )
    )
    else (
        concat(
            format-date($dateFrom, "[D].[M].[Y]", $lang, (), ()),
            '–',
            format-date($dateTo, "[D].[M].[Y]", $lang, (), ())
        )
    )
};


declare function baudiShared:getBirthDeathDates($dates, $lang) {
    let $date := if ($dates/tei:date)
                        then (baudiShared:formatDate($dates/tei:date, 'full', $lang))
                        else ()
    let $datePlace := if ($dates/tei:placeName/text())
                        then (normalize-space($dates/tei:placeName/text()))
                        else ()
    return
        if ($date and $datePlace)
        then (concat($date, ', ', $datePlace))
        else if ($date)
        then ($date)
        else if ($date = '' and $datePlace = '')
        then (baudiShared:translate('unknown'))
        else if ($datePlace)
        then (concat($datePlace, ', ', baudiShared:translate('dateUnknown')))
        else (baudiShared:translate('unknown'))
};

declare function baudiShared:any-equals-any($args as xs:string*, $searchStrings as xs:string*) as xs:boolean {
    some $arg in $args
    satisfies
        some $searchString in $searchStrings
        satisfies
            $arg = $searchString
};

declare function baudiShared:queryKey() {
  functx:substring-before-if-contains(concat(request:get-uri(), request:get-query-string()), "firstRecord")
};


declare %templates:wrap function baudiShared:readCache($node as node(), $model as map(*), $cacheName as xs:string) {
    doc(concat('xmldb:exist:///db/apps/mriCat/caches/', $cacheName, '.xml'))/*
};


(: Patrick integrates https://jaketrent.com/post/xquery-browser-language-detection/ :)

declare function baudiShared:get-browser-lang() as xs:string? {
  let $header := request:get-header("Accept-Language")
  return if (fn:exists($header)) then
    baudiShared:get-top-supported-lang(baudiShared:get-browser-langs($header), ("de", "en"))
  else
    ()
};

(:declare function baudiShared:get-lang() as xs:string? {
  let $lang := if(string-length(request:get-parameter("lang", "")) gt 0) then
      (\: use http parameter lang as selected language :\)
      request:get-parameter("lang", "")
  else
     if(string-length(request:get-cookie-value("forceLang")) gt 0) then
       request:get-cookie-value("forceLang")
     else
       baudiShared:get-browser-lang()
  (\: limit to de and en; en default :\)
  return if($lang != "en" and $lang != "de") then "en" else $lang
};:)

declare function baudiShared:get-top-supported-lang($ordered-langs as xs:string*, $translations as xs:string*) as xs:string? {
  if (fn:empty($ordered-langs)) then
    ()
  else
    let $lang := $ordered-langs[1]
    return if ($lang = $translations) then
      $lang
    else
      baudiShared:get-top-supported-lang(fn:subsequence($ordered-langs, 2), $translations)
};

declare function baudiShared:get-browser-langs($header as xs:string) as xs:string* {
  let $langs :=
    for $entry in fn:tokenize(baudiShared:parse-header($header), ",")
    let $data := fn:tokenize($entry, "q=")
    let $quality := $data[2]
    order by
      if (fn:exists($quality) and fn:string-length($quality) gt 0) then
  xs:float($quality)
      else
  xs:float(1.0)
      descending
    return $data[1]
  return $langs
};

declare function baudiShared:parse-header($header as xs:string) as xs:string {
  let $regex := "(([a-z]{1,8})(-[a-z]{1,8})?)\s*(;\s*q\s*=\s*(1|0\.[0-9]+))?"
  let $flags := "i"
  let $format := "$2q=$5"
  return fn:replace(fn:lower-case($header), $regex, $format)
};


declare function baudiShared:getSelectedLanguage($node as node()*,$selectedLang as xs:string) {
    baudiShared:get-lang()
};


declare function baudiShared:stringJoinAll($node as node()) {
    string-join($node/string(),' | ')
};

(:~
 : Function to get the name of a person by ID
 : 
 : @param $param possible values are 'full', 'short'
 : @param $linking if the value is 'yes' the function tries to create a link to the authority file
 : @return If linking than node(), else string
 :)

declare function baudiShared:getPersName($personID, $param as xs:string, $linking as xs:string?) {
let $person :=$app:collectionPersons/id($personID)
let $linkToRecord := string-join(($app:dbRoot, $personID), '/')
let $persName := if($person/tei:persName[@role='uniform'])
                  then($person/tei:persName[@role='uniform'])
                  else($person/tei:persName[1])
let $nameForename := if($persName//tei:forename[@type='used'])
                     then($persName//tei:forename[not(@type='altWriting') and @type='used'])
                     else($persName//tei:forename[1])
let $nameForenames := $persName//tei:forename[not(@type='altWriting')]
                      => string-join(' ')
let $nameForenameAlt := concat('(auch ',$persName//tei:forename[@type='altWriting'], ')')
let $nameNameLink := $persName//tei:nameLink/text()
let $nameSurname := $persName//tei:surname[not(@type='altWriting')]
                     => string-join(' ')
let $nameSurnameAlt := concat('(auch ',$persName//tei:surname[@type='altWriting'], ')')
let $nameGenName := $persName//tei:genName/text()
let $nameAddNameTitle := $persName//tei:addName[matches(@type,"title")]/text()
let $nameAddNameEpitet := $persName//tei:addName[matches(@type,"^epithet")]/text()

let $nameRoleName := $persName//tei:roleName[1]/text()
let $nameAddNameNick := $persName//tei:addName[matches(@type,"^nick")]
                         => string-join(' ')
let $affiliation := $persName//tei:affiliation/text()
let $nameUnspecified := $persName//tei:name[matches(@type,'^unspecified')]/text()
let $nameUnspec := if($affiliation and $nameUnspecified)
                   then(concat($nameUnspecified, ' (',$affiliation,')'))
                   else($nameUnspecified)
let $nameStrings := if($param = "full")
                    then(
                            if($nameAddNameTitle or $nameForenames or $nameForenameAlt or $nameAddNameEpitet or $nameNameLink or $nameSurname or $nameSurnameAlt or $nameGenName or $nameUnspec)
                            then(string-join(($nameAddNameTitle, $nameForenames, $nameForenameAlt, $nameAddNameEpitet, $nameNameLink, $nameSurname, $nameSurnameAlt, $nameUnspec, if($nameGenName) then(concat(' (',$nameGenName,')')) else()), ' '))
                            else if($nameRoleName)
                            then($nameRoleName)
                            else if($nameAddNameNick)
                            then($nameAddNameNick)
                            else(baudiShared:translate('baudi.registry.persons.unknown'))
                        )
                    else if($param = 'short')
                    then(if($nameForename or $nameNameLink or $nameSurname)
                         then(string-join(($nameForename, $nameNameLink, $nameSurname, if($nameGenName) then(concat(' (',$nameGenName,')')) else()), ' '))
                         else if($persName/text() !='')
                          then(string-join($persName/text(), ' '))
                         else(baudiShared:translate('baudi.registry.persons.unknown')))
                    else if($param = 'reversed')
                    then(
                        if($nameSurname)
                        then(concat($nameSurname,
                                   if($nameGenName) then(concat(' (',$nameGenName,')')) else(),
                                   if($nameAddNameTitle or $nameForename or $nameNameLink)
                                   then(concat(', ', string-join(($nameAddNameTitle, $nameForename, $nameNameLink), ' ')))
                                   else()))
                        else if($nameForename)
                        then(string-join(($nameForename, $nameNameLink, $nameUnspec), ' '),
                             if($nameGenName) then(concat(' (',$nameGenName,')')) else())
                        else if($nameRoleName)
                        then($nameRoleName)
                        else if($nameAddNameNick)
                        then($nameAddNameNick)
                        else(baudiShared:translate('baudi.registry.persons.unknown'))
                    )
                    
                    else (baudiShared:translate('baudi.registry.persons.unknown'))
                    
    return
        if($linking = 'yes')
        then(<a href="{$linkToRecord}">{$nameStrings}</a>)
        else($nameStrings)
};


declare function baudiShared:getPersonaLinked($id as xs:string) {
    
    let $personRecord := $app:collectionPersons[@xml:id = $id]
    let $personLink := concat($app:dbRoot, '/person/', $id)
    let $forename := $personRecord/tei:persName/tei:forename
    let $surname :=  $personRecord/tei:persName/tei:surname
    let $name := if($surname and $forename)
                 then(string-join(($forename, $surname),' '))
                 else if($surname and not($forename))
                 then(string-join($surname,' '))
                 else if (not($surname) and $forename)
                 then(string-join($forename, ' '))
                 else()
    
    return
        if($name)
        then(<a href="{$personLink}">{$name}</a>)
        else (baudiShared:translate('baudi.registry.persons.unknown'))
};

declare function baudiShared:getOrgNameFull($org as node()) {

    let $name := string-join($org/tei:orgName[1]/text(), ' ')
    
    return
        $name
};

declare function baudiShared:getOrgNameFullLinked($org as node()) {

    let $orgID := $org/@xml:id
    let $orgUri := concat($app:dbRoot, '/institution/', $orgID)
    let $name := baudiShared:getOrgNameFull($org)
    
    return
        <a href="{$orgUri}">{$name}</a>
};

declare function baudiShared:getCorpNameFullLinked($corpName as node()) {

    let $corpID := $corpName/@auth/string()
    let $corpUri := concat($app:dbRoot, '/institution/', $corpID)
    let $nameFound := $app:collectionInstitutions[matches(@xml:id, $corpID)]//tei:orgName[1]/text()
    let $name := if($nameFound) then($nameFound) else($corpName)
    
    return
        <a href="{$corpUri}">{$name}</a>
};

(:declare function baudiShared:getName($key as xs:string, $param as xs:string){

    let $person :=$app:collectionPersons[range:field-eq("person-id", $key)]
    let $institution := $app:collectionInstitutions[range:field-eq("institution-id", $key)]
    let $nameForename := $person//tei:forename[matches(@type,"^used")][1]/text()[1]
    let $nameNameLink := $person//tei:nameLink[1]/text()[1]
    let $nameSurname := $person//tei:surname[matches(@type,"^used")][1]/text()[1]
    let $nameGenName := $person//tei:genName/text()
    let $nameAddNameTitle := $person//tei:addName[matches(@type,"^title")][1]/text()[1]
    let $nameAddNameEpitet := $person//tei:addName[matches(@type,"^epithet")][1]/text()[1]
    let $pseudonym := if ($person//tei:forename[matches(@type,'^pseudonym')] or $person//tei:surname[matches(@type,'^pseudonym')])
                      then (concat($person//tei:forename[matches(@type,'^pseudonym')], ' ', $person//tei:surname[matches(@type,'^pseudonym')]))
                      else ()
    let $nameRoleName := $person//tei:roleName[1]/text()[1]
    let $nameAddNameNick := $person//tei:addName[matches(@type,"^nick")][1]/text()[1]
    let $affiliation := $person//tei:affiliation[1]/text()
    let $nameUnspecified := $person//tei:name[matches(@type,'^unspecified')][1]/text()[1]
    let $nameUnspec := if($affiliation and $nameUnspecified)
                       then(concat($nameUnspecified, ' (',$affiliation,')'))
                       else($nameUnspecified)
    let $institutionName := $institution//tei:org/tei:orgName/text()
    
    let $name := if ($person)
                 then(
                      if($person and $param = 'full')
                      then(
                            if(not($nameForename) and not($nameNameLink) and not($nameUnspec))
                            then($nameRoleName)
                            else(string-join(($nameAddNameTitle, $nameForename, $nameAddNameEpitet, $nameNameLink, $nameSurname, $nameUnspec, $nameGenName), ' '))
                          )
                          
                      else if($person and $param = 'short')
                      then(
                           string-join(($nameForename, $nameNameLink, $nameSurname, $nameUnspec, $nameGenName), ' ')
                          )
                          
                      else if($person and $param = 'reversed')
                      then(
                            if($nameSurname)
                            then(
                                concat($nameSurname, ', ',string-join(($nameForename, $nameNameLink), ' '),
                                if($nameGenName) then(concat(' (',$nameGenName,')')) else())
                                )
                            else (
                                    if(not($nameForename) and not($nameNameLink) and not($nameUnspec))
                                    then($nameRoleName)
                                    else(
                                           string-join(($nameForename, $nameNameLink, $nameUnspec), ' '),
                                           if($nameGenName) then(concat(' (',$nameGenName,')')) else()
                                        )
                            )
                           )
                           
                      else ('[NoPersonFound]')
                     )
                 else if($institution)
                 then($institutionName)
                 else('[NoInstitutionFound]')
    return
       $name
};:)

declare function baudiShared:linkAll($node as node()){
    transform:transform($node,doc('/db/apps/baudiApp/resources/xslt/linking.xsl'),())
};

declare function baudiShared:checkGenderforLangValues($persID){
    let $person := $app:collectionPersons[@xml:id=$persID]
    let $gender := $person//tei:sex/string(@type)
    return
        if($gender = 'male')
        then()
        else if ($gender = 'female')
        then('.female')
        else('')
};


declare function baudiShared:getReferences($id) {
    let $collectionReference := ($app:collectionPersons[matches(.//@key,$id)],
                                 $app:collectionInstitutions[matches(.//@key,$id)],
                                 $app:collectionPeriodicals[matches(.//@key,$id)],
                                 $app:collectionLoci[matches(.//@key,$id)],
                                 $app:collectionDocuments[matches(.//@key,$id)],
                                 $app:collectionSourcesMusic[matches(.//@auth,$id)],
                                 $app:collectionWorks[matches(.//@auth,$id)])
    
    let $entryGroups := for $doc in $collectionReference
                          let $docRoot := $doc/root()/node()
                          let $docID := $docRoot/@xml:id
                          let $docIDStart := substring($docID,1,8)
                          let $docInfo := if(starts-with($docRoot/@xml:id,'baudi-07-'))
                                          then(baudiShared:translate('baudi.registry.persons.references.sources.text'))
                                          else if (starts-with($docRoot/@xml:id,'baudi-02-'))
                                          then (baudiShared:translate('baudi.registry.persons.references.works'))
                                          else if(starts-with($docRoot/@xml:id,'baudi-04-'))
                                          then(baudiShared:translate('baudi.registry.persons.references.persons'))
                                          else if(starts-with($docRoot/@xml:id,'baudi-05-'))
                                          then(baudiShared:translate('baudi.registry.persons.references.institutions'))
                                          else if(starts-with($docRoot/@xml:id,'baudi-06-'))
                                          then(baudiShared:translate('baudi.registry.persons.references.loci'))
                                          else if(starts-with($docRoot/@xml:id,'baudi-09-'))
                                          then(baudiShared:translate('baudi.registry.persons.references.periodicals'))
                                          else if(starts-with($docRoot/@xml:id,'baudi-01-'))
                                          then(baudiShared:translate('baudi.registry.persons.references.sources.music'))
                                          else(baudiShared:translate('baudi.registry.persons.references.other'))
                          let $entryOrder := if(starts-with($docRoot/@xml:id,'baudi-02-'))
                                          then('002')
                                          else if (starts-with($docRoot/@xml:id,'baudi-01-'))
                                          then ('001')
                                          else if(starts-with($docRoot/@xml:id,'baudi-07-'))
                                          then('003')
                                          else if(starts-with($docRoot/@xml:id,'baudi-04-'))
                                          then('004')
                                          else if(starts-with($docRoot/@xml:id,'baudi-05-'))
                                          then('005')
                                          else if(starts-with($docRoot/@xml:id,'baudi-06-'))
                                          then('006')
                                          else('007')
                          let $correspActionSent := $docRoot//tei:correspAction[@type="sent"]
                          let $correspActionReceived := $docRoot//tei:correspAction[@type="received"]
                          let $correspSentTurned := baudiShared:getPersName($correspActionSent/tei:persName/@key, 'short','yes')
                          let $correspReceivedTurned := baudiShared:getPersName($correspActionReceived/tei:persName/@key, 'short','yes')
                          let $docDate := if($correspActionSent)
                                          then('DATUM')
                                          else(<br/>)
                          let $workSortValue := 'sort'
                          let $docTitle := if($correspActionSent)
                                           then($correspSentTurned,<br/>,'an ',$correspReceivedTurned)
                                           else if(starts-with($docRoot/@xml:id,'baudi-02-')) 
                                           then($docRoot//mei:workList/mei:work[1]/mei:title[1]/string())
                                           else if($docRoot/name()='TEI')
                                           then($docRoot//tei:titleStmt/tei:title/string())
                                           else('noTitle')
                          let $entry := <div class="row RegisterEntry" xmlns="http://www.w3.org/1999/xhtml">
                                          <div class="col-3" dateToSort="{$docDate}" workSort="{$workSortValue}">
                                              {$docInfo}
                                              {if($docDate and starts-with($docRoot/@xml:id,'A'))
                                              then(' vom ','DATUM')
                                              else()}
                                         </div>
                                         <div class="col" docTitle="{normalize-space($docTitle[1])}">{$docTitle}</div>
                                         <div class="col-2"><a href="{$docID}">{string($docID)}</a></div>
                                       </div>
                          group by $docIDStart
                          return
                              (<div xmlns="http://www.w3.org/1999/xhtml" groupName="{$docIDStart}" order="{$entryOrder}">{for $each in $entry
                                    order by if($each/div/@dateToSort !='')
                                             then($each/div/@dateToSort)
                                             else if($each/div/@workSort)
                                             then($each/div/@workSort)
                                             else ($each/div/@docTitle)
                                    return
                                        $each}</div>)
   let $entryGroupsShow := for $groups in $entryGroups
                              let $groupName := $groups/@groupName
                              let $order := $groups/@order
                              let $registerSortEntryLabel := switch ($groupName/string())
                                                               case 'baudi-01-' return baudiShared:translate('baudi.registry.persons.references.sources.music')
                                                               case 'baudi-02-' return baudiShared:translate('baudi.registry.persons.references.works')
                                                               case 'baudi-04-' return baudiShared:translate('baudi.registry.persons.references.persons')
                                                               case 'baudi-05-' return baudiShared:translate('baudi.registry.persons.references.institutions')
                                                               case 'baudi-06-' return baudiShared:translate('baudi.registry.persons.references.loci')
                                                               case 'baudi-07-' return baudiShared:translate('baudi.registry.persons.references.sources.text')
                                                               case 'baudi-09-' return baudiShared:translate('baudi.registry.persons.references.periodicals')
                                                               default return baudiShared:translate('baudi.registry.persons.references.other')
                                order by $order
                                return
                                 <div class="RegisterSortBox" xmlns="http://www.w3.org/1999/xhtml">
                                          <div class="RegisterSortEntry">{$registerSortEntryLabel}</div>
                                          {for $group in $groups
                                              return
                                                  $group}
                                 </div>
   return
    $entryGroupsShow
};