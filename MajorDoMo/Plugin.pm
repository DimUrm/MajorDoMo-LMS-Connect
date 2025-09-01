#	MajorDoMo Connect Plug-in
#
#	Author:	Agaphonov Dmitri <skysilver.da@gmail.com>
#
#	Copyright (c) 2015 Agaphonov Dmitri
#	All rights reserved.
#
#	2025-9-01 Update

package Plugins::MajorDoMo::Plugin;
use strict;

use base qw(Slim::Plugin::Base);

use URI::Escape qw(uri_escape_utf8);
use JSON;

use Slim::Utils::Strings qw(string);
use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Misc;
use Slim::Player::Client;
use Slim::Player::Source;
use Slim::Player::Playlist;
use Slim::Utils::Networking::SimpleRequest;

use File::Spec::Functions qw(:ALL);
use FindBin qw($Bin);

use Plugins::MajorDoMo::MajorDoMoSendMsg;
use Plugins::MajorDoMo::Settings;

# ----------------------------------------------------------------------------
# Глобальные переменные
# ----------------------------------------------------------------------------

my $playmodeCurrent = 'stop';
my $playmodeOld = 'stop';


# ----------------------------------------------------------------------------
my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.MajorDoMo',
	'defaultLevel' => 'ERROR',
	'description'  => 'PLUGIN_MAJORDOMO_MODULE_NAME',
});

# ----------------------------------------------------------------------------
# Путь и имя файла для хранения настроек плагина: prefs\plugin\MajorDoMo.pref
# ----------------------------------------------------------------------------
my $prefs    = preferences('plugin.MajorDoMo');


# ----------------------------------------------------------------------------
# Конструктор плагина (тут ничего не меняем)
# ----------------------------------------------------------------------------
sub new {
	my $class = shift;

	my $plugin = $class->SUPER::new(
		'name'        => 'MajorDoMo',
		'version'     => '0.3.5',
		'description' => 'PLUGIN_MAJORDOMO_DESCRIPTION',
		'author'      => 'Agaphonov Dmitri',
		'email'       => 'skysilver.da@gmail.com',
		'settings'    => 'Plugins::MajorDoMo::Settings',
	);
	
	return $plugin;
}


# ----------------------------------------------------------------------------
# Инициализация плагина (тут ничего не меняем)
# ----------------------------------------------------------------------------
sub initPlugin {
	my ($plugin) = @_;
	$log->debug("Plugin::initPlugin()\n");
	
	Slim::Player::Client::registerClientCallback(\&newPlayerCheck);
}


# ----------------------------------------------------------------------------
# Проверка на подключение нового плеера
# ----------------------------------------------------------------------------
sub newPlayerCheck {
	my ($client) = @_;
	$log->debug("Plugin::newPlayerCheck() - Player: " . $client->name() . " ID: " . $client->id() . "\\n");
	
	my $cprefs = $prefs->client($client);
	
	if ($cprefs->get('pref_Enabled')) {
	
		$log->debug("Plugin::newPlayerCheck() - Subscribed for Player: " . $client->name() . "\\n");
		
		$client->subscribe('power',         \&RequestPower);
		$client->subscribe('play',          \&RequestPlay);
		$client->subscribe('pause',         \&RequestPause);
		$client->subscribe('client',        \&RequestClient);
		$client->subscribe('mixer',         \&RequestVolume);
		$client->subscribe('newsong',       \&RequestNewsong);
        
        # Добавленные подписки
        $client->subscribe('track', \&RequestTrackProgress); # Подписка на изменение трека для обновления прогресса
        $client->subscribe('sync', \&RequestSync); # Подписка на события синхронизации
	}
}


# ----------------------------------------------------------------------------
# Главная функция обработки команд, поступающих от плеера
# ----------------------------------------------------------------------------
sub commandCallback {
    my ($plugin, $client, $command, $param) = @_;
    my $cprefs = $prefs->client($client);
	
	# ... (существующий код)
	
	# Добавьте вызовы для новых команд, если они поступают от других источников
	# (например, из HTTP API самого LMS)
    elsif ($command eq 'save_playlist') {
        RequestSavePlaylist($client);
    }
}


# ----------------------------------------------------------------------------
# Функция для сохранения плейлиста
# ----------------------------------------------------------------------------
sub RequestSavePlaylist {
    my $client = shift;
    my $cprefs = $prefs->client($client);
    my $Cmd = $cprefs->get('msgSavePlaylist');
    
    my $request = {
        'id' => 1,
        'method' => 'slim.request',
        'params' => [ $client->id(), ['playlist', 'info', 0, 500] ]
    };
    
    my ($success, $response) = Slim::Utils::Networking::SimpleRequest->jsonrpc($request);
    
    if ($success) {
        my $playlist_data = $response->{'result'}->{'playlist_loop'};
        if ($playlist_data) {
            my $json_text = encode_json($playlist_data);
            # Отправляем данные POST-запросом
            SendCommands($client, $Cmd, $json_text);
        } else {
            $log->debug("RequestSavePlaylist: Empty playlist");
        }
    } else {
        $log->debug("RequestSavePlaylist: JSON-RPC request failed");
    }
}


# ----------------------------------------------------------------------------
# Функция для отправки прогресса трека
# ----------------------------------------------------------------------------
sub RequestTrackProgress {
    my $client = shift;
    my $cprefs = $prefs->client($client);
    my $Cmd = $cprefs->get('msgTrackProgress');
    
    my $currentTime = $client->currentTime();
    if (defined $currentTime) {
        my $url = $Cmd . "&time=" . $currentTime;
        SendCommands($client, $url); # Используем GET для простых данных
    }
}

# ----------------------------------------------------------------------------
# Функция для отслеживания синхронизации
# ----------------------------------------------------------------------------
sub RequestSync {
    my $client = shift;
    my $cprefs = $prefs->client($client);
    my $Cmd = $cprefs->get('msgSync');
    
    my $syncGroupId = $client->syncGroupId();
    if (defined $syncGroupId) {
        my $url = $Cmd . "&sync_group=" . uri_escape_utf8($syncGroupId);
        SendCommands($client, $url);
    }
}


# ----------------------------------------------------------------------------
# Старые функции, которые были в плагине
# ----------------------------------------------------------------------------

sub RequestPower {
	my ($client, $param) = @_;
	
	$log->debug("Plugin::RequestPower() - Player: " . $client->name() . " ID: " . $client->id() . ", Power: " . $param . "\\n");
	
	if ($param) {
		RequestPowerOn($client);
	}
	else {
		RequestPowerOff($client);
	}
}


sub RequestPowerOn {

	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $Cmd = '';

	$Cmd = $cprefs->get('msgOn1');
	
	$log->debug("RequestPowerOn() Msg: " . $Cmd . "\\n");
	
	SendCommands($client, $Cmd);
}


sub RequestPowerOff {

	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $Cmd = '';

	$Cmd = $cprefs->get('msgOff1');
	
	$log->debug("RequestPowerOff() Msg: " . $Cmd . "\\n");
	
	SendCommands($client, $Cmd);
}


sub RequestPlay {

	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $Cmd = '';

	$Cmd = $cprefs->get('msgPlay1');
	
	$log->debug("RequestPlay() Msg: " . $Cmd . "\\n");
	
	SendCommands($client, $Cmd);
}


sub RequestPause {

	my $client = shift;
	my $cprefs = $prefs->client($client);
	my $Cmd = '';

	$Cmd = $cprefs->get('msgPause1');
	
	$log->debug("RequestPause() Msg: " . $Cmd . "\\n");
	
	SendCommands($client, $Cmd);
}


sub RequestVolume {

	my $client = shift;
	my $CurrentVolume = shift;
	my $cprefs = $prefs->client($client);
	my $Cmd = '';

	$Cmd = $cprefs->get('msgVolume1') . "&vollevel=" . $CurrentVolume;
	
	$log->debug("RequestVolume() Msg: " . $Cmd . "\\n");
	
	SendCommands($client, $Cmd);
}


sub RequestNewsong {

	my $client = shift;
	my $trackInfo = shift;
	my $cprefs = $prefs->client($client);
	my $Cmd = '';

	my $track = $trackInfo->{'track'};
	my $artist = $trackInfo->{'artist'};
	my $album = $trackInfo->{'album'};

	$log->debug("Plugin::RequestNewsong() - Track: " . $track . " Artist: " . $artist . " Album: " . $album . "\\n");
	
	$Cmd = $cprefs->get('msgNewsong') . "&track=" . uri_escape_utf8($track) . "&artist=" . uri_escape_utf8($artist) . "&album=" . uri_escape_utf8($album);
	
	SendCommands($client, $Cmd);

}


# ----------------------------------------------------------------------------
sub SendCommands{

	my $client = shift;
	my $iCmds = shift;
	my $PostData = shift;
	
	my $cprefs = $prefs->client($client);
	my $Addr = $cprefs->get('srvAddress');
	
	if (defined $Addr && length $Addr > 0) {
		$log->debug("SendCommands - Addr: " . $Addr . "\\n");
		
		if (defined $iCmds) {
			# if iCmds is not an array, convert it to an array
			unless (ref $iCmds eq 'ARRAY') {
				$iCmds = [$iCmds];
			}
			
			foreach my $iCmd (@$iCmds) {
				if ($iCmd =~ m/http:\/\// ) {
					$iCmd =~ s/http:\/\//\//g;
				}
				Plugins::MajorDoMo::MajorDoMoSendMsg->SendCmd($Addr, $iCmd, $PostData);
			}
		}
	}
}

1;
