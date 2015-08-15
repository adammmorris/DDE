<?
ob_start();

if (rand(0,1) == 0) {
	$url = 'baseline_v2.swf';
} else {
	$url = 'noGoalInstructions.swf';
}

while (ob_get_status()) 
{
    ob_end_clean();
}

header( "Location: $url" );
?> 