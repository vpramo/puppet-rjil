class rjil::commonservices::mediawiki {
  class { '::mediawiki':
    server_name      => 'wiki.corp.jiocloud.com',
    admin_email      => 'jiocloud.toolsteam@ril.com',
    db_root_password => 'db_password',
    doc_root         => '/mnt/data/var/www/wikis',
    max_memory       => '1024'
  }

  mediawiki::instance { 'jiocloud':
    db_password => 'db_password',
    db_name     => 'jiocloud_wiki_db',
    db_user     => 'jiocloud_wiki_db',
    port        => '80',
    ensure      => 'present'
  }

}
