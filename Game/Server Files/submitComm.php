<?
$version = "dde_fmri_1";
//$repeat = "fromMST";

//GET IP
$ip = (getenv(HTTP_X_FORWARDED_FOR))
    ?  getenv(HTTP_X_FORWARDED_FOR)
    :  getenv(REMOTE_ADDR);

//experimental data

$id = $_POST[id];
$comm = $_POST[comm];

//add timestamp
$dateStamp = date("Y-m-j"); 
$timeStamp = date("H:i:s");

//send to database
$user="moral";
$password="j|n321";
$database="adam";
mysql_connect("localhost",$user,$password);
@mysql_select_db($database) or die( "Unable to select database");

$query1= "INSERT INTO comments VALUES ('$id','$dateStamp','$timeStamp','$version','$comm','')";
mysql_query($query1);

mysql_close();
?> 