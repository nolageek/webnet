<?
#supress PHP errors
error_reporting(0);
#ports 80,443,25,110,3306,21,22
#999 - port should not be active - means port is not supposed to be scanned

if($_GET['check'] == "main") {
	$p1="80";
	$p2="443";
	$p3="25";
	$p4="110";
	$p5="3306";
	$p6="21";
	$p7="22";
	$p8="53";
	
	$hd1="/";
	$hd2="/home";
	$hd3="/home2";
	$hd4="/home3";
	$hd5="/home4";
	$hd6="/home5";
	$hd7="/tmp";
	$hd8="/backup";
	$hd9="/boot";
	
	$host = "localhost";
	
	$portarray = array("$p1","$p2","$p3","$p4","$p5","$p6","$p7","$p8");
	foreach ($portarray as $port){
		#if port is 999 then do not check it
		if ($port=="999") echo "999,";
		else {
			$fp = @fsockopen($host, $port, $errno, $errstr, 10);
			if (!$fp) echo "2,";
			else {
				echo "1,";
				fclose ($fp);
			}
		}
	}
//number of processes
	$data = shell_exec('cat /proc/loadavg');
	$dataArray = explode(' ',$data);
	$procArray = explode('/',$dataArray[3]);
	echo $procArray[1].chr(10);


//Server Load - load average
	$loadavg_array = explode(" ", exec("cat /proc/loadavg"));
	$loadavg = $loadavg_array[0];
	//$loadavg = sys_getloadavg();
	echo ",".$loadavg;
	
//get disk space left hd1
	if ($hd1<>999){
		$hd1_total = disk_total_space("$hd1");
		$hd1_total=$hd1_total/1024;
		$hd1_total=$hd1_total/1024;
		$hd1_total=round($hd1_total, 2);
		
		$hd1_free = disk_free_space("$hd1");
		$hd1_free=$hd1_free/1024;
		$hd1_free=$hd1_free/1024;
		$hd1_free=round($hd1_free, 2);
	}

	if ($hd2<>999){
		$hd2_total = disk_total_space("$hd2");
		$hd2_total=$hd2_total/1024;
		$hd2_total=$hd2_total/1024;
		$hd2_total=round($hd2_total, 2);
		
		$hd2_free = disk_free_space("$hd2");
		$hd2_free=$hd2_free/1024;
		$hd2_free=$hd2_free/1024;
		$hd2_free=round($hd2_free, 2);
	}

	if ($hd3<>999){
		$hd3_total = disk_total_space("$hd3");
		$hd3_total=$hd3_total/1024;
		$hd3_total=$hd_total/1024;
		$hd3_total=round($hd3_total, 2);
		
		$hd3_free = disk_free_space("$hd3");
		$hd3_free=$hd3_free/1024;
		$hd3_free=$hd_free/1024;
		$hd3_free=round($hd3_free, 2);
	}

	if ($hd4<>999){
		$hd4_total = disk_total_space("$hd4");
		$hd4_total=$hd4_total/1024;
		$hd4_total=$hd4_total/1024;
		$hd4_total=round($hd4_total, 2);
		
		$hd4_free = disk_free_space("$hd4");
		$hd4_free=$hd4_free/1024;
		$hd4_free=$hd4_free/1024;
		$hd4_free=round($hd4_free, 2);
	}
	
	if ($hd5<>999){
		$hd5_total = disk_total_space("$hd5");
		$hd5_total=$hd5_total/1024;
		$hd5_total=$hd5_total/1024;
		$hd5_total=round($hd5_total, 2);
		
		$hd5_free = disk_free_space("$hd5");
		$hd5_free=$hd5_free/1024;
		$hd5_free=$hd5_free/1024;
		$hd5_free=round($hd5_free, 2);
	}

	if ($hd6<>999){
		$hd6_total = disk_total_space("$hd6");
		$hd6_total=$hd6_total/1024;
		$hd6_total=$hd6_total/1024;
		$hd6_total=round($hd6_total, 2);
		
		$hd6_free = disk_free_space("$hd6");
		$hd6_free=$hd6_free/1024;
		$hd6_free=$hd6_free/1024;
		$hd6_free=round($hd6_free, 2);
	}

	if ($hd7<>999){
		$hd7_total = disk_total_space("$hd7");
		$hd7_total=$hd7_total/1024;
		$hd7_total=$hd_total/1024;
		$hd7_total=round($hd7_total, 2);
		
		$hd7_free = disk_free_space("$hd7");
		$hd7_free=$hd7_free/1024;
		$hd7_free=$hd_free/1024;
		$hd7_free=round($hd7_free, 2);
	}

	if ($hd8<>999){
		$hd8_total = disk_total_space("$hd8");
		$hd8_total=$hd8_total/1024;
		$hd8_total=$hd8_total/1024;
		$hd8_total=round($hd8_total, 2);
		
		$hd8_free = disk_free_space("$hd8");
		$hd8_free=$hd8_free/1024;
		$hd8_free=$hd8_free/1024;
		$hd8_free=round($hd8_free, 2);
	}
	
	if ($hd9<>999){
		$hd9_total = disk_total_space("$hd9");
		$hd9_total=$hd9_total/1024;
		$hd9_total=$hd9_total/1024;
		$hd9_total=round($hd9_total, 2);
		
		$hd9_free = disk_free_space("$hd9");
		$hd9_free=$hd9_free/1024;
		$hd9_free=$hd9_free/1024;
		$hd9_free=round($hd9_free, 2);
	}

//Uptime 
	$uptime_array = explode(" ", exec("cat /proc/uptime"));
	$uptime = $uptime_array[0];
	print(",$uptime");
		
//Memory
	$mem_total_array = explode(":", exec("cat /proc/meminfo | grep MemTotal"));
	$mem_total = trim($mem_total_array[1]/1024);
	$mem_free_array = explode(":", exec("cat /proc/meminfo | grep MemFree"));
	$mem_free = trim($mem_free_array[1]/1024);
	
	$swap_total_array = explode(":", exec("cat /proc/meminfo | grep SwapTotal"));
	$tmp = explode(" ",trim($swap_total_array[1]));	
	$swap_total = $tmp[0]/1024;	
	
	$swap_free_array = explode(":", exec("cat /proc/meminfo | grep SwapFree"));
	$tmp_free = explode(" ",trim($swap_free_array[1]));	
	$swap_free = $tmp_free[0]/1024;	

	print(",$hd1_total,$hd1_free,$hd2_total,$hd2_free,$hd3_total,$hd3_free,$hd4_total,$hd4_free,$hd5_total,$hd5_free,$hd6_total,$hd6_free,$hd7_total,$hd7_free,$hd8_total,$hd8_free,$hd9_total,$hd9_free,$mem_total,$mem_free,$swap_total,$swap_free");

} else {	
//System Software and Version
	$php_version = explode(" ",exec("php -v | grep built"));
	$mysql_version_array = explode(" ", exec("mysql -V"));
	$mysql_version = $mysql_version_array[3]; 
	$mysql_version .= " ";
	$mysql_version .= $mysql_version_array[4];
	$mysql_version .= " ";
	$mysql_version .= substr_replace($mysql_version_array[5] ,"",-1);
	$webserver_version = explode(" ",exec('httpd -v | grep "Server version"'));
	$kernel = exec("cat /proc/sys/kernel/osrelease");
	$platform = exec("uname -m");
	$os = exec("uname -s");
	$distro = exec("cat /etc/redhat-release");
	$cpu_array = explode(":",exec("cat /proc/cpuinfo | grep processor"));
	$number_cpu = $cpu_array[1]+1;
	$model_name_array = explode(":",exec('cat /proc/cpuinfo | grep "model name"'));
	$model_name = $model_name_array[1];
	$cpu_speed_array = explode(":",exec('cat /proc/cpuinfo | grep "cpu MHz"'));
	$cpu_speed = $cpu_speed_array[1];
	$cache_size_array_tmp = explode(":",exec('cat /proc/cpuinfo | grep "cache size"'));
	$cache_size_array = explode(" ", $cache_size_array_tmp[1]);
	$cache_size = $cache_size_array[1];
	$cahce_size_unit = $cache_size_array[2];
	$seller_array = explode(":",exec("cat /proc/cpuinfo | grep vendor_id"));
	$seller = trim($seller_array[1]);
	
	print("$php_version[1],$mysql_version,$webserver_version[2],$kernel,$platform,$os,$distro,$number_cpu,$model_name,$cpu_speed,$cache_size,$cahce_size_unit,$seller");
}
?>