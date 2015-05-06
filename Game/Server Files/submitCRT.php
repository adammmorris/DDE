<?
$version = "rp_moral_1";
//$repeat = "fromMST";

//GET IP
$ip = (getenv(HTTP_X_FORWARDED_FOR))
    ?  getenv(HTTP_X_FORWARDED_FOR)
    :  getenv(REMOTE_ADDR);

//experimental data

$id = $_POST[id];
$crt1 = $_POST[crt1];
$crt2 = $_POST[crt2];
$crt3 = $_POST[crt3];

//add timestamp
$dateStamp = date("Y-m-j"); 
$timeStamp = date("H:i:s");

//send to database
$user="moral";
$password="j|n321";
$database="adam";
mysql_connect("localhost",$user,$password);
@mysql_select_db($database) or die( "Unable to select database");

$query1= "INSERT INTO crt VALUES ('$id','$dateStamp','$timeStamp','$version','$crt1','$crt2','$crt3','')";
mysql_query($query1);

mysql_close();
?> 