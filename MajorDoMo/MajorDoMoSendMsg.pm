#	MajorDoMo Connect Plug-in
#
#	Author:	Agaphonov Dmitri <skysilver.da@gmail.com>
#
#	Copyright (c) 2015 Agaphonov Dmitri
#	All rights reserved.
#

package Plugins::MajorDoMo::MajorDoMoSendMsg;

use strict;
use base qw(Slim::Networking::Async);

use URI;
use Slim::Utils::Log;
use Slim::Utils::Misc;
use Slim::Utils::Prefs;
use Slim::Networking::SimpleAsyncHTTP;
use Socket qw(:crlf);


# ----------------------------------------------------------------------------
my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.MajorDoMo',
	'defaultLevel' => 'ERROR',
	'description'  => 'PLUGIN_MAJORDOMO_MODULE_NAME',
});

# ----------------------------------------------------------------------------
# Глобальные переменные
# ----------------------------------------------------------------------------
	my $prefs = preferences('plugin.MajorDoMo'); #файл настроек
	my $self;

# ----------------------------------------------------------------------------
# Общие настройки
# ----------------------------------------------------------------------------
my $classPlugin	= undef;

# ----------------------------------------------------------------------------
# Конструктор плагина (тут ничего не меняем)
# ----------------------------------------------------------------------------
sub new {
	my $ref = shift;
	$classPlugin = shift;

	$log->debug( "MajorDoMoSendMsg::new() " . $classPlugin . "\\n");

	return $ref->SUPER::new();
}


# ----------------------------------------------------------------------------
# Функции-заглушки для обработки успешных и ошибочных ответов HTTP
# ----------------------------------------------------------------------------
sub HttpSuccess {
    my $http = shift;
    my $response = $http->response();
    $log->debug("HttpSuccess - URL: " . $http->url() . ", Code: " . $response->code() . ", Message: " . $response->message() . "\\n");
}


sub HttpError {
    my $http = shift;
    $log->error("HttpError - URL: " . $http->url() . ", Message: " . $http->error() . "\\n");
}


# ----------------------------------------------------------------------------
# Функция выполнения HTTP-запроса (GET)
# ----------------------------------------------------------------------------
sub HTTPSend{
	my $Addr = shift;
	my $Cmd = shift;
	my $timeout = 1;
	
	$log->debug("HTTPSend - Addr: " . $Addr . ", Cmd: " . $Cmd . "\\n");
	
	my $http = Slim::Networking::SimpleAsyncHTTP->new(
			\&HttpSuccess,
			\&HttpError, 
			{
				#mydata'  => 'foo',
				#cache    => 0,		# optional, cache result of HTTP request
				#expires => '1h',	# optional, specify the length of time to cache
			}
	);
	
	my $url = $Addr . $Cmd;
	
	$http->get($url);
}


# ----------------------------------------------------------------------------
# Функция выполнения HTTP-запроса (POST)
# ----------------------------------------------------------------------------
sub HTTPSendPOST{
	my $Addr = shift;
	my $Cmd = shift;
	my $PostData = shift;
	my $timeout = 1;
	
	$log->debug("HTTPSendPOST - Addr: " . $Addr . ", Cmd: " . $Cmd . ", PostData: " . $PostData . "\\n");
	
	my $http = Slim::Networking::SimpleAsyncHTTP->new(
		\&HttpSuccess,
		\&HttpError,
		{
			'cache' => 0,
			'timeout' => $timeout,
			'method' => 'POST',
			'content' => $PostData,
			'headers' => {'Content-Type' => 'application/json'}
		}
	);
	
	my $url = $Addr . $Cmd;
	
	$http->get($url);
}


# ----------------------------------------------------------------------------
# Функция обработки строки HTTP-запроса
# ----------------------------------------------------------------------------
sub SendCmd{
	my $Addr = shift;
	my $Cmd = shift;
	my $PostData = shift;
	
	$log->debug("SendCmd - Addr: " . $Addr . ", Cmd: " . $Cmd . ", PostData: " . (defined $PostData ? substr($PostData, 0, 50) . "..." : "undef") . "\\n");
	
	my $http = "http://";
	
	if( index($Addr, $http) == 0 ) {
		if (defined $PostData && length $PostData > 0) {
			HTTPSendPOST($Addr, $Cmd, $PostData);
		} else {
			HTTPSend($Addr, $Cmd);
		}
	}
	else{
		$log->debug("SendCmd - Wrong server address. \\n");
	}	
}
