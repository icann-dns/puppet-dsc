# == Class: dsc
#
class dsc (
  $enable_collector = true,
  $enable_presenter = false,
) {
  validate_bool($enable_collector)
  validate_bool($enable_presenter)
  if $enable_collector {
    include dsc::collector
  }
  if $enable_presenter {
    fail('Sorry this module does not currently support configuering the presenter.  Pull requests welcome https://github.com/icann-dns/puppet-dsc')
  }
}
