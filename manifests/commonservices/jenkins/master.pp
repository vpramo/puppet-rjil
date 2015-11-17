class rjil::commonservices::jenkins::master {
  include ::jenkins
  include ::rjil::commonservices::jenkins

  jenkins::plugin {
    'ansicolor':
    ;

    'antisamy-markup-formatter':
    ;

    'ant':
    ;

    'build-pipeline-plugin':
    ;

    'build-timeout':
    ;

    'conditional-buildstep':
    ;

    'copyartifact':
    ;

    'credentials':
    ;

    'cvs':
    ;

    'dashboard-view':
    ;

    'delivery-pipeline-plugin':
    ;

    'envinject':
    ;

    'extended-read-permission':
    ;

    'external-monitor-job':
    ;

    'gcm-notification':
    ;

    'ghprb':
    ;

    'git-client':
    ;

    'github-api':
    ;

    'github':
    ;

    'github-oauth':
    ;

    'git':
    ;

    'greenballs':
    ;

    'htmlpublisher':
    ;

    'instant-messaging':
    ;

    'ircbot':
    ;

    'javadoc':
    ;

    'jclouds-jenkins':
    ;

    'jenkins-multijob-plugin':
    ;

    'jobConfigHistory':
    ;

    'jquery':
    ;

    'jquery-ui':
    ;

    'junit':
    ;

    'ldap':
    ;

    'mailer':
    ;

    'mapdb-api':
    ;

    'matrix-auth':
    ;

    'matrix-project':
    ;

    'maven-plugin':
    ;

    'mercurial':
    ;

    'multiple-scms':
    ;

    'openid4java':
    ;

    'openid':
    ;

    'pam-auth':
    ;

    'parameterized-trigger':
    ;

    'plain-credentials':
    ;

    'pollscm':
    ;

    'publish-over-ssh':
    ;

    'rebuild':
    ;

    'repo':
    ;

    'run-condition':
    ;

    'SBuild':
    ;

    'scm-api':
    ;

    'scp':
    ;

    'slack':
    ;

    'ssh-agent':
    ;

    'ssh-credentials':
    ;

    'ssh-slaves':
    ;

    'subversion':
    ;

    'timestamper':
    ;

    'token-macro':
    ;

    'translation':
    ;

    'windows-slaves':
    ;

    'ws-cleanup':
    ;
  }

  file { '/home/jenkins/.gitconfig':
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/rjil/jenkins-gitconfig',
    mode   => '0644'
  }
}

