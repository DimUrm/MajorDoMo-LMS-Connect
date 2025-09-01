package Plugins::MajorDoMo::Settings;

use strict;
use base qw(Slim::Web::Settings);
use Slim::Utils::Strings qw(string);
use Slim::Utils::Log;
use Slim::Utils::Prefs;

# ----------------------------------------------------------------------------
# Глобальные переменные
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Общие настройки
# ----------------------------------------------------------------------------
my $classPlugin	= undef;

my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.MajorDoMo',
	'defaultLevel' => 'ERROR',
	'description'  => 'PLUGIN_MAJORDOMO_MODULE_NAME',
});

# ----------------------------------------------------------------------------
# Путь и имя файла для хранения настроек плагина: prefs\plugin\MajorDoMo.pref
# ----------------------------------------------------------------------------
my $prefs = preferences('plugin.MajorDoMo');

# ----------------------------------------------------------------------------
# Конструктор плагина (тут ничего не меняем)
# ----------------------------------------------------------------------------
sub new {
	my $class = shift;

	$classPlugin = shift;

	$log->debug( "Settings::new() " . $classPlugin . "\\n");

	$class->SUPER::new();
	
	return $class;
}


# ----------------------------------------------------------------------------
# Запуск и остановка
# ----------------------------------------------------------------------------
sub handler {
	my $this = shift;
	my ($params, $client) = @_;
	
	$log->debug("Settings::handler() - Params: " . $params . " Client: " . $client . "\\n");

	if ($params) {
		if ($params->{'pref_Enabled'}) { 
			$prefs->client($client)->set('pref_Enabled', 1); 
		} else { 
			$prefs->client($client)->set('pref_Enabled', 0); 
		}
		
		if ($params->{'srvAddress'}) {
			my $srvAddress = $params->{'srvAddress'};
			$prefs->client($client)->set('srvAddress', "$srvAddress");
		}
		
		if ($params->{'msgOn1'}) {
			my $msgOn1 = $params->{'msgOn1'};
			$prefs->client($client)->set('msgOn1', "$msgOn1");
		}
		if ($params->{'msgOff1'}) { 
			my $msgOff1 = $params->{'msgOff1'};
			$prefs->client($client)->set('msgOff1', "$msgOff1"); 
		}
		if ($params->{'msgPlay1'}) { 
			my $msgPlay1 = $params->{'msgPlay1'};
			$prefs->client($client)->set('msgPlay1', "$msgPlay1"); 
		}
		if ($params->{'msgPause1'}) { 
			my $msgPause1 = $params->{'msgPause1'};
			$prefs->client($client)->set('msgPause1', "$msgPause1"); 
		}
		if ($params->{'msgVolume1'}) { 
			my $msgVolume1 = $params->{'msgVolume1'};
			$prefs->client($client)->set('msgVolume1', "$msgVolume1"); 
		}
		if ($params->{'msgNewsong'}) { 
			my $msgNewsong = $params->{'msgNewsong'};
			$prefs->client($client)->set('msgNewsong', "$msgNewsong"); 
		}
        
        # Добавленные параметры
		if ($params->{'msgSavePlaylist'}) {
			my $msgSavePlaylist = $params->{'msgSavePlaylist'};
			$prefs->client($client)->set('msgSavePlaylist', "$msgSavePlaylist");
		}
		if ($params->{'msgTrackProgress'}) {
			my $msgTrackProgress = $params->{'msgTrackProgress'};
			$prefs->client($client)->set('msgTrackProgress', "$msgTrackProgress");
		}
		if ($params->{'msgSync'}) {
			my $msgSync = $params->{'msgSync'};
			$prefs->client($client)->set('msgSync', "$msgSync");
		}
	}

	# Заполняем поля на странице настроек плагина в веб-интерфейсе.
	# Значения берутся из файла настроек.
	if($prefs->client($client)->get('pref_Enabled') == '1') {
		$params->{'prefs'}->{'pref_Enabled'} = 1; 
	}

	$params->{'prefs'}->{'srvAddress'} = $prefs->client($client)->get('srvAddress'); 
	$params->{'prefs'}->{'msgOn1'} = $prefs->client($client)->get('msgOn1'); 
	$params->{'prefs'}->{'msgOff1'} = $prefs->client($client)->get('msgOff1'); 
	$params->{'prefs'}->{'msgPlay1'} = $prefs->client($client)->get('msgPlay1'); 
	$params->{'prefs'}->{'msgPause1'} = $prefs->client($client)->get('msgPause1'); 
	$params->{'prefs'}->{'msgVolume1'} = $prefs->client($client)->get('msgVolume1'); 
	$params->{'prefs'}->{'msgNewsong'} = $prefs->client($client)->get('msgNewsong'); 
	
    # Заполняем новые поля
	$params->{'prefs'}->{'msgSavePlaylist'} = $prefs->client($client)->get('msgSavePlaylist');
	$params->{'prefs'}->{'msgTrackProgress'} = $prefs->client($client)->get('msgTrackProgress');
	$params->{'prefs'}->{'msgSync'} = $prefs->client($client)->get('msgSync');

	return $this->SUPER::handler($params, $client);
}


1;
