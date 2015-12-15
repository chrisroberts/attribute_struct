## v0.2.26
* Add support for lowercase leading camel casing

## v0.2.24
* Fix `#_root` helper to properly check for parent
* Always use the `#_klass_new` helper
* Support optional arguments/block to `#_klass_new`

## v0.2.22
* Add more helper method bang aliases
* Properly persist camel data on Hash keys
* Support optional automatic AttributeStruct loading on Hash set

## v0.2.20
* Fix: remove nil structs

## v0.2.18
* Fix `AttributeStruct#dump!` to properly handle nil-type values

## v0.2.16
* Fix regression mixed argument and block set returning second level struct

## v0.2.14
* Fix `:value_collapse` option to prevent multiple nestings

## v0.2.12
* Implementation updates to monkey camels helper
* Provide bang style helper methods for all helpers

## v0.2.10
* Add support for multi parameter set

## v0.2.8
* Fix class mismatch issue

## v0.2.6
* Vendor `Mash` and expand to provide required deep_merge functionality
* Remove external dependencies

## v0.2.4
* Revert #class method removal (required by hash helpers when duping)
* Set base prior to path walking
* Initialize struct if nil is encountered
* Collapse values at leaf

## v0.2.2
* Update block evaluation assignment to prevent value knockout
* Fix `#is_a?` behavior and include base class in check list
* Add `#respond_to?` method
* Add irb helper module

## v0.2.0
* Add support for value setting into given context level
* Add #build helper method
* Introduce `:value_collapse` option for multi set combination instead of replacement
* Provide bang suffix aliases

## v0.1.8
* Basic (optional) auto camel detection on import
* Add hash helper methods out to class

## v0.1.6
* Add helpers for walking up the tree
* Update hashie dependency restriction

## v0.1.4
* Add `_array` helper
* Ensure all helpers are using underscore prefix
* Inherit from BasicObject
* Allow struct discovery in enumerable objects
* Add more helpers

## v0.1.2
* Fix naming in require

## v0.1.0
* Initial release
