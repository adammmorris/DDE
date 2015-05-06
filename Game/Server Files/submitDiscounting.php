<?
$version = "rp_moral_1";
//$repeat = "fromMST";

//GET IP
$ip = (getenv(HTTP_X_FORWARDED_FOR))
    ?  getenv(HTTP_X_FORWARDED_FOR)
    :  getenv(REMOTE_ADDR);

//experimental data

$id = $_POST[id];
$d1 = $_POST[d1];
$d2 = $_POST[d2];
$d3 = $_POST[d3];
$d4 = $_POST[d4];
$d5 = $_POST[d5];
$d6 = $_POST[d6];
$d7 = $_POST[d7];
$d8 = $_POST[d8];
$d9 = $_POST[d9];

//add timestamp
$dateStamp = date("Y-m-j"); 
$timeStamp = date("H:i:s");

//send to database
$user="moral";
$password="j|n321";
$database="adam";
mysql_connect("localhost",$user,$password);
@mysql_select_db($database) or die( "Unable to select database");

$query1= "INSERT INTO discounting VALUES ('$id','$dateStamp','$timeStamp','$version','$d1','$d2','$d3','$d4','$d5','$d6','$d7','$d8','$d9','')";
mysql_query($query1);

mysql_close();
?> 