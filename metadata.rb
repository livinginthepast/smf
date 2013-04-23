name             'smf'
maintainer       'ModCloth, Inc.'
maintainer_email 'ops@modcloth.com'
license          'Apache 2.0'
description      'A light weight resource provider (LWRP) for SMF (Service Management Facility)'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.6.9'

supports 'smartos'

depends 'rbac', '>= 0.0.2'

recommends 'resource-control'
