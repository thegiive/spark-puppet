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
	 require( Class["install_java"] )

	#http://www.michael-noll.com/tutorials/running-hadoop-on-ubuntu-linux-single-node-cluster/
	$hadoop_location = "/home/thegiive/env" 
	$hadoop_version = "hadoop-1.2.0" 
	$hadoop_jobtracker_host = "localhost:54311" 
	$hdfs_replication_value = 1 
	$hadoop_tmp_dir = "${hadoop_location}/${hadoop_version}/tmp/"
	$hadoop_hdfs_host = "hdfs://localhost:54310" 
	exec {"apps_wget":
		command => "/usr/bin/wget  http://ftp.twaren.net/Unix/Web/apache/hadoop/common/hadoop-1.2.0/hadoop-1.2.0.tar.gz -O /tmp/hadoop.tgz",
unless => "/bin/ls /tmp/hadoop.tgz",
	}
	exec {"untar hadoop":
		command => "/bin/tar  zxvf  /tmp/hadoop.tgz",
		cwd => "${hadoop_location}" , 
		require => Exec["apps_wget"] , 
	}
	file{ "core-site.xml" : 
		path => "${hadoop_location}/${hadoop_version}/conf/core-site.xml" , 
		content => template("hadoop/core-site.xml"), 
		require => Exec["untar hadoop"] , 
	}
	file{ "mapred-site.xml" : 
		path => "${hadoop_location}/${hadoop_version}/conf/mapred-site.xml" , 
		content => template("hadoop/mapred-site.xml"), 
		require => Exec["untar hadoop"] , 
	}
	file{ "hdfs-site.xml" : 
		path => "${hadoop_location}/${hadoop_version}/conf/hdfs-site.xml" , 
		content => template("hadoop/hdfs-site.xml"), 
		require => Exec["untar hadoop"] , 
	}
	file{ "hadoop-env.sh" : 
		path => "${hadoop_location}/${hadoop_version}/conf/hadoop-env.sh" , 
		source => "puppet:///hadoop/hadoop-env.sh" , 
		require => Exec["untar hadoop"] , 
	}
	exec { "generate rsa": 
		command => "/usr/bin/ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa" , 
	}
	exec { "cat rsa": 
		command => "/bin/cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys" , 
		require => Exec["generate rsa"] , 
	}
	
	exec { "run hadoop": 
		command => "${hadoop_location}/${hadoop_version}/bin/start-all.sh", 
		cwd => "${hadoop_location}" ,
		require => Exec["untar hadoop"] ,
	}

}

class spark{
	 require( Class["hadoop"] )
	$spark_location = "/home/thegiive/env" 
	$spark_slave = "localhost" 
	$spark_version = "spark-0.7.2" 
	$spark_worker_memory = "1g" 
       	$scala_home="/home/thegiive/scala-2.9.2"
       # https://github.com/amplab/shark/wiki/Running-Shark-on-a-Cluster 
       #scala home /usr/bin/
       package { "scala":
	       ensure => '2.9.2+dfsg-1' , 
        }
	exec {"wget_spark":
		command => "/usr/bin/wget  http://spark-project.org/files/spark-0.7.2-prebuilt-hadoop1.tgz      -O /tmp/spark.tgz",
			unless => "/bin/ls /tmp/spark.tgz",
			require => Package["scala"] , 
	}
	exec {"untar spark":
		command => "/bin/tar  zxvf  /tmp/spark.tgz",
		cwd => "${spark_location}" , 
		require => Exec["wget_spark"] , 
	}
	file{ "spark-env.sh" : 
		path => "${spark_location}/${spark_version}/conf/spark-env.sh" , 
		content => template("spark/spark-env.sh"), 
		require => Exec["untar spark"] , 
	}
	exec { "run spark": 
		command => "${spark_location}/${spark_version}/bin/start-all.sh", 
		cwd => "${spark_location}" ,
		require => file["spark-env.sh"] ,
	}
}

class shark{
	 require( Class["spark"] )
	$base_location = "/home/thegiive/env" 
	$shark_version = "shark-0.7.0"
 	$hive_version = "hive-0.9.0-bin"
	$hive_location = "${base_location}/${hive_version}"
	$shark_location = "${base_location}/${shark_version}"
	$spark_version = "spark-0.7.2" 
	$spark_location = "${base_location}/${spark_version}"
	$spark_server = "spark://localhost:7077"
	$spark_worker_memory = "1g" 

	$hadoop_version = "hadoop-1.2.0" 
	$hadoop_location = "${base_location}/${hadoop_version}"

	exec {"wget_shark":
		command => "/usr/bin/wget  http://spark-project.org/download/shark-0.7.0-hadoop1-bin.tgz        -O /tmp/shark.tgz",
			unless => "/bin/ls /tmp/shark.tgz",
	}
	exec {"untar shark":
		command => "/bin/tar  zxvf  /tmp/shark.tgz",
		cwd => "${shark_location}" , 
		require => Exec["wget_shark"] , 
	}
	file{ "shark-env.sh" : 
		path => "${shark_location}/conf/shark-env.sh" , 
		content => template("shark/shark-env.sh"), 
		require => Exec["untar shark"] , 
	}
}

class run{
$hadoop_location = "/home/thegiive/env" 
$hadoop_version = "hadoop-1.2.0" 
exec { "runhadoop": 
	command => "${hadoop_location}/${hadoop_version}/bin/start-all.sh", 
		cwd => "${hadoop_location}" ,
}
	$spark_location = "/home/thegiive/env" 
	$spark_version = "spark-0.7.2" 
exec { "runspark": 
	command => "${spark_location}/${spark_version}/bin/start-all.sh", 
		cwd => "${spark_location}" ,
                require => Exec["runhadoop"] ,

}
}
include install_java
include hadoop
include spark
include shark
include run
