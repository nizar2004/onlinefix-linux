<?php
namespace app\modules;

use facade\Json;
use std, gui, framework, app;


class Localization extends AbstractModule
{
    private $strings;
    private $fallback;
    
    /**
     * @event construct 
     */
    function doConstruct(ScriptEvent $e = null)
    {    
        $locale = Locale::getDefault()->getLanguage();
        if (ResourceStream::exists('res://locale/'.$locale.'.json') == false)
            $locale = 'en';
        
        $this->strings = Json::decode(ResourceStream::of('res://locale/'.$locale.'.json')->readFully());
        $this->fallback = $locale != 'en'
            ? Json::decode(ResourceStream::of('res://locale/en.json')->readFully())
            : $this->strings;
    }
    
    public function _(string $code)
    {
        return $this->strings[$code] ?? $this->fallback[$code] ?? $code;
    }
}
