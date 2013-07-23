class install_java {
	package { "software-properties-common":
		ensure => "installed" 
	}
	exec { "add repos": 
		command => "add-apt-repository ppa:webupd8team/java" ,
		path => "/usr/bin",
		require => Package["software-properties-common"] , 
	}
	exec { "apt-get update" : 
		command => "apt-get update" , 
		path => "/usr/bin", 
		require => Exec["add repos"] , 
	}
	package { "oracle-java7-installer" : 
		ensure => "installed" , 
		require => Exec["apt-get update"] , 
	}
	
}

class hadoop{
	$hadoop_jobtracker_host = "localhost:54311" 
	$hdfs_replication_value = 1 
	exec {"apps_wget":
		command => "/usr/bin/wget  http://ftp.twaren.net/Unix/Web/apache/hadoop/common/hadoop-1.2.0/hadoop-1.2.0.tar.gz -O /tmp/hadoop.tgz",
unless => "/bin/ls /tmp/hadoop.tgz",
	}
	exec {"untar hadoop":
		command => "/bin/tar  zxvf  /tmp/hadoop.tgz",
		cwd => "/home/thegiive/env" , 
		require => Exec["apps_wget"] , 
	}
	file{ "core-site.xml" : 
		path => "/home/thegiive/env/hadoop-1.2.0/conf/core-site.xml" , 
		source => "puppet:///hadoop/core-site.xml" , 
		require => Exec["untar hadoop"] , 
	}
	file{ "mapred-site.xml" : 
		path => "/home/thegiive/env/hadoop-1.2.0/conf/mapred-site.xml" , 
		content => template("hadoop/mapred-site.xml"), 
		require => Exec["untar hadoop"] , 
	}
	file{ "hdfs-site.xml" : 
		path => "/home/thegiive/env/hadoop-1.2.0/conf/hdfs-site.xml" , 
		content => template("hadoop/hdfs-site.xml"), 
		require => Exec["untar hadoop"] , 
	}
	file{ "hadoop-env.sh" : 
		path => "/home/thegiive/env/hadoop-1.2.0/conf/hadoop-env.sh" , 
		source => "puppet:///hadoop/hadoop-env.sh" , 
		require => Exec["untar hadoop"] , 
	}
	exec { "run hadoop": 
		command => "/home/thegiive/env/hadoop-1.2.0/bin/start-all.sh", 
		cwd => "/home/thegiive/env" , 
		require => Exec["untar hadoop"] ,
	}

}

#include install_java
include hadoop
