xquery version "3.1";

module namespace shared="http://baumann-digital.de/portal-app/ns/shared";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace console="http://exist-db.org/xquery/console";

import module namespace app="http://baumann-digital.de/ns/templates" at "app.xql";
import module namespace persons="http://baumann-digital.de/portal-app/ns/persons" at "persons.xqm";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="https://exist-db.org/xquery/config" at "config.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace range="http://exist-db.org/xquery/range";
import module namespace transform="http://exist-db.org/xquery/transform";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";
import module namespace er="http://baumann-digital.de/portal-app/ns/external-requests" at "external-requests.xqm";

import module namespace i18n="http://exist-db.org/xquery/i18n" at "i18n.xql";

declare variable $shared:xsltFormattingText as document-node() := doc($config:app-root || '/resources/xslt/formattingText.xsl');
declare variable $shared:xsltFormattingTextWithoutLinks as document-node() := doc($config:app-root || '/resources/xslt/formattingTextWithoutLinks.xsl');
(:~ 
: MRP Main Nav lang switch
:
: @param $node the processed node
: @param $model the model
:
: @return html <li/>-Elements
:)

declare function shared:get-lang() as xs:string? {
  let $lang := if(string-length(request:get-parameter("lang", "")) gt 0) then
      (: use http parameter lang as selected language :)
      request:get-parameter("lang", "")
  else
     if(string-length(request:get-cookie-value("forceLang")) gt 0) then
       request:get-cookie-value("forceLang")
     else
       shared:get-browser-lang()
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

declare function shared:getI18nText($doc as node()) {
    let $lang := shared:get-lang()
    let $log := console:log(concat('lang: ', $lang))
    return
            if (exists($doc//tei:text/tei:body/tei:div[@xml:lang]))
            then(
                if($doc//tei:text/tei:body/tei:div[@xml:lang = $lang])
                then($doc//tei:text/tei:body/tei:div[@xml:lang = $lang])
                else($doc//tei:text/tei:body/tei:div)
                )
            else($doc//tei:text/tei:body/tei:div)
};


declare function shared:translate($content) {
    let $content := element i18n:text {
                        attribute key {$content}
                    }
    return
        i18n:process($content, '', $config:app-root || '/catalogues', 'en')
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

declare function shared:monthName($monthNo as xs:integer) as xs:string {
    let $lang := shared:get-lang()

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

declare function shared:customDate($dateVal as xs:string) as xs:string {
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
                shared:monthName($dateValT[2]),
                ' ',
                $dateValT[1],
                ' [',
                shared:translate('mriCat.entry.postalObject.date.day'),
                ' ',
                shared:translate('unknown'),
                ']'
            )
        )
        else if ($hasDay and $hasMonth)
        then (
            concat(
                format-number($dateValT[3], '0'),
                '.&#160;',
                shared:monthName($dateValT[2]),
                ', [',
                shared:translate('mriCat.entry.postalObject.date.year'),
                ' ',
                shared:translate('unknown'),
                ']'
            )
        )
        else if ($hasMonth)
        then (
            concat(
                shared:monthName($dateValT[2]),
                ', [',
                shared:translate('mriCat.entry.postalObject.date.day'),
                '/',
                shared:translate('mriCat.entry.postalObject.date.year'),
                ' ',
                shared:translate('unknown'),
                ']'
            )
        )
        else if ($hasDay)
        then (
            concat(
                format-number($dateValT[3], '0'),
                '., [',
                shared:translate('mriCat.entry.postalObject.date.month'),
                '/',
                shared:translate('mriCat.entry.postalObject.date.year'),
                ' ',
                shared:translate('unknown'),
                ']'
            )
        )
        else if ($hasYear)
        then (
            concat(
                $dateValT[1],
                ', [',
                shared:translate('mriCat.entry.postalObject.date.day'),
                '/',
                shared:translate('mriCat.entry.postalObject.date.month'),
                ' ',
                shared:translate('unknown'),
                ']'
            )
        )
        else (shared:translate('mriCat.entry.postalObject.date.type.undated'))

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
: ToDo: find the right type of $date for shared:getBirthDeathDates
:
:)

declare function shared:formatDate($dateRaw, $formation as xs:string, $lang as xs:string) as xs:string {
    let $form := if ($formation = 'full')
                 then ('[D].&#160;[MNn,*-3].&#160;[Y]')
                 else if ($formation = 'short')
                 then()
                 else ('[D].[M].[Y]')
    let $date :=  if(string-length($dateRaw)=10 and not(contains($dateRaw,'-00')) and not(contains($dateRaw,'0000-')))
                  then(format-date(xs:date($dateRaw),$form,$lang,(),()))
                  else if($dateRaw =('0000','0000-00','0000-00-00'))
                  then('[' || shared:translate('undated') || ']')
                  else if(string-length($dateRaw)=7 and not(contains($dateRaw,'00')))
                  then (concat(upper-case(substring(format-date(xs:date(concat($dateRaw,'-01')),'[Mn,*-3]. [Y]',$lang,(),()),1,1)),substring(format-date(xs:date(concat($dateRaw,'-01')),'[Mn,*-3]. [Y]',$lang,(),()),2)))
                  else if(contains($dateRaw,'0000-') and contains($dateRaw,'-00'))
                  then (concat(upper-case(substring(format-date(xs:date(replace(replace($dateRaw,'0000-','9999-'),'-00','-01')),'[Mn,*-3].',$lang,(),()),1,1)),substring(format-date(xs:date(replace(replace($dateRaw,'0000-','9999-'),'-00','-01')),'[Mn,*-3].',$lang,(),()),2)))
                  else if(starts-with($dateRaw,'0000-'))
                  then(concat(format-date(xs:date(replace($dateRaw,'0000-','9999-')),'[D]. ',$lang,(),()),upper-case(substring(format-date(xs:date(replace($dateRaw,'0000-','9999-')),'[Mn,*-3]. ',$lang,(),()),1,1)),substring(format-date(xs:date(replace($dateRaw,'0000-','9999-')),'[Mn,*-3].',$lang,(),()),2)))
                  else($dateRaw)
    
    let $replaceMay := $date => replace('Mai.','Mai') => replace('May.','May')
    return
        $replaceMay
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
: ToDo: find the right type of $date for shared:getBirthDeathDates
:
:)

declare function shared:shortenAndFormatDates($dateFrom, $dateTo, $form as xs:string, $lang as xs:string) as xs:string {
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


declare function shared:getBirthDeathDates($dates, $lang) {
    let $date := if ($dates/tei:date)
                        then (shared:formatDate($dates/tei:date, 'full', $lang))
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
        then (shared:translate('unknown'))
        else if ($datePlace)
        then (concat($datePlace, ', ', shared:translate('dateUnknown')))
        else (shared:translate('unknown'))
};

declare function shared:any-equals-any($args as xs:string*, $searchStrings as xs:string*) as xs:boolean {
    some $arg in $args
    satisfies
        some $searchString in $searchStrings
        satisfies
            $arg = $searchString
};

declare function shared:queryKey() {
  functx:substring-before-if-contains(concat(request:get-uri(), request:get-query-string()), "firstRecord")
};


declare %templates:wrap function shared:readCache($node as node(), $model as map(*), $cacheName as xs:string) {
    doc(concat('xmldb:exist:///db/apps/mriCat/caches/', $cacheName, '.xml'))/*
};


(: Patrick integrates https://jaketrent.com/post/xquery-browser-language-detection/ :)

declare function shared:get-browser-lang() as xs:string? {
  let $header := request:get-header("Accept-Language")
  return if (fn:exists($header)) then
    shared:get-top-supported-lang(shared:get-browser-langs($header), ("de", "en"))
  else
    ()
};

(:declare function shared:get-lang() as xs:string? {
  let $lang := if(string-length(request:get-parameter("lang", "")) gt 0) then
      (\: use http parameter lang as selected language :\)
      request:get-parameter("lang", "")
  else
     if(string-length(request:get-cookie-value("forceLang")) gt 0) then
       request:get-cookie-value("forceLang")
     else
       shared:get-browser-lang()
  (\: limit to de and en; en default :\)
  return if($lang != "en" and $lang != "de") then "en" else $lang
};:)

declare function shared:get-top-supported-lang($ordered-langs as xs:string*, $translations as xs:string*) as xs:string? {
  if (fn:empty($ordered-langs)) then
    ()
  else
    let $lang := $ordered-langs[1]
    return if ($lang = $translations) then
      $lang
    else
      shared:get-top-supported-lang(fn:subsequence($ordered-langs, 2), $translations)
};

declare function shared:get-browser-langs($header as xs:string) as xs:string* {
  let $langs :=
    for $entry in fn:tokenize(shared:parse-header($header), ",")
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

declare function shared:parse-header($header as xs:string) as xs:string {
  let $regex := "(([a-z]{1,8})(-[a-z]{1,8})?)\s*(;\s*q\s*=\s*(1|0\.[0-9]+))?"
  let $flags := "i"
  let $format := "$2q=$5"
  return fn:replace(fn:lower-case($header), $regex, $format)
};


declare function shared:getSelectedLanguage($node as node()*,$selectedLang as xs:string) {
    shared:get-lang()
};


declare function shared:stringJoinAll($node as node()) {
    string-join($node/string(),' | ')
};

(:~
 : Function to get the name of a person by ID
 : 
 : @param $param possible values are 'full', 'short'
 : @param $linking if the value is 'yes' the function tries to create a link to the authority file
 : @return If linking than node(), else string
 :)

declare function shared:getPersName($personID, $param as xs:string, $linking as xs:string?) {
let $person :=$app:collectionPersons/id($personID)
let $linkToRecord := '/' || $personID
let $persName := if($person/tei:persName[@role='uniform'])
                  then($person/tei:persName[@role='uniform'])
                  else($person/tei:persName[1])
let $nameForename := if($persName//tei:forename[@type='used'])
                     then($persName//tei:forename[not(@type='altWriting') and @type='used'])
                     else($persName//tei:forename[1])
let $nameForenames := $persName//tei:forename[not(@type='altWriting')]
                      => string-join(' ')
let $nameForenameAlt := if($persName//tei:forename[@type='altWriting']) then(concat('(auch ',$persName//tei:forename[@type='altWriting'], ')')) else()
let $nameNameLink := $persName//tei:nameLink/text()
let $nameSurname := $persName//tei:surname[not(@type='altWriting')]
                     => string-join(' ')
let $nameSurnameAlt := if($persName//tei:surname[@type='altWriting']) then(concat('(auch ',$persName//tei:surname[@type='altWriting'], ')')) else()
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
                            else(shared:translate('registry.persons.unknown'))
                        )
                    else if($param = 'short')
                    then(if($nameForename or $nameNameLink or $nameSurname)
                         then(string-join(($nameForename, $nameNameLink, $nameSurname, if($nameGenName) then(concat(' (',$nameGenName,')')) else()), ' '))
                         else if($persName/text() !='')
                          then(string-join($persName/text(), ' '))
                         else(shared:translate('registry.persons.unknown')))
                    else if($param = 'reversed')
                    then(
                        if($nameSurname)
                        then(concat($nameSurname,
                                   if($nameGenName) then(concat(' (',$nameGenName,')')) else(),
                                   if($nameAddNameTitle or $nameForenames or $nameForename or $nameNameLink)
                                   then(concat(', ', string-join(($nameAddNameTitle, (if($nameForenames) then($nameForenames)else($nameForename)), $nameNameLink), ' ')))
                                   else()))
                        else if($nameForename)
                        then(string-join(((if($nameForenames) then($nameForenames)else($nameForename)), $nameNameLink, $nameUnspec), ' '),
                             if($nameGenName) then(concat(' (',$nameGenName,')')) else())
                        else if($nameRoleName)
                        then($nameRoleName)
                        else if($nameAddNameNick)
                        then($nameAddNameNick)
                        else(shared:translate('registry.persons.unknown'))
                    )
                    
                    else (shared:translate('registry.persons.unknown'))
                    
    return
        if($linking = 'yes')
        then(<a href="{$linkToRecord}">{$nameStrings}</a>)
        else($nameStrings)
};


declare function shared:getPersonaLinked($id as xs:string) {
    
    let $personRecord := $app:collectionPersons[@xml:id = $id]
    let $personLink := concat('/', $id)
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
        else (shared:translate('registry.persons.unknown'))
};

declare function shared:getOrgNameFull($org as node()) {

    let $name := string-join($org/tei:orgName[1]//text(), ' ')
    
    return
        $name
};

declare function shared:getOrgNameFullLinked($org as node()) {

    let $orgID := $org/@xml:id
    let $orgUri := concat('/', $orgID)
    let $name := shared:getOrgNameFull($org)
    
    return
        <a href="{$orgUri}">{$name}</a>
};

declare function shared:getCorpNameFullLinked($corpName as node()) {

    let $corpID := $corpName/@codedval/string()
    let $corpUri := concat('/', $corpID)
    let $nameFound := if($corpID) then($app:collectionInstitutions[matches(@xml:id, $corpID)]//tei:orgName[1]/text()) else()
    let $name := if($nameFound) then($nameFound) else($corpName)
    
    return
        <a href="{$corpUri}">{$name}</a>
};


declare function shared:linkAll($node as node()){
    transform:transform($node,doc($config:app-root || '/resources/xslt/linking.xsl'),())
};

declare function shared:checkGenderforLangValues($persID){
    let $person := $app:collectionPersons[@xml:id=$persID]
    let $gender := $person//tei:sex/string(@type)
    return
        if($gender = 'male')
        then()
        else if ($gender = 'female')
        then('.female')
        else('')
};

(:~
 : Determine document type based on ID patterns from options.xml
 : 
 : @param $docID the document ID to check
 : @return string identifier for the document type (e.g. 'persons', 'works', 'other')
 :)
declare function shared:get-doc-type($docID as xs:string) as xs:string {
    let $patterns := map {
        'sourcesMusic': config:get-option('sourcesMusicIDs'),
        'works': config:get-option('workIDs'),
        'expressions': config:get-option('expressionIDs'),
        'persons': config:get-option('personIDs'),
        'institutions': config:get-option('institutionIDs'),
        'loci': config:get-option('lociIDs'),
        'sourcesDocs': config:get-option('sourcesDocIDs')
    }
    return
        if (matches($docID, $patterns?sourcesMusic)) then 'sourcesMusic'
        else if (matches($docID, $patterns?works)) then 'works'
        else if (matches($docID, $patterns?expressions)) then 'expressions'
        else if (matches($docID, $patterns?persons)) then 'persons'
        else if (matches($docID, $patterns?institutions)) then 'institutions'
        else if (matches($docID, $patterns?loci)) then 'loci'
        else if (matches($docID, $patterns?sourcesDocs)) then 'sourcesDocs'
        else 'other'
};

(:~
 : Get label and order for a document type
 : 
 : @param $docType the document type identifier
 : @return map with 'label' and 'order' keys
 :)
declare function shared:get-type-info($docType as xs:string) as map(*) {
    switch ($docType)
        case 'sourcesMusic' return map {
            'label': shared:translate('registry.persons.references.sources.music'),
            'order': '001'
        }
        case 'works' return map {
            'label': shared:translate('registry.persons.references.works'),
            'order': '002'
        }
        case 'expressions' return map {
            'label': shared:translate('registry.persons.references.works'),
            'order': '002'
        }
        case 'sourcesDocs' return map {
            'label': shared:translate('registry.persons.references.sources.text'),
            'order': '003'
        }
        case 'persons' return map {
            'label': shared:translate('registry.persons.references.persons'),
            'order': '004'
        }
        case 'institutions' return map {
            'label': shared:translate('registry.persons.references.institutions'),
            'order': '005'
        }
        case 'loci' return map {
            'label': shared:translate('registry.persons.references.loci'),
            'order': '006'
        }
        default return map {
            'label': shared:translate('registry.persons.references.other'),
            'order': '007'
        }
};

(:~
 : Extract title from document based on type
 : 
 : @param $doc the document node
 : @param $docType the document type
 : @return the document title as string
 :)
declare function shared:get-doc-title($doc as node(), $docType as xs:string) as xs:string {
    let $correspActionSent := $doc//tei:correspAction[@type="sent"]
    let $correspActionReceived := $doc//tei:correspAction[@type="received"]
    
    let $title := if($correspActionSent)
                  then(
                      let $sent := shared:getPersName($correspActionSent/tei:persName/@key, 'short','yes')
                      let $received := shared:getPersName($correspActionReceived/tei:persName/@key, 'short','yes')
                      return ($sent, ' an ', $received)
                  )
                  else if($docType = 'works' or $docType = 'expressions')
                  then($doc//(mei:work//mei:titlePart[@type="main"])[1]/text())
                  else if($docType = 'sourcesMusic')
                  then($doc//(mei:manifestation//mei:titlePart[@type="main"])[1]/text())
                  else if($docType = 'persons')
                  then($doc/tei:persName[1]//text())
                  else if($docType = 'institutions')
                  then($doc/tei:orgName[1]//text())
                  else if($docType = 'loci')
                  then($doc/tei:placeName[1]//text())
                  else if($doc/name()='TEI')
                  then($doc//tei:titleStmt/tei:title/string())
                  else('noTitle')
    
    return string-join($title, ' ') => normalize-space()
};

(:~
 : Build reference data structure for a person/institution/locus
 : 
 : @param $id the ID to find references for
 : @return map with grouped reference data
 :)
declare function shared:build-reference-data($id as xs:string) as map(*) {
    let $collectionReference := (
        $app:collectionPersons[matches(.//@key,$id)],
        $app:collectionInstitutions[matches(.//@key,$id)],
        $app:collectionLoci[matches(.//@key,$id)],
        $app:collectionDocuments[matches(.//@key,$id)],
        $app:collectionSourcesMusic[matches(.//@codedval,$id)],
        $app:collectionWorks[matches(.//@codedval,$id)],
        $app:collectionEditions[matches(.//@key,$id)],
        $app:collectionTexts[matches(.//@key,$id)]
    )
    
    let $entries := for $doc in $collectionReference
                    let $docID := string($doc/@xml:id)
                    let $docType := shared:get-doc-type($docID)
                    let $typeInfo := shared:get-type-info($docType)
                    let $title := shared:get-doc-title($doc, $docType)
                    let $sortValue := $title => replace('»','') => replace('«','')
                    return map {
                        'id': $docID,
                        'type': $docType,
                        'typeLabel': $typeInfo?label,
                        'order': $typeInfo?order,
                        'title': $title,
                        'sortValue': $sortValue
                    }
    
    (: Group by type :)
    let $grouped := map:merge(
        for $entry in $entries
        let $type := $entry?type
        group by $type
        return map:entry($type, array { $entry })
    )
    
    return map {
        'total': count($entries),
        'groups': $grouped
    }
};

(:~
 : Format reference data as HTML (legacy function)
 : 
 : @param $data the reference data map from build-reference-data()
 : @return HTML elements
 :)
declare function shared:format-references-html($data as map(*)) {
    for $groupKey in map:keys($data?groups)
    let $entries := $data?groups($groupKey)?*
    let $firstEntry := $entries[1]
    let $typeInfo := shared:get-type-info($groupKey)
    order by $typeInfo?order
    return
        <div class="RegisterSortBox" xmlns="http://www.w3.org/1999/xhtml">
            <div class="RegisterSortEntry">{$typeInfo?label}</div>
            {
                for $entry in $entries
                order by $entry?sortValue
                return
                    <div class="row RegisterEntry">
                        <div class="col-3">
                            {$entry?typeLabel}
                        </div>
                        <div class="col" docTitle="{$entry?title}">{$entry?title}</div>
                        <div class="col-3" docID="{$entry?id}">
                            <a href="/{$entry?id}">{$entry?id}</a>
                        </div>
                    </div>
            }
        </div>
};

(:~
 : Main entry point - get references and return as HTML (backward compatible)
 : 
 : @param $id the ID to find references for
 : @return HTML representation of references
 :)
declare function shared:getReferences($id) {
    let $data := shared:build-reference-data($id)
    return shared:format-references-html($data)
};

declare function shared:get-status-symbol($status as xs:string?) as node()? {
    if($status='proposed')
    then(<img src="$resources/img/ampel_rot.svg" title="Status:{$status}, (Traffic Light SVG Vector from https://www.svgrepo.com/svg/500083/traffic-light)" alt="Traffic Light SVG Vector from https://www.svgrepo.com/svg/500083/traffic-light" width="40px"/>)
    else if($status='candidate')
    then(<img src="$resources/img/ampel_gelb.svg" title="Status:{$status}, (Traffic Light SVG Vector from https://www.svgrepo.com/svg/500083/traffic-light)" alt="Traffic Light SVG Vector from https://www.svgrepo.com/svg/500083/traffic-light" width="40px"/>)
    else if($status='approved')
    then(<img src="$resources/img/ampel_gruen.svg" title="Status:{$status}, (Traffic Light SVG Vector from https://www.svgrepo.com/svg/500083/traffic-light)" alt="Traffic Light SVG Vector from https://www.svgrepo.com/svg/500083/traffic-light" width="40px"/>)
    else(<span>no status</span>)
};

(:~
 : Get norm data identifier - delegates to external-requests module
 : 
 : @param $object the TEI/MEI node containing idno elements
 : @param $identifierType the type of identifier ('gnd' or 'viaf')
 : @param $linking whether to return a linked HTML anchor element
 : @return linked anchor element or plain string identifier
 : @deprecated Use er:get-norm-data-link() directly
 :)
declare function shared:getNormDataIdentifier($object as node(), $identifierType as xs:string, $linking as xs:boolean) {
    er:get-norm-data-link($object, $identifierType, $linking)
};