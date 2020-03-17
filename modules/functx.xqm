xquery version "3.0";

module namespace functx = "http://www.functx.com";

declare function functx:max-string
  ( $strings as xs:anyAtomicType* )  as xs:string? {

   max(for $string in $strings return string($string))
 } ;