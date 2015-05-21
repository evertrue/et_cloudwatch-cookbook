name             'et_cloudwatch'
maintainer       'EverTrue, Inc'
maintainer_email 'devops@evertrue.com'
license          'Apache 2.0'
description      'Provides a resource for setting up CloudWatch alerts'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.1'


depends 'et_fog', '>= 1.1.0'
