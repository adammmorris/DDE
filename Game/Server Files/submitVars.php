<?
$version = "dde_fmri_1";
//$repeat = "fromMST";

//GET IP
$ip = (getenv(HTTP_X_FORWARDED_FOR))
    ?  getenv(HTTP_X_FORWARDED_FOR)
    :  getenv(REMOTE_ADDR);

//experimental data

$id = $_POST[id];
$type = $_POST[Type];
$goal = $_POST[Goal];
$optnum = $_POST[OptNum];
$action = $_POST[Action];
$S2 = $_POST[S2];
$Re = $_POST[Re];
$rt1 = $_POST[rt1];
$rt2 = $_POST[rt2];
$score = $_POST[score];
$round = $_POST[round];

//add timestamp
$dateStamp = date("Y-m-j"); 
$timeStamp = date("H:i:s");

//send to database
$user="moral";
$password="j|n321";
$database="adam";
mysql_connect("localhost",$user,$password);
@mysql_select_db($database) or die( "Unable to select database");

$query1= "INSERT INTO dde VALUES ('$id','$dateStamp','$timeStamp','$version','$type','$goal','$optnum','$action','$S2','$Re','$rt1','$rt2','$score','$round','')";
mysql_query($query1);

mysql_close();
?> 