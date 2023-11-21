local imgui = require "mimgui"
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local wm = require 'lib.windows.message'
local ffi = require 'ffi'
local sampev = require 'lib.samp.events'
require "lib.moonloader"
local dlstatus = require('moonloader').download_status
local inicfg = require 'inicfg'
local bass = require "lib.bass"
local memory = require 'memory'
local Vector3D = require 'vector3d'
local ev = require "moonloader".audiostream_state
local ad = require "ADDONS"
local cjson = require 'cjson'
local bitex = require('bitex')
local bit = require('bit')
local effil = require('effil')
local hotkey = require('mimhotkey')
-- Библиотеки

local keyToggle = 0x04
local keyApply = 0x01
local keyApplyCar = 0x02

local top3 = nil
local camera_settings = {
	changed = false,
	distance = 2.0
}
local keys = {
	["onfoot"] = {},
	["vehicle"] = {}
}
local carban = false
local font = renderCreateFont("Tahoma", 10, FCR_BOLD + FCR_BORDER)
local font2 = renderCreateFont("Arial", 8, FCR_ITALICS + FCR_BORDER)

local cfg = inicfg.load({
    statTimers = {
    	state = false,
    	clock = false,
    	sesOnline = false,
    	sesAfk = false, 
    	sesFull = false,
  		dayOnline = false,
  		dayAfk = false,
  		dayFull = false,
  		weekOnline = false,
  		weekAfk = false,
  		weekFull = false,
        server = nil,
        reports = false,
        nakaz = false,
    },
	onDay = {
		today = os.date("%a"),
		online = 0,
		afk = 0,
		full = 0,
        reports = 0,
        nakaz = 0,
	},
	onWeek = {
		week = 1,
		online = 0,
		afk = 0,
		full = 0,
        reports = 0,
        nakaz = 0,
	},
    myWeekOnline = {
        [0] = 0,
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0
    },
    myWeekNakaz = {
        [0] = 0,
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0
    },
    myWeekReport = {
        [0] = 0,
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0
    },
    style = {
    	round = 10.0,
    	colorW = 4279834905,
    	colorT = 4286677377
    },
    pos = {
        x = 0,
        y = 0
    }
}, "TimerOnline")

local confq = inicfg.load({
    config = {
        volume = 50,
        sp = false,
        napom = false,
        carrot = false,
        imCarco = false,
        imCarcos = false,
        autoCome = false,
        adminPassword = '',
        showAdminPassword = true,
        radio = 0,
        radios = 0,
        radios2 = 0,
        retrans = false,
        sound = 0,
        speedHack = false,
        gmCar = false,
        noBike = false,
        airBrake = false,
        speed_airbrake = 1,
        showMyBullets = false,
        staticObjectMy = 0xFFFF0000,
        dinamicObjectMy = 0xFFFF0000,
        pedP = 0xFFFF0000,
        carP = 0xFFFF0000,
        pedPMy = 0xFFFF0000,
        carPMy = 0xFFFF0000,
        staticObject = 0xFFFF0000,
        dinamicObject = 0xFFFF0000,
        secondToClose = 5,
        secondToCloseTwo = 5,
        widthRenderLineOne = 1,
        widthRenderLineTwo = 1,
        secondToClose = 5,
        sizeOffPolygon = 1,
        sizeOffPolygonTwo = 1,
        polygonNumber = 1,
        polygonNumberTwo = 1,
        rotationPolygonOne = 10,
        rotationPolygonTwo = 10,
        maxMyLines = 50,
        maxNotMyLines = 50,
        cbEndMy = true,
        cbEnd = true,
        bulletTracer = false,
        wallhack = false,
        server = false,
        PC = false,
        recon = false,
        menutab = false
	},
    poskey = {
        x = 0,
        y = 0
    },
    ["hp"] = {
        ["color"] = 0xFFFF0000,
    },
    sorkcomm = {
        to = false,
        dm = false,
        sk = false,
        vred = false,
        tk = false,
        ch = false,
        nrp = false,
        orp = false,
        osk = false,
        tk = false,
    },
    bindKeys = {
        tool = "[0,0]",
        autoreport = "[0,0]",
        recon = "[0,0]",
        refresh = "[0,0]",
        nakaz = "[0,0]",
        leader = "[0,0]"
    }
}, "setap.ini")
inicfg.save(confq, "setap.ini")

local rInfo = {
	state = false,
    id = -1,
    nickname = '',
    status = false,
    tip = 'none',
    playerId = -1,
    vehicleId = -1,
    syncData = {},
    request = {},
    position = {},
    process_teleport = false,
    count = 0,
    command = ''
}
-- Массивы конфигов

local massiv = {
    dialogArr = {'Наборы', 'Предложить МП', 'Игровой вопрос'},
    dialogStr = '',

    dialogArrr = {'Rifa', 'Vagos', 'Aztecas', 'Groove', 'Ballas'},
    dialogStrr = '',
    
    dialogGoss = {'ППС', 'ФСБ', 'ВМФ', 'Мэрия', 'ДПС', 'ОМОН', 'АП', 'МЧС', 'СМИ'},
    dialogGos = '',

    dialogMaff = {'LCN', 'Yakudza', 'Русская Мафия', 'Хитманы'},
    dialogMaf = '',

    dialogOtb = {'Ghetto', 'Goss', 'Mafia'},
    dialogOtbb = '',

    dialogOsk = {'В репорте', 'В чате игрока', 'В чате администрацию'},
    dialogOskk = '',
    date = imgui.new.int(0),
    imBitch = imgui.new.bool(confq.config.napom),
    imBitche = imgui.new.bool(confq.config.sp),
    imCarrot = imgui.new.bool(confq.config.carrot),
    imCarco = imgui.new.bool(confq.config.imCarco),
    imCarcos = imgui.new.bool(confq.config.imCarcos),
    volume = imgui.new.float(confq.config.volume),
    PC = imgui.new.bool(confq.config.PC),
    toggle_toggle = imgui.new.bool(),
    retrans = imgui.new.bool(confq.config.retrans),
    arraynew = imgui.new.int(0),
    razdacha_zapusk = imgui.new.int(0),
    razdacha = imgui.new.int(0),
    slovo = imgui.new.int(0),
    mep = imgui.new.int(0),
    mepo = imgui.new.int(0),
    setstatos = imgui.new.int(0),
    numberAmmo = imgui.new.int(999),

    text_buffer = imgui.new.char[256](),
    texter = imgui.new.char[256](),
    text_opros = imgui.new.char[256](),
    idos = imgui.new.char[256](),
    idoss = imgui.new.char[256](),
}

local checkbox = {
    togglebuttons = {
        clocktime = imgui.new.bool(cfg.statTimers.clock),
        sesOnline = imgui.new.bool(cfg.statTimers.sesOnline),
        sesAfk = imgui.new.bool(cfg.statTimers.sesAfk),
        sesFull = imgui.new.bool(cfg.statTimers.sesFull),
        dayOnline = imgui.new.bool(cfg.statTimers.dayOnline),
        dayAfk = imgui.new.bool(cfg.statTimers.dayAfk),
        dayFull = imgui.new.bool(cfg.statTimers.dayFull),
        weekOnline = imgui.new.bool(cfg.statTimers.weekOnline),
        weekAfk = imgui.new.bool(cfg.statTimers.weekAfk),
        weekFull = imgui.new.bool(cfg.statTimers.weekFull),
        reports = imgui.new.bool(cfg.statTimers.reports),
        nakaz = imgui.new.bool(cfg.statTimers.nakaz),
    },
    statistics = {
        LsessionReport = 0,
        mcx = 0x0087FF,
        sX, sY = getScreenResolution(),
        tag = '{0087FF}TimerOnline: {FFFFFF}',
        to = imgui.new.bool(false),
        nowTime = os.date("%H:%M:%S", os.time()),
        settings = imgui.new.bool(false),
        myOnline = imgui.new.bool(false),
        pos = false,
        restart = false,
        recon = false,
        reportssumm = cfg.myWeekReport[0] + cfg.myWeekReport[1] + cfg.myWeekReport[2] + cfg.myWeekReport[3] + cfg.myWeekReport[4] + cfg.myWeekReport[5] + cfg.myWeekReport[6],
        nakazsumm = cfg.myWeekNakaz[0] + cfg.myWeekNakaz[1] + cfg.myWeekNakaz[2] + cfg.myWeekNakaz[3] + cfg.myWeekNakaz[4] + cfg.myWeekNakaz[5] + cfg.myWeekNakaz[6],
        sesOnline = imgui.new.int(0),
        sesAfk = imgui.new.int(0),
        sesFull = imgui.new.int(0),
        dayFull = imgui.new.int(cfg.onDay.full),
        weekFull = imgui.new.int(cfg.onWeek.full),
        sRound = imgui.new.float(cfg.style.round),
        posX = cfg.pos.x, 
        posY = cfg.pos.y,
        renderTAB = imgui.new.bool()
    },
}

local tWeekdays = {
    [0] = 'Воскресенье',
    [1] = 'Понедельник', 
    [2] = 'Вторник', 
    [3] = 'Среда', 
    [4] = 'Четверг', 
    [5] = 'Пятница', 
    [6] = 'Суббота'
}

local arrGuns = {
	[1] = 'Fist[0]',
	[2] = 'Brass knuckles[1]',
	[3] = 'Hockey stick[2]',
	[4] = 'Club[3]',
	[5] = 'Knife[4]',
	[6] = 'Bat[5]',
	[7] = 'Shovel[6]',
	[8] = 'Cue[7]',
	[9] = 'Katana[8]',
	[10] = 'Chainsaw[9]',
	[11] = 'Dildo[10]',
	[12] = 'Dildo[11]',
	[13] = 'Dildo[12]',
	[14] = 'Dildo[13]',
	[15] = 'Bouquet[14]',
	[16] = 'Cane[15]',
	[17] = 'Grenade[16]',
	[18] = 'Gas[17]',
	[19] = 'Molotov cocktail[18]',
	[20] = 'Unknown',
	[21] = 'Unknown',
	[22] = 'Unknown',
	[23] = '9MM[22]',
	[24] = '9mm with silencer[23]',
	[25] = 'Desert Eagle[24]',
	[26] = 'Shotgun[25]',
	[27] = 'Sawed-off[26]',
	[28] = 'Fast Shotgun[27]',
	[29] = 'Uzi[28]',
	[30] = 'MP5[29]',
	[31] = 'AK-47[30]',			
	[32] = 'M4[31]',	
	[33] = 'Tec-9[32]',		
	[34] = 'Sniper rifle[33]',			
	[35] = 'Sniper rifle[34]',			
	[36] = 'RPG[35]',			
	[37] = 'RPG[36]',			
	[38] = 'Flamethrower[37]',			
	[39] = 'Minigun[38]',			
	[40] = 'TNT bag[39]',			
	[41] = 'Detonator[40]',			
	[42] = 'Spray can[41]',			
	[43] = 'Fire extinguisher[42]',			
	[44] = 'Camera[43]',		
	[45] = 'Thermal imager[44]',			
	[46] = 'Thermal imager[45]'	,		
	[47] = 'Parachute[46]'			
}

local allGunsP = {
    ["24"] = "Desert Eagle",
    ["31"] = "M4",
    ["46"] = "Парашют",
    ["25"] = "Дробовик"
}

local prizemep =  {u8'"Король Дигла"', u8'"Русская Рулетка"', u8'"Дамба"', u8'"Прятки"', u8'"Последний Выживший"', u8'"Поливалка"', u8'"Бомбардировка"', u8'"Таран"', u8'"PUBG"', u8'"Реакция"', u8'"Бои без правил"', u8'"Гонки"', u8'"Дерби"', u8'"PaintBall"'}
local prizemp = {u8'"На Выбор"', u8'"Аптечки"', u8'"VIP-CAR"', u8'"Уровень на выбор"', u8'"Стиль Боя"', u8'Номер телефона на выбор', u8'Деньги', u8'Секрет', u8'Админ-права', u8'ПРОМОКОД'} 
local word = {u8'01', u8'PRIDE', u8'02', u8'ENVY', u8'MS', u8'Healme', u8'Kills', u8'LVL', u8'VIPCAR'}
local prizeon = {u8'"500 Аптечек"', u8'"200 Аптечек"', u8'"400 Аптечек"', u8'500 миллионов', u8'1337 убийств в статистику',  u8'"Костюм попугая"', u8'"Мигалку на голову"', u8'"Комплект всемогущий"', u8'"Огонек на голову"', u8'"Шляпу курицы"', u8'"Номер телефона на выбор"', u8'"1ккк"', u8'"Стиль Боя на Выбор"', u8'"500 убийств"', u8'"Уровень"', u8'"ВипКар"', u8'Бизнес', u8'Дом на VineWood', u8'секретный приз'}
local selectedd_item = {'Infernus', 'NRG 500', 'Sultan'}
local item_sound = {u8'Звук1', u8'Звук2'}
local item_theme = {u8'Синяя тема', u8'Фиолетовая тема', u8'Зеленая тема', u8'Красная тема', u8'Голубая тема'}

-- Обычные массивы

local tool = imgui.new.bool()

local ex, ey = getScreenResolution()

local direcories = {
    number1 = getWorkingDirectory() .. '/InTool/report.mp3',
    number2 = getWorkingDirectory() .. '/InTool/report2.mp3'
}

local speakid = ''

local obnova = {
    obnova = {
        vers = '2',
        script_vers_text = '1.00 PATH',
    },
}

local script_vers = obnova.obnova.vers
local script_vers_text = obnova.obnova.script_vers_text
local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
local colors_accent1, colors_accent2, colors_accent3, colors_neutral1, colors_neutral2 = {}, {}, {}, {}, {}

local MonetLua = require 'MoonMonet'

ffi.cdef[[
struct stKillEntry
{
	char					szKiller[25];
	char					szVictim[25];
	uint32_t				clKillerColor; // D3DCOLOR
	uint32_t				clVictimColor; // D3DCOLOR
	uint8_t					byteType;
} __attribute__ ((packed));

struct stKillInfo
{
	int						iEnabled;
	struct stKillEntry		killEntry[5];
	int 					iLongestNickLength;
  	int 					iOffsetX;
  	int 					iOffsetY;
	void			    	*pD3DFont; // ID3DXFont
	void		    		*pWeaponFont1; // ID3DXFont
	void		   	    	*pWeaponFont2; // ID3DXFont
	void					*pSprite;
	void					*pD3DDevice;
	int 					iAuxFontInited;
    void 		    		*pAuxFont1; // ID3DXFont
    void 			    	*pAuxFont2; // ID3DXFont
} __attribute__ ((packed));
]]

local menuSelect = 3
local b = '0790'

local tableOfNew = {
    poskey = {
        y = confq.poskey.y,
        x = confq.poskey.x,
    },
    reconmenu = imgui.new.bool(confq.config.recon),
    inputAmmoBullets = imgui.new.char[256](),
    givehp = imgui.new.int(100),
    selectedd_item = imgui.new.int(confq.config.radios2),
    selected_itom = imgui.new.int(confq.config.radios),
    tempLeader = imgui.new.bool(),
    AutoReport = imgui.new.bool(),
    carColor1 = imgui.new.char[256]("0"),
    carColor2 = imgui.new.char[256]("0"),
    givehp = imgui.new.int(100),
    selectGun = imgui.new.int(0),
    speed_airbrake = imgui.new.int(0),
    numberGunCreate = imgui.new.int(0),
    intComboCar = imgui.new.int(0),
    findText = imgui.new.char[256](),
    answer_report = imgui.new.char[256](),
    third_window = imgui.new.bool(),
    setstat = imgui.new.bool(),
    readytogo = imgui.new.bool(),
    bombino = imgui.new.bool(),
    item_sounds = imgui.new.int(confq.config.sound),
    windowcheck = imgui.new.bool(false),
    svoemp = imgui.new.char[256](),
    recon = imgui.new.bool(true),
    inputpost = imgui.new.char[256](),
    menutab = imgui.new.bool(),
}

local reports = {
    [0] = {
        nickname = '',
        id = -1,
        textP = ''
    }
}
local allCarsP = {
    ["487"] = "Maverick",
    ["411"] = "Infernus",
    ["560"] = "Sultan",
    ["522"] = "NRG",
    ["601"] = "SWAT",
    ["415"] = "Cheetah",
    ["451"] = "Turismo",
    ["510"] = "BMX"
}

local tCarsTypeName = {"Автомобиль", "Мотоицикл", "Вертолёт", "Самолёт", "Прицеп", "Лодка", "Другое", "Поезд", "Велосипед"}
local tCarsType = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1,
3, 1, 1, 1, 1, 6, 1, 1, 1, 1, 5, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 6, 3, 2, 8, 5, 1, 6, 6, 6, 1,
1, 1, 1, 1, 4, 2, 2, 2, 7, 7, 1, 1, 2, 3, 1, 7, 6, 6, 1, 1, 4, 1, 1, 1, 1, 9, 1, 1, 6, 1,
1, 3, 3, 1, 1, 1, 1, 6, 1, 1, 1, 3, 1, 1, 1, 7, 1, 1, 1, 1, 1, 1, 1, 9, 9, 4, 4, 4, 1, 1, 1,
1, 1, 4, 4, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 8, 8, 7, 1, 1, 1, 1, 1, 1, 1,
1, 3, 1, 1, 1, 1, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 1, 1, 1, 1, 8, 8, 7, 1, 1, 1, 1, 1, 4,
1, 1, 1, 2, 1, 1, 5, 1, 2, 1, 1, 1, 7, 5, 4, 4, 7, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5, 5, 1, 5, 5
}

local tCarsName = {"Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel", "Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus",
"Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam", "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BFInjection", "Hunter",
"Premier", "Enforcer", "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie", "Stallion", "Rumpo",
"RCBandit", "Romero","Packer", "Monster", "Admiral", "Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed",
"Yankee", "Caddy", "Solair", "Berkley'sRCVan", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RCBaron", "RCRaider", "Glendale", "Oceanic", "Sanchez", "Sparrow",
"Patriot", "Quad", "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage",
"Dozer", "Maverick", "NewsChopper", "Rancher", "FBIRancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking", "BlistaCompact", "PoliceMaverick",
"Boxvillde", "Benson", "Mesa", "RCGoblin", "HotringRacerA", "HotringRacerB", "BloodringBanger", "Rancher", "SuperGT", "Elegant", "Journey", "Bike",
"MountainBike", "Beagle", "Cropduster", "Stunt", "Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "hydra", "FCR-900", "NRG-500", "HPV1000",
"CementTruck", "TowTruck", "Fortune", "Cadrona", "FBITruck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan", "Blade", "Freight",
"Streak", "Vortex", "Vincent", "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder", "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada",
"Yosemite", "Windsor", "Monster", "Monster", "Uranus", "Jester", "Sultan", "Stratum", "Elegy", "Raindance", "RCTiger", "Flash", "Tahoma", "Savanna", "Bandito",
"FreightFlat", "StreakCarriage", "Kart", "Mower", "Dune", "Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400", "NewsVan",
"Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club", "FreightBox", "Trailer", "Andromada", "Dodo", "RCCam", "Launch", "PoliceCar", "PoliceCar",
"PoliceCar", "PoliceRanger", "Picador", "S.W.A.T", "Alpha", "Phoenix", "GlendaleShit", "SadlerShit", "Luggage A", "Luggage B", "Stairs", "Boxville", "Tiller",
"UtilityTrailer"}

local tempLeaders = {
    [1] = u8'Полиция ЛС',
    [2] = u8'FBI',
    [3] = u8'Армия LS',
    [4] = u8'Больница LS',
    [5] = u8'Итальянская Мафия',
    [6] = u8'Японская Мафия',
    [7] = u8'Мэрия',
    [8] = u8'Недоступно',
    [9] = u8'Недоступно',
    [10] = u8'Недоступно',
    [11] = u8'Недоступно',
    [12] = u8'Баллас',
    [13] = u8'Вагос',
    [14] = u8'Русская мафия',
    [15] = u8'Грув Стрит',
    [16] = u8'Радиоцентр',
    [17] = u8'Ацтек',
    [18] = u8'Рифа',
    [19] = u8'Недоступно',
    [20] = u8'Недоступно',
    [21] = u8'Недоступно',
    [22] = u8'Недоступно',
    [23] = u8'Похоронное Бюро',
    [24] = u8'Недоступно',
    [25] = u8'SWAT',
    [26] = u8'Администрация Президента',
    [27] = u8'Академия Полиции',
    [28] = u8'Недоступно'
}

local setstatis = {
	[1]= u8'[1] Уровень',
	[2]= u8'[2] Законопослушность',
	[3]= u8'[3] Материалы',
	[4]= u8'[4] Убийства',
	[5]= u8'[5] Номер Телефона',
	[6]= u8'[6] EXP',
	[7]= u8'[7] Деньги в Банке',
	[8]= u8'[8] Деньги на Мобиле',
	[9]= u8'[9] Наличные Деньги',
	[10]= u8'[10] Аптечки',
	[11]= u8'[11] Член орг.',
	[12]=  u8'[12] BOX',
	[13]= u8'[13] Kong-Fu',
	[14]= u8'[14] Kick-Box',
	[15]= u8'[15] Наркозависимость',
}

local arraynew = {
    [1] = u8"Репортам",
    [2] = u8"Джайлам",
    [3] = u8"Мутам",
    [4] = u8"Банам"
}

local arrayDate = {u8"За все время", u8"За неделю"}

local pensTable = [[Блокировка чата:
    МГ
    Капс
    Флуд
    Оскорбление игроков
    Оскорбление администрации
    Упоминание родных
    Обман администрации
    Бред в /gov, /d, /vad, /ad
    Транслит в: Игровой чат
    Отсутствие тэга в /gov, или /d

    Блокировка аккаунта:
    Использование читов в деморгане
    Реклама проектов
    Вредительские читы
    Использование читов в деморгане
    Выход от наказания
    Оскорбление проекта
    Оскорбление родных

    Выдача деморгана:
    ДМ
    ДБ
    ТК
    СК
    ПГ
    nonRP
    БагоЮз
    DM от 3-их человек
    Читы во фракции
    Читы

    Выдача варна:
    Отказ от проверки
    Найденны читы при проверке

    Блокировка репорта:
    Транслит
    Оффтоп
    Неадекват
]]

local timesTable = [[
    Время
    10 минут
    5 минут
    10 минут
    15 минут
    15 минут
    60 минут
    15 минут
    10 минут
    5 минут
    10 минут


    5 дней
    60 минут
    Навсегда + banip
    5 дней
    1 день
    60 минут
    60 минут -> 2 дня бана


    10 минут
    10 минут
    10 минут
    10 минут
    5 минут
    10 минут
    15 минут
    20 минут
    30 минут + увольнение
    60 минут


    1 варн
    1 варн


    5 минут
    10 минут
    30 минут
]]

for _, str in ipairs(massiv.dialogOsk) do
    massiv.dialogOskk = massiv.dialogOskk .. str .. '\n'
end

for _, str in ipairs(massiv.dialogArr) do
    massiv.dialogStr = massiv.dialogStr .. str .. "\n"
end

for _, str in ipairs(massiv.dialogArrr) do
    massiv.dialogStrr = massiv.dialogStrr .. str .. "\n"
end

for _, str in ipairs(massiv.dialogOtb) do
    massiv.dialogOtbb = massiv.dialogOtbb .. str .. "\n"
end

for _, str in ipairs(massiv.dialogGoss) do
    massiv.dialogGos = massiv.dialogGos .. str .. "\n"
end

for _, str in ipairs(massiv.dialogMaff) do
    massiv.dialogMaf = massiv.dialogMaf .. str .. "\n"
end

local elements = {
    checkbox = {
        autoCome = imgui.new.bool(confq.config.autoCome),
        adminPassword = imgui.new.char[256](u8(confq.config.adminPassword)),
        showAdminPassword = imgui.new.bool(confq.config.showAdminPassword),
        speedHack = imgui.new.bool(confq.config.speedHack),
        gmCar = imgui.new.bool(confq.config.gmCar),
        noBike = imgui.new.bool(confq.config.noBike),
        airBrake = imgui.new.bool(confq.config.airBrake),
        showMyBullets = imgui.new.bool(confq.config.showMyBullets),
        cbEnd = imgui.new.bool(confq.config.cbEnd),
        bulletTracer = imgui.new.bool(confq.config.bulletTracer),
    },
    int = {
        secondToClose = imgui.new.int(confq.config.secondToClose),
        secondToCloseTwo = imgui.new.int(confq.config.secondToCloseTwo),
        widthRenderLineOne = imgui.new.int(confq.config.widthRenderLineOne),
        widthRenderLineTwo = imgui.new.int(confq.config.widthRenderLineTwo),
        sizeOffPolygon = imgui.new.int(confq.config.sizeOffPolygon),
        sizeOffPolygonTwo = imgui.new.int(confq.config.sizeOffPolygonTwo),
        polygonNumber = imgui.new.int(confq.config.polygonNumber),
        polygonNumberTwo = imgui.new.int(confq.config.polygonNumberTwo),
        rotationPolygonOne = imgui.new.int(confq.config.rotationPolygonOne),
        rotationPolygonTwo = imgui.new.int(confq.config.rotationPolygonTwo),
        maxMyLines = imgui.new.int(confq.config.maxMyLines),
        maxNotMyLines = imgui.new.int(confq.config.maxNotMyLines)
    },
}

local bulletSync = {lastId = 0, maxLines = elements.int.maxNotMyLines[0]}
for i = 1, bulletSync.maxLines do
    bulletSync[i] = {other = {time = 0, t = {x,y,z}, o = {x,y,z}, type = 0, color = 0}}
end

local items = {
    items = {
        ImItems = imgui.new['const char*'][#setstatis](setstatis),
        ImWords = imgui.new['const char*'][#word](word),
        prizeon = imgui.new['const char*'][#prizeon](prizeon),
        ImWorks = imgui.new['const char*'][#word](word),
        prizemp = imgui.new['const char*'][#prizemp](prizemp),
        prizemep = imgui.new['const char*'][#prizemep](prizemep),
        tCarsName = imgui.new['const char*'][#tCarsName](tCarsName),
        selectedd_item = imgui.new['const char*'][#selectedd_item](selectedd_item),
        item_sound = imgui.new['const char*'][#item_sound](item_sound),
        item_theme = imgui.new['const char*'][#item_theme](item_theme),
        arrGuns = imgui.new['const char*'][#arrGuns](arrGuns),
        arraynew = imgui.new['const char*'][#arraynew](arraynew),
        arrayDate = imgui.new['const char*'][#arrayDate](arrayDate),
    },
    sorkcomm = {
        dm = imgui.new.bool(confq.sorkcomm.dm),
        sk = imgui.new.bool(confq.sorkcomm.sk),
        tk = imgui.new.bool(confq.sorkcomm.tk),
        ch = imgui.new.bool(confq.sorkcomm.ch),
        nrp = imgui.new.bool(confq.sorkcomm.nrp),
        osk = imgui.new.bool(confq.sorkcomm.osk),
        orp = imgui.new.bool(confq.sorkcomm.orp),
        vred = imgui.new.bool(confq.sorkcomm.vred),
    },
    bool = {
        wallhack = imgui.new.bool(confq.config.wallhack),
    }
}

function setShowCursor(toggle)
    lua_thread.create(function()
        if not isSampLoaded() or not isSampfuncsLoaded() then return end
        while not isSampAvailable() do wait(100) end
        if toggle then
            sampSetCursorMode(CMODE_LOCKCAM)
        else
            sampToggleCursor(false)
        end
        cursorEnabled = toggle
    end)
end

local binds = {
    bindCallback = function()
        tool[0] = not tool[0]
    end,
    autoreport = function()
        tableOfNew.AutoReport[0] = not tableOfNew.AutoReport[0]
    end,
    recon = function()
        sampSendChat('/re off')
    end,
    refresh = function()
        if rInfo.id < 0 then
            sampAddChatMessage('{ff0000}[InTool] Вы не в реконе!')
        end
        sampSendChat('/re '..rInfo.id)
    end,
    nakaz = function()
        tableOfNew.third_window[0] = not tableOfNew.third_window[0]
    end,
    leader = function()
        tableOfNew.tempLeader[0] = not tableOfNew.tempLeader[0]
    end
}

local bindKeys = {
    tool = decodeJson(confq.bindKeys.tool),
    autoreport = decodeJson(confq.bindKeys.autoreport),
    recon = decodeJson(confq.bindKeys.recon),
    refresh = decodeJson(confq.bindKeys.refresh),
    nakaz = decodeJson(confq.bindKeys.nakaz),
    leader = decodeJson(confq.bindKeys.leader)
}

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage('{FF0000}[InTool] {00FF00}Биги запустился. Чтобы использовать введите - /tool. {4B0082}Ваша версия: ' .. obnova.obnova.script_vers_text, -1)
    lua_thread.create(fortimer)
    lua_thread.create(registercommands)
    lua_thread.create(downloadFiles)
    lua_thread.create(time)
    lua_thread.create(autoSave)
    checkbox.statistics.to = imgui.new.bool(confq.sorkcomm.to)
    kill = ffi.cast('struct stKillInfo*', sampGetKillInfoPtr())
    local nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
    local servak = sampGetCurrentServerName()
    font = renderCreateFont("Arial", 8, 7)
    font1 = renderCreateFont("Arial", 10, 5)
    hotkey.no_flood = false
    lua_thread.create(function()
        while true do
            if not rInfo.state then
                tableOfNew.recon[0] = false
            else
                tableOfNew.recon[0] = true
            end
            while isPauseMenuActive() do
                if cursorEnabled then
                    setShowCursor(false)
                end
            end
            if isKeyJustPressed(keyToggle) and not (sampIsChatInputActive() or sampIsDialogActive() or isSampfuncsConsoleActive() or isPauseMenuActive()) then
                cursorEnabled = not cursorEnabled
                setShowCursor(cursorEnabled)
                while isKeyJustPressed(keyToggle) do wait(0) end
            end

            if cursorEnabled then
                local mode = sampGetCursorMode()
                if mode == 0 then
                    setShowCursor(true)
                end
                local sx, sy = getCursorPos()
                local sw, sh = getScreenResolution()
                -- is cursor in game window bounds?
                if sx >= 0 and sy >= 0 and sx < sw and sy < sh then
                    local posX, posY, posZ = convertScreenCoordsToWorld3D(sx, sy, 700.0)
                    local camX, camY, camZ = getActiveCameraCoordinates()
                    -- search for the collision point
                    local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, true, true, false, true, false, false, false)
                    if result and colpoint.entity ~= 0 then
                        local normal = colpoint.normal
                        local pos = Vector3D(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]) - (Vector3D(normal[1], normal[2], normal[3]) * 0.1)
                        local zOffset = 300
                        if normal[3] >= 0.5 then zOffset = 1 end
                        -- search for the ground position vertically down
                        local result, colpoint2 = processLineOfSight(pos.x, pos.y, pos.z + zOffset, pos.x, pos.y, pos.z - 0.3,
                            true, true, false, true, false, false, false)
                        if result then
                            pos = Vector3D(colpoint2.pos[1], colpoint2.pos[2], colpoint2.pos[3] + 1)

                            local curX, curY, curZ  = getCharCoordinates(playerPed)
                            local dist              = getDistanceBetweenCoords3d(curX, curY, curZ, pos.x, pos.y, pos.z)
                            local hoffs             = renderGetFontDrawHeight(font)

                            sy = sy - 2
                            sx = sx - 2
                            -- renderFontDrawText(font, string.format("%0.2fm", dist), sx, sy - hoffs, 0xEEEEEEEE)
                            renderFontDrawTextCenter(font, string.format("%0.2f", dist), sx+2, sy - hoffs, 0xEEEEEEEE)

                            local tpIntoCar = nil
                            if colpoint.entityType == 2 and not rInfo.state then
                                local car = getVehiclePointerHandle(colpoint.entity)
                                if doesVehicleExist(car) and (not isCharInAnyCar(playerPed) or storeCarCharIsInNoSave(playerPed) ~= car) then
                                    renderFontDrawTextCenter(font, getNameOfVehicleModel(getCarModel(car)), sx, sy - hoffs * 2, -1)
                                    local color = 0x44FFFFFF
                                    if isKeyDown(keyApplyCar) then
                                        tpIntoCar = car
                                        color = 0xFFFFFFFF
                                    end
                                    renderFontDrawTextCenter(font, 'Нажмите правую кнопку чтобы сесть в машину', sx, sy - hoffs*3, color)
                                end
                            end

                            createPointMarker(pos.x, pos.y, pos.z)

                            -- teleport!
                            if isKeyDown(keyApply) then
                                if rInfo.id ~= -1 and rInfo.state and sampIsPlayerConnected(id) and not sampIsPlayerPaused(id) then
                                    rInfo.command = '/gethere '..rInfo.id
                                    rInfo.position = pos
                                    rInfo.process_teleport = true
                                elseif not rInfo.status then
                                    if tpIntoCar then
                                        if not jumpIntoCar(tpIntoCar) then
                                        -- teleport to the car if there is no free seats
                                        teleportPlayer(pos.x, pos.y, pos.z)
                                        end
                                    else
                                        if isCharInAnyCar(playerPed) then
                                            local norm = Vector3D(colpoint.normal[1], colpoint.normal[2], 0)
                                            local norm2 = Vector3D(colpoint2.normal[1], colpoint2.normal[2], colpoint2.normal[3])
                                            rotateCarAroundUpAxis(storeCarCharIsInNoSave(playerPed), norm2)
                                            pos = pos - norm * 1.8
                                            pos.z = pos.z - 0.8
                                        end
                                        teleportPlayer(pos.x, pos.y, pos.z)
                                    end
                                end
                                removePointMarker()
                                setShowCursor(false)
                            end
                        end
                    end
                end
            end
            wait(0)
            removePointMarker()
        end
    end)
    hotkey.RegisterCallback('tool', bindKeys.tool, binds.bindCallback)
    hotkey.RegisterCallback('autoreport', bindKeys.autoreport, binds.autoreport)
    hotkey.RegisterCallback('reconoff', bindKeys.recon, binds.recon)
    hotkey.RegisterCallback('nakaz', bindKeys.nakaz, binds.nakaz)
    hotkey.RegisterCallback('refresh', bindKeys.refresh, binds.refresh)
    hotkey.RegisterCallback('leader', bindKeys.leader, binds.leader)
    imgui.Process = true
    async_http_request('GET', 'https://raw.githubusercontent.com/Vladislave232/InTool/main/uploader.txt', 
        {
            headers = {
                ['Content-Type'] = 'application/json'
            },
        },
        function(response)
            if response.status_code == 200 then
                version, versionT = response.text:match('version = (.*)\nversionT = (.*)')
                print(version, versionT)
            end
        end,
        function(err)
            print("Ошибка: " .. err)
        end
    )

    while true do
        wait(0)
        if massiv.imCarcos[0] then
            memory.setint16(getModuleHandle("samp.dll") + 0x09D318, 37008, true)
        end
        if items.bool.wallhack[0] then
            function getweaponname(weapon)
                local names = {
                [0] = "Fist",
                [1] = "Brass Knuckles",
                [2] = "Golf Club",
                [3] = "Nightstick",
                [4] = "Knife",
                [5] = "Baseball Bat",
                [6] = "Shovel",
                [7] = "Pool Cue",
                [8] = "Katana",
                [9] = "Chainsaw",
                [10] = "Purple Dildo",
                [11] = "Dildo",
                [12] = "Vibrator",
                [13] = "Silver Vibrator",
                [14] = "Flowers",
                [15] = "Cane",
                [16] = "Grenade",
                [17] = "Tear Gas",
                [18] = "Molotov Cocktail",
                [22] = "9mm",
                [23] = "Silenced 9mm",
                [24] = "Desert Eagle",
                [25] = "Shotgun",
                [26] = "Sawnoff Shotgun",
                [27] = "Combat Shotgun",
                [28] = "Micro SMG/Uzi",
                [29] = "MP5",
                [30] = "AK-47",
                [31] = "M4",
                [32] = "Tec-9",
                [33] = "Country Rifle",
                [34] = "Sniper Rifle",
                [35] = "RPG",
                [36] = "HS Rocket",
                [37] = "Flamethrower",
                [38] = "Minigun",
                [39] = "Satchel Charge",
                [40] = "Detonator",
                [41] = "Spraycan",
                [42] = "Fire Extinguisher",
                [43] = "Camera",
                [44] = "Night Vis Goggles",
                [45] = "Thermal Goggles",
                [46] = "Parachute" }
                return names[weapon]
            end
            for id = 0, sampGetMaxPlayerId(true) do
                if sampIsPlayerConnected(id) then
                    local exists, handle = sampGetCharHandleBySampPlayerId(id)
                    if exists and doesCharExist(handle) then
                        if isCharOnScreen(handle) then
                    
                            local color = sampGetPlayerColor(id)
                            local name = sampGetPlayerNickname(id)
                            local health = sampGetPlayerHealth(id)
                            local armor = sampGetPlayerArmor(id)
                            local weapon = getCurrentCharWeapon(handle)
                            local weap = getweaponname(weapon)
                            local ping = sampGetPlayerPing(id)
                            local X, Y, Z = getCharCoordinates(handle)
                            local x, y = convert3DCoordsToScreen(X, Y, Z)
                            local myX, myY, myZ = getCharCoordinates(playerPed)
                            local myx, myy = convert3DCoordsToScreen(myX, myY, myZ)
                            local distance = getDistanceBetweenCoords3d(X, Y, Z, myX, myY, myZ)
                            local model = getCharModel(handle)
                    
                            enabled = false
                            if enabled then
                                if not sampIsPlayerPaused(id) then
                                    renderFontDrawText(font, string.format("%s[%d]", name, id), x, y, color)
                                else
                                    renderFontDrawText(font, string.format("%s[%d] (AFK)", name, id), x, y, color)
                                end
                            end
                            enabled1 = true
                            distance = math.ceil(distance)
                            if enabled1 then
                                color = -1
                                if not sampIsPlayerPaused(id) then
                                    renderFontDrawText(font1, string.format("%s[%d]\n%d HP | %d AP\nPing: %d\nWeapon: %s\nДистанция: %s\n", name, id, health, armor, ping, weap, distance), x, y, color)
                                else
                                    renderFontDrawText(font1, string.format("%s[%d] (AFK)\n%d HP | %d AP\nPing: %d\nWeapon: %s\nДистанция: %s", name, id, health, armor, ping, weap, distance), x, y, color)
                                end
                            end
                            enabled2 = false
                    
                            if enabled2 then
                                renderDrawLine(myx, myy, x, y, 2, color)
                                renderDrawPolygon(x, y, 5, 5, 15, 0, color)
                            end
                    
                            enabled3 = false
                            if enabled3 then
                                local x1, y1, z1 = getModelDimensions(model)
                                local lx, ly, lz = getOffsetFromCharInWorldCoords(handle, x1, -y1, z1) -- НИЗ ПЕРЕД ЛЕВО
                                local scx1, scy1 = convert3DCoordsToScreen(lx, ly, lz)
                    
                                local x1, y1, z1 = getModelDimensions(model)
                                local lx, ly, lz = getOffsetFromCharInWorldCoords(handle, -x1, -y1, z1) -- НИЗ ПЕРЕД ПРАВО
                                local scx2, scy2 = convert3DCoordsToScreen(lx, ly, lz)
                    
                                renderDrawLine(scx1, scy1, scx2, scy2, 2, color)
                                
                                local x1, y1, z1= getModelDimensions(model)
                                local lx, ly, lz = getOffsetFromCharInWorldCoords(handle, -x1, -y1, z1) -- НИЗ ПЕРЕД ПРАВО
                                local scx1, scy1 = convert3DCoordsToScreen(lx, ly, lz)
                    
                                local x1, y1, z1 = getModelDimensions(model)
                                local lx, ly, lz = getOffsetFromCharInWorldCoords(handle, -x1, y1, z1) -- НИЗ ЗАД ПРАВО
                                local scx2, scy2 = convert3DCoordsToScreen(lx, ly, lz)
                    
                                renderDrawLine(scx1, scy1, scx2, scy2, 2, color)
                                
                                local x1, y1, z1 = getModelDimensions(model)
                                local lx, ly, lz = getOffsetFromCharInWorldCoords(handle, -x1, y1, z1) -- НИЗ ЗАД ПРАВО
                                local scx1, scy1 = convert3DCoordsToScreen(lx, ly, lz)
                    
                                local x1, y1, z1 = getModelDimensions(model)
                                local lx, ly, lz = getOffsetFromCharInWorldCoords(handle, x1, y1, z1) -- НИЗ ЗАД ЛЕВО
                                local scx2, scy2 = convert3DCoordsToScreen(lx, ly, lz)
                    
                                renderDrawLine(scx1, scy1, scx2, scy2, 2, color)
                                
                                local x1, y1, z1 = getModelDimensions(model)
                                local lx, ly, lz = getOffsetFromCharInWorldCoords(handle, x1, y1, z1) -- НИЗ ЗАД ЛЕВО
                                local scx1, scy1 = convert3DCoordsToScreen(lx, ly, lz)
                    
                                local x1, y1, z1 = getModelDimensions(model)
                                local lx, ly, lz = getOffsetFromCharInWorldCoords(handle, x1, -y1, z1) -- НИЗ ПЕРЕД ЛЕВО
                                local scx2, scy2 = convert3DCoordsToScreen(lx, ly, lz)
                    
                                renderDrawLine(scx1, scy1, scx2, scy2, 2, color)
                                renderDrawPolygon(x, y, 5, 5, 15, 0, color)
                            end
                        end
                    end
                end
            end
        end
        if isKeyJustPressed(0xA4) and isKeyJustPressed(0x02) then
            validtar, pedtar = getCharPlayerIsTargeting(playerHandle)
            if validtar and doesCharExist(pedtar) then
                local result, id = sampGetPlayerIdByCharHandle(pedtar)
                if result then
                    speakid = id
                    tableOfNew.windowcheck[0] = true
                end
            end
        end
        local result, button, list, input = sampHasDialogRespond(250)
        if result then
            if button == 1 then
                if list == 0 then
                    sampSendChat('/rmute ' .. jopa .. ' 15 Оскорбление Администрации')
                elseif list == 1 then
                    sampSendChat('/mute ' .. jopa .. ' 15 Оскорбление Игроков')
                elseif list == 2 then
                    sampSendChat('/mute ' .. jopa .. ' 15 Оскорбление Администрации')
                end
            end
        end
        local result, button, list, input = sampHasDialogRespond(13)
        if result then
            if button == 1 then
                if list == 0 then
                    sampSendChat('/aad INFO | Ув. лидеры/заместители, проводите собеседования наборы. Игрокам скучно!')
                elseif list == 1 then
                    sampSendChat('/aad INFO | Ув. игроки, вы можете предложить свое мероприятие - /report.')
                elseif list == 2 then
                    sampSendChat('/aad INFO | Ув. игроки. Вы можете задать любой игровой вопрос - /report.')
                end
            end
        end
        local result, button, list, input = sampHasDialogRespond(16)
        if result then
            if button == 1 then
                arrayGhetto = {"Rifa", "Vagos", "Aztec", "Groove", "Ballas"}
                sampSendChat('/aad Отбор | Ув. игроки, сейчас проходит отбор на должность лидера '..arrayGhetto[list+1])
                wait(1000)
                sampSendChat('/aad Отбор | Критерии: +14, +10 часов, знание правил.')
                wait(1000)
                sampSendChat('/aad Отбор | Желающие /gomp')
                wait(1000)
                sampSendChat('/mp')
            end
        end
        local result, button, list, input = sampHasDialogRespond(17)
        if result then
            if button == 1 then
                arrayGoss = {}
                sampSendChat('/aad Отбор | Ув. игроки, сейчас проходит отбор на должность лидера '..arrayGoss[list+1])
                wait(1000)
                sampSendChat('/aad Отбор | Критерии: +14, +10 часов, знание правил.')
                wait(1000)
                sampSendChat('/aad Отбор | Желающие /gomp')
                wait(1000)
                sampSendChat('/mp')
            end
        end
        local result, button, list, input = sampHasDialogRespond(18)
        if result then
            if button == 1 then
                arrayMafia = {"Русская Мафия", "Хитманы", "LCN", "Yakuza"}
                sampSendChat('/aad Отбор | Ув. игроки, сейчас проходит отбор на должность лидера '..arrayMafia[list+1])
                wait(1000)
                sampSendChat('/aad Отбор | Критерии: +14, +10 часов, знание правил.')
                wait(1000)
                sampSendChat('/aad Отбор | Желающие /gomp')
                wait(1000)
                sampSendChat('/mp')
            end
        end
        local result, button, list, input = sampHasDialogRespond(14)
        if result then
            if button == 1 then
                if list == 0 then
                    sampShowDialog(16, 'Выберите лидерку', massiv.dialogStrr, 'Тык', 'Закрыть', 2)
                elseif list == 1 then
                    sampShowDialog(17, 'Выберите лидерку', massiv.dialogGos, 'Тык', 'Закрыть', 2)
                elseif list == 2 then
                    sampShowDialog(18, 'Выберите лидерку', massiv.dialogMaf, 'Тык', 'Закрыть', 2)
                end
            end
        end
        if isCharInAnyCar(playerPed) then
            if elements.checkbox.speedHack[0] then
                if isKeyDown(0xA4) then
                    if getCarSpeed(storeCarCharIsInNoSave(playerPed)) * 2.01 <= 500 then
                        local cVecX, cVecY, cVecZ = getCarSpeedVector(storeCarCharIsInNoSave(playerPed))
                        local heading = getCarHeading(storeCarCharIsInNoSave(playerPed))
                        local turbo = fps_correction() / 65
                        local xforce, yforce, zforce = turbo, turbo, turbo
                        local Sin, Cos = math.sin(-math.rad(heading)), math.cos(-math.rad(heading))
                        if cVecX > -0.01 and cVecX < 0.01 then xforce = 0.0 end
                        if cVecY > -0.01 and cVecY < 0.01 then yforce = 0.0 end
                        if cVecZ < 0 then zforce = -zforce end
                        if cVecZ > -2 and cVecZ < 15 then zforce = 0.0 end
                        if Sin > 0 and cVecX < 0 then xforce = -xforce end
                        if Sin < 0 and cVecX > 0 then xforce = -xforce end
                        if Cos > 0 and cVecY < 0 then yforce = -yforce end
                        if Cos < 0 and cVecY > 0 then yforce = -yforce end
                        applyForceToCar(storeCarCharIsInNoSave(playerPed), xforce * Sin, yforce * Cos, zforce / 2, 0.0, 0.0, 0.0)
                    end
                end
            end
            if elements.checkbox.noBike[0] then
                setCharCanBeKnockedOffBike(playerPed, true)
            else
                setCharCanBeKnockedOffBike(playerPed, false)
            end	
            if elements.checkbox.gmCar[0] then
                setCanBurstCarTires(storeCarCharIsInNoSave(playerPed), false)
                setCarProofs(storeCarCharIsInNoSave(playerPed), true, true, true, true, true)
                setCarHeavy(storeCarCharIsInNoSave(playerPed), true)
                function sampev.onSetVehicleHealth(vehicleId, health)
                    if not boolEnabled then
                        return false
                    end
                end
            else
                setCanBurstCarTires(storeCarCharIsInNoSave(playerPed), false)
                setCarProofs(storeCarCharIsInNoSave(playerPed), false, false, false, false, false)
                setCarHeavy(storeCarCharIsInNoSave(playerPed), false)
            end
        end
        if elements.checkbox.airBrake[0] then 
            if isKeyJustPressed(VK_RSHIFT) and not sampIsChatInputActive() then
                enAirBrake = not enAirBrake
                if enAirBrake then
                    local posX, posY, posZ = getCharCoordinates(playerPed)
                    airBrkCoords = {posX, posY, posZ, 0.0, 0.0, getCharHeading(playerPed)}
                end
            end
        end
        if enAirBrake then
            if isCharInAnyCar(playerPed) then heading = getCarHeading(storeCarCharIsInNoSave(playerPed))
            else heading = getCharHeading(playerPed) end
            local camCoordX, camCoordY, camCoordZ = getActiveCameraCoordinates()
            local targetCamX, targetCamY, targetCamZ = getActiveCameraPointAt()
            local angle = getHeadingFromVector2d(targetCamX - camCoordX, targetCamY - camCoordY)
            if isCharInAnyCar(playerPed) then difference = 0.79 else difference = 1.0 end
            setCharCoordinates(playerPed, airBrkCoords[1], airBrkCoords[2], airBrkCoords[3] - difference)
            if not isSampfuncsConsoleActive() and not sampIsChatInputActive() and not sampIsDialogActive() and not isPauseMenuActive() then
                if isKeyDown(VK_W) then
                airBrkCoords[1] = airBrkCoords[1] + confq.config.speed_airbrake * math.sin(-math.rad(angle))
                airBrkCoords[2] = airBrkCoords[2] + confq.config.speed_airbrake * math.cos(-math.rad(angle))
                if not isCharInAnyCar(playerPed) then setCharHeading(playerPed, angle)
                else setCarHeading(storeCarCharIsInNoSave(playerPed), angle) end
                elseif isKeyDown(VK_S) then
                    airBrkCoords[1] = airBrkCoords[1] - confq.config.speed_airbrake * math.sin(-math.rad(heading))
                    airBrkCoords[2] = airBrkCoords[2] - confq.config.speed_airbrake * math.cos(-math.rad(heading))
                end
                if isKeyDown(VK_A) then
                    airBrkCoords[1] = airBrkCoords[1] - confq.config.speed_airbrake * math.sin(-math.rad(heading - 90))
                    airBrkCoords[2] = airBrkCoords[2] - confq.config.speed_airbrake * math.cos(-math.rad(heading - 90))
                elseif isKeyDown(VK_D) then
                    airBrkCoords[1] = airBrkCoords[1] - confq.config.speed_airbrake * math.sin(-math.rad(heading + 90))
                    airBrkCoords[2] = airBrkCoords[2] - confq.config.speed_airbrake * math.cos(-math.rad(heading + 90))
                end
                if isKeyDown(VK_UP) then airBrkCoords[3] = airBrkCoords[3] + confq.config.speed_airbrake / 2.0 end
                if isKeyDown(VK_DOWN) and airBrkCoords[3] > -95.0 then airBrkCoords[3] = airBrkCoords[3] - confq.config.speed_airbrake / 2.0 end
                if isKeyJustPressed(0xBB) then
                    confq.config.speed_airbrake = confq.config.speed_airbrake + 0.2
                    printStyledString('Speed minus by 0.2Now Speed: ' .. confq.config.speed_airbrake, 1000, 4) save()
                end
                if isKeyJustPressed(0xBD) then
                    confq.config.speed_airbrake = confq.config.speed_airbrake - 0.2
                    printStyledString('Speed plus by 0.2 Now Speed: ' .. confq.config.speed_airbrake, 1000, 4) save()
                end
            end
        end
        local oTime = os.time()
        if elements.checkbox.bulletTracer[0] then
            for i = 1, bulletSync.maxLines do
                if bulletSync[i].other.time >= oTime then
                    local result, wX, wY, wZ, wW, wH = convert3DCoordsToScreenEx(bulletSync[i].other.o.x, bulletSync[i].other.o.y, bulletSync[i].other.o.z, true, true)
                    local resulti, pX, pY, pZ, pW, pH = convert3DCoordsToScreenEx(bulletSync[i].other.t.x, bulletSync[i].other.t.y, bulletSync[i].other.t.z, true, true)
                    if result and resulti then
                        local xResolution = memory.getuint32(0x00C17044)
                        if wZ < 1 then
                            wX = xResolution - wX
                        end
                        if pZ < 1 then
                            pZ = xResolution - pZ
                        end 
                        renderDrawLine(wX, wY, pX, pY, elements.int.widthRenderLineOne[0], bulletSync[i].other.color)
                        if elements.checkbox.cbEnd[0] then
                            renderDrawPolygon(pX, pY-1, 3 + elements.int.sizeOffPolygonTwo[0], 3 + elements.int.sizeOffPolygonTwo[0], 1 + elements.int.polygonNumberTwo[0], elements.int.rotationPolygonTwo[0], bulletSync[i].other.color)
                        end
                    end
                end
            end
        end
    end
end

local fa = require("fAwesome5")
local fsClock = nil
local font = {}
imgui.OnInitialize(function()
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    u32 = imgui.ColorConvertFloat4ToU32
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    local iconRanges = imgui.new.ImWchar[3](fa.min_range, fa.max_range, 0)
    local path = getFolderPath(0x14) .. '\\COOPBL.ttf'
    imgui.GetIO().Fonts:AddFontFromFileTTF('trebucbd.ttf', 14.0, nil, glyph_ranges)
    icon = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 14.0, config, iconRanges)
    if fsClock == nil then
        fsClock = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\impact.ttf', 25.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
    -- дополнительные шриты:
    font[25] = imgui.GetIO().Fonts:AddFontFromFileTTF((getFolderPath(0x14) .. '\\ariblk.ttf'), 20.0, nil, glyph_ranges)
    font[19] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 19.0, nil, glyph_ranges)
    font[20] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 14.0, nil, glyph_ranges)
    font[12] = imgui.GetIO().Fonts:AddFontFromFileTTF((getFolderPath(0x14) .. '\\ariblk.ttf'), 16.0, nil, glyph_ranges)
    
    
    
    logo = imgui.CreateTextureFromFile(getWorkingDirectory() .. '/InTool/logos1.png')
    setting1 = imgui.CreateTextureFromFile(getWorkingDirectory() .. '/InTool/settings.jpg')
    local staticObject = imgui.ColorConvertU32ToFloat4(confq.config.staticObject)
    color1 = imgui.new.float[4](staticObject.x, staticObject.y, staticObject.z, staticObject.w)

    local dinamicObject = imgui.ColorConvertU32ToFloat4(confq.config.dinamicObject)
    color2 = imgui.new.float[4](dinamicObject.x, dinamicObject.y, dinamicObject.z, dinamicObject.w)

    local pedP = imgui.ColorConvertU32ToFloat4(confq.config.pedP)
    color3 = imgui.new.float[4](pedP.x, pedP.y, pedP.z, pedP.w)

    local carP = imgui.ColorConvertU32ToFloat4(confq.config.carP)
    color4 = imgui.new.float[4](carP.x, carP.y, carP.z, carP.w)
    imgui.GetIO().IniFilename = nil
    if tableOfNew.selected_itom[0] == 0 then
        imgui.thememoonmonet(0.5, true)
    elseif tableOfNew.selected_itom[0] == 1 then
        imgui.thememoonpurple(0.6, true)
    elseif tableOfNew.selected_itom[0] == 2 then
        imgui.themoongreen(1, true)
    elseif tableOfNew.selected_itom[0] == 3 then
        imgui.themoonred(1, true)
    elseif tableOfNew.selected_itom[0] == 4 then
        imgui.themoonyellow(1, true)
    end
end)

imgui.OnFrame(function() return tool[0] end,
    function(player)
        imgui.ShowCursor = true
        imgui.SetNextWindowPos(imgui.ImVec2(imgui.GetIO().DisplaySize.x / 2, imgui.GetIO().DisplaySize.y / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(700, 398), imgui.Cond.Always)
        imgui.Begin('                                                                                           ' .. (u8(' InTool')), tool, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse +  imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollbar)
        imgui.BeginChild("##menuSecond", imgui.ImVec2(180, 380), true)
        imgui.Text('            ')
        imgui.SameLine()
        if not massiv.PC[0] then
            imgui.Image(logo, imgui.ImVec2(88, 45))
        end
        imgui.Separator()
        imgui.TextDisabled(u8'Ваша версия '..u8:decode(obnova.obnova.script_vers_text))
        imgui.Separator()
        if imgui.Button(fa.ICON_FA_POWER_OFF, imgui.ImVec2(0, 0)) then
            thisScript():unload()
        end
        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_TACHOMETER_ALT, imgui.ImVec2(0, 0)) then
            menuSelect = 200
        end
        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_NEWSPAPER, imgui.ImVec2(0, 0)) then
            menuSelect = 3
        end imgui.SameLine()
        if imgui.Button(fa.ICON_FA_VIDEO, imgui.ImVec2(0, 0)) then
            menuSelect = 0
        end
        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_NEUTER, imgui.ImVec2(0, 0)) then
            menuSelect = 333
        end

        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_KEY, imgui.ImVec2(0, 0)) then
            menuSelect = 9
        end
        if imgui.Button(fa.ICON_FA_COG..(u8' Настройки'), imgui.ImVec2(170, 0)) then -- fa.ICON_FA_KEYBOARD
            menuSelect = 2
        end
        if imgui.Button(fa.ICON_FA_EXCLAMATION..(u8' Полезные ссылки'), imgui.ImVec2(170, 0)) then -- fa.ICON_FA_EXCLAMATION_TRIANGE или fa.ICON_FA_EXCLAMATION если не будет работать
            menuSelect = 49
        end
        if imgui.Button(fa.ICON_FA_CAR..(u8' Машины'), imgui.ImVec2(170, 0)) then -- fa.ICON_FA_CAR
            menuSelect = 1
        end
        if imgui.Button(fa.ICON_FA_RADIATION_ALT..(u8' Оружия'), imgui.ImVec2(170, 0)) then -- fa.ICON_FA_RADIATION_ALT
            menuSelect = 8
        end
        if imgui.Button(fa.ICON_FA_INDUSTRY..(u8' Раздачи'), imgui.ImVec2(170, 0)) then -- fa.ICON_FA_INDUSTRY
            tableOfNew.setstat[0] = not tableOfNew.setstat[0]
            menuSelect = 505
        end
        if imgui.Button(fa.ICON_FA_INDUSTRY..(u8' Мероприятия'), imgui.ImVec2(170, 0)) then -- fa.ICON_FA_INDUSTRY
            menuSelect = 122
        end
        if imgui.Button(fa.ICON_FA_LIST..(u8' Таблица наказаний'), imgui.ImVec2(170, 0)) then -- fa.ICON_FA_LIST
            tableOfNew.third_window[0] = not tableOfNew.third_window[0]
        end
        if imgui.Button(fa.ICON_FA_LIST_OL..(u8' Временное лидерство'), imgui.ImVec2(170, 0)) then -- fa.ICON_FA_LIST_OL
            tableOfNew.tempLeader[0] = not tableOfNew.tempLeader[0]
        end
        if imgui.Button(fa.ICON_FA_POLL..(u8' Лучшие Администраторы'), imgui.ImVec2(170, 0)) then -- fa.ICON_FA_POLL
--[[             lua_thread.create(function()
                getlist()
                wait(1000)
                menuSelect = 2222
            end) ]]
            sampAddChatMessage('{ff0000}[InTool] {ffffff}К сожалению эта функция находится на стадии разработки! Ожидайте обновления.')
        end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild("##menuSelectable", imgui.ImVec2(500, 380), true)
        if menuSelect == 200 then
            imgui.PushFont(fsClock) imgui.TextDisabled('Timer Online') imgui.PopFont()
        	imgui.BeginChild('##checkboxButtons', imgui.ImVec2(190, 245), true)
        	   	if ad.ToggleButton(u8'Текущее дата и время', checkbox.togglebuttons.clocktime) then
                   cfg.statTimers.clock = checkbox.togglebuttons.clocktime[0]
                end
	            if ad.ToggleButton(u8'Онлайн сессию', checkbox.togglebuttons.sesOnline) then 
                    cfg.statTimers.sesOnline = checkbox.togglebuttons.sesOnline[0]
                end
	            imgui.Text(u8'Без учёта АФК (Чистый онлайн)')
	            if ad.ToggleButton(u8'AFK за сессию', checkbox.togglebuttons.sesAfk) then 
                    cfg.statTimers.sesAfk = checkbox.togglebuttons.sesAfk[0]
                end
	            if ad.ToggleButton(u8'Общий за сессию', checkbox.togglebuttons.sesFull) then 
                    cfg.statTimers.sesFull = checkbox.togglebuttons.sesFull[0]
                end
	            if ad.ToggleButton(u8'Онлайн за день', checkbox.togglebuttons.dayOnline) then 
                    cfg.statTimers.dayOnline = checkbox.togglebuttons.dayOnline[0]
                end
	            imgui.Text(u8'Без учёта АФК (Чистый онлайн)')
	            if ad.ToggleButton(u8'АФК за день', checkbox.togglebuttons.dayAfk) then 
                    cfg.statTimers.dayAfk = checkbox.togglebuttons.dayAfk[0]
                end
	            if ad.ToggleButton(u8'Общий за день', checkbox.togglebuttons.dayFull) then 
                    cfg.statTimers.dayFull = checkbox.togglebuttons.dayFull[0]
                end
                if ad.ToggleButton(u8'Репорты за день', checkbox.togglebuttons.reports) then
                    cfg.statTimers.reports = checkbox.togglebuttons.reports[0]
                end
                if ad.ToggleButton(u8'Наказаний выдано: ', checkbox.togglebuttons.nakaz) then
                    cfg.statTimers.nakaz = checkbox.togglebuttons.nakaz[0]
                 end
	            if ad.ToggleButton(u8'Онлайн за неделю', checkbox.togglebuttons.weekOnline) then 
                    cfg.statTimers.weekOnline = checkbox.togglebuttons.weekOnline[0]
                end
	            imgui.Text(u8'Без учёта АФК (Чистый онлайн)')
	            if ad.ToggleButton(u8'АФК за неделю', checkbox.togglebuttons.weekAfk) then
                    cfg.statTimers.weekAfk = checkbox.togglebuttons.weekAfk[0]
                end
	            if ad.ToggleButton(u8'Общий за неделю', checkbox.togglebuttons.weekFull) then
                    cfg.statTimers.weekFull = checkbox.togglebuttons.weekFull[0]
                end
        	imgui.EndChild()
        	imgui.SameLine()
        	imgui.BeginChild('##Customisation', imgui.ImVec2(-1, 245), true)
        	    if imgui.Checkbox(u8('##State'), checkbox.statistics.to) then 
		    		confq.sorkcomm.to = checkbox.statistics.to[0]
		    		save()
		    	end
		    	imgui.SameLine()
		    	if checkbox.statistics.to[0] then
		    		imgui.TextColored(imgui.ImVec4(0.00, 0.53, 0.76, 1.00), u8'Включено')
		    	else
		    		imgui.TextDisabled(u8'Выключено')
		    	end
        	    if imgui.Button(u8'Местоположение', imgui.ImVec2(-1, 20)) then
	                lua_thread.create(function ()
	                    checkCursor = true
	                    tool[0] = false
	                    sampSetCursorMode(4)
	                	sampAddChatMessage(checkbox.statistics.tag..'Нажмите {0087FF}SPACE{FFFFFF} что-бы сохранить позицию', checkbox.statistics.mcx)
	                    while checkCursor do
	                        local cX, cY = getCursorPos()
	                        checkbox.statistics.posX, checkbox.statistics.posY = cX, cY
	                        if isKeyDown(32) then
	                        	sampSetCursorMode(0)
	                        	cfg.pos.x, cfg.pos.y = checkbox.statistics.posX, checkbox.statistics.posY
	                            checkCursor = false
	                            tool[0] = true
	                            if inicfg.save(cfg, 'TimerOnline.ini') then sampAddChatMessage(checkbox.statistics.tag ..'Позиция сохранена!', checkbox.statistics.mcx) end
	                        end
	                        wait(0)
	                    end
	                end)
	            end
        	    imgui.PushItemWidth(-1)
                imgui.SetCursorPosY(imgui.GetWindowHeight() - 20)
                imgui.Text(u8'Сбросить все настройки')
	            if imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0) then
	                restart = true
	                os.remove(getWorkingDirectory()..'\\config\\TimerOnline.ini')
	                thisScript():reload()
	            else
	                imgui.Text(u8'Двойной клик что-бы\nсбросить все настройки и таймеры')
	            end
        	imgui.EndChild()
            if imgui.Button(u8'Сохранить и закрыть', imgui.ImVec2(-1, 20)) then
                if inicfg.save(cfg, 'TimerOnline.ini') then 
                	sampAddChatMessage(checkbox.statistics.tag..'Настройки сохранены!', checkbox.statistics.mcx)
                	checkbox.statistics.settings[0] = false 
                end
            end
            if imgui.Button(u8'Статистика онлайна на протяжении недели', imgui.ImVec2(-1, 20)) then
                checkbox.statistics.myOnline[0] = true
            end
        end
        if menuSelect == 9 then 
            imgui.PushFont(font[25])
            imgui.CenterText(u8'Binds MENU')
            imgui.PopFont()

            imgui.BeginChild('assd', imgui.ImVec2(320, 180), true)
            local toh = hotkey.KeyEditor('tool', u8'Активация Tool')
            local autop = hotkey.KeyEditor('autoreport', u8'AutoReport')
            local reoff = hotkey.KeyEditor('reconoff', u8'Выход из рекона') 
            local ref = hotkey.KeyEditor('refresh', u8'Refresh в реконе')
            local nakaz = hotkey.KeyEditor('nakaz', u8'Таблица наказаний')
            local leader = hotkey.KeyEditor('leader', u8'Временное лидерство')
            imgui.EndChild()

            if reoff then confq.bindKeys.recon = encodeJson(reoff); save() end    
            if ref then confq.bindKeys.refresh = encodeJson(ref); save(); end
            if autop then confq.bindKeys.autoreport = encodeJson(autop); save(); end
            if toh then confq.bindKeys.tool = encodeJson(toh); save(); end
            if nakaz then confq.bindKeys.nakaz = encodeJson(nakaz); save(); end
            if leader then confq.bindKeys.leader = encodeJson(leader); save(); end
            if imgui.Button(u8'Сбросить настройки биндов') then 
                confq.bindKeys.tool = "[0,0]"
                confq.bindKeys.refresh = "[0,0]"
                confq.bindKeys.recon = "[0,0]"
                confq.bindKeys.autoreport = "[0,0]"
                confq.bindKeys.nakaz = "[0,0]"
                confq.bindKeys.leader = "[0,0]"
                save()
                sampAddChatMessage("{FF0000}[InTool] {ffffff}Перезагружаюсь...", -1)
                thisScript():reload()
            end
        end

        if menuSelect == 333 then
            imgui.Separator()
            imgui.PushItemWidth(175)
            if imgui.SliderInt("##secondsBullets", elements.int.secondToClose, 5, 15) then
                confq.config.secondToClose = elements.int.secondToClose[0]
                save()
            end imgui.SameLine() imgui.Text(u8"Время задержки трейсера")
            if imgui.SliderInt("##renderWidthLinesOne", elements.int.widthRenderLineOne, 1, 10) then
                confq.config.widthRenderLineOne = elements.int.widthRenderLineOne[0]
                save()
            end imgui.SameLine() imgui.Text(u8"Толщина линий")
            if imgui.SliderInt('##numberNotMyBullet', elements.int.maxNotMyLines, 10, 300) then
                bulletSync.maxNotMyLines = elements.int.maxNotMyLines[0]
                bulletSync = {lastId = 0, maxLines = elements.int.maxNotMyLines[0]}
                for i = 1, bulletSync.maxLines do
                    bulletSync[i] = { other = {time = 0, t = {x,y,z}, o = {x,y,z}, type = 0, color = 0}}
                end
                confq.config.maxNotMyLines = elements.int.maxNotMyLines[0]
                save()
            end imgui.SameLine() imgui.Text(u8"Максимальное количество линий")
            
            imgui.Separator()

            if imgui.Checkbox(u8"[Вкл/выкл] Окончания у трейсеров", elements.checkbox.cbEnd) then
                confq.config.cbEnd = elements.checkbox.cbEnd[0]
                save()
            end

            if imgui.SliderInt('##sizeTraicerEndTwo', elements.int.sizeOffPolygonTwo, 1, 10) then
                confq.config.sizeOffPolygonTwo = elements.int.sizeOffPolygonTwo[0]
                save()
            end imgui.SameLine() imgui.Text(u8"Размер окончания трейсера")

            if imgui.SliderInt('##endNumbersTwo', elements.int.polygonNumberTwo, 2, 10) then
                confq.config.polygonNumberTwo = elements.int.polygonNumberTwo[0] 
                save()
            end imgui.SameLine() imgui.Text(u8"Количество углов на окончаниях")

            if imgui.SliderInt('##rotationTwo', elements.int.rotationPolygonTwo, 0, 360) then
                confq.config.rotationPolygonTwo = elements.int.rotationPolygonTwo[0]
                save() 
            end imgui.SameLine() imgui.Text(u8"Градус поворота окончания")

            imgui.PopItemWidth()
            imgui.Separator()
            imgui.Text(u8"Укажите цвет трейсера, если игрок попал в: ")
            imgui.PushItemWidth(325)
            if imgui.ColorEdit4("———", color2) then
                confq.config.dinamicObject = imgui.ColorConvertFloat4ToU32(
                    imgui.ImVec4( color2[0], color2[1], color2[2], color2[3] )
                )
                
            end imgui.SameLine() imgui.Text(u8"Динамический объект")
            
            if imgui.ColorEdit4("————————————————————", color1) then
                confq.config.staticObject = imgui.ColorConvertFloat4ToU32(
                    imgui.ImVec4( color1[0], color1[1], color1[2], color1[3] )
                )
            end imgui.SameLine() imgui.Text(u8"Статический объект")
            
            if imgui.ColorEdit4("——————————————", color3) then
                confq.config.pedP = imgui.ColorConvertFloat4ToU32(
                    imgui.ImVec4( color3[0], color3[1], color3[2], color3[3] )
                )
            end imgui.SameLine() imgui.Text(u8"Игрока")

            if imgui.ColorEdit4("——", color4) then
                confq.config.carP = imgui.ColorConvertFloat4ToU32(
                    imgui.ImVec4( color4[0], color4[1], color4[2], color4[3] )
                )
            end imgui.SameLine() imgui.Text(u8"Машину")
            imgui.PopItemWidth()
            imgui.Separator()
        end
        if menuSelect == 505 then
            ad.AlignedText(u8'Раздача', 2)
            imgui.Combo(u8'Слово', massiv.razdacha,items.items.ImWords, #word)
            imgui.Combo(u8'Призы', massiv.razdacha_zapusk,items.items.prizeon, #prizeon)
            if imgui.InputText(u8'Введите ID победителя', massiv.text_buffer, 256) then
            end
            if imgui.Button(u8'Раздача') then
                sampSendChat('/aad РАЗДАЧА | Кто первый напишет в /rep' .. ' ' .. u8:decode(word[massiv.razdacha[0] + 1]) .. " тот получит " .. u8:decode(prizeon[massiv.razdacha_zapusk[0] + 1]))
            end
            imgui.SameLine()
            if imgui.Button(u8'Выдать') then
                sampSendChat('/aad РАЗДАЧА | ' .. ffi.string(massiv.text_buffer) .. ' WIN')
            end
            imgui.Separator()
            imgui.Text(u8'Примеры')
            math.randomseed(os.time())
            rand = math.random(1, 200)
            ral = math.random(1, 200)
            if imgui.Button(u8'Плюс') then
                sampSendChat('/aad Примеры | Кто первый решит пример ' .. rand .. '+' .. ral .. ' получит ' .. u8:decode(prizeon[massiv.razdacha_zapusk[0] + 1]))
            end
            imgui.SameLine()
            if imgui.Button(u8'Минус') then
                sampSendChat('/aad Примеры | Кто первый решит пример ' .. rand .. '-' .. ral .. ' получит ' .. u8:decode(prizeon[massiv.razdacha_zapusk[0] + 1]))
            end
            imgui.Separator()
            imgui.Text(u8'Авто-обьявление победителя')
            imgui.Text(u8"Обьявлять победителя автоматически")
            imgui.SameLine(250)
            ad.ToggleButton(u8'Раздача активна', massiv.toggle_toggle)
            imgui.Combo(u8'Ключевое слово для автовыдачи', massiv.slovo,items.items.ImWorks, #word)
        end
        if menuSelect == 122 then
            imgui.PushItemWidth(150)
            imgui.Combo(u8'Выберите приз', massiv.mep,items.items.prizemp, #prizemp)
            imgui.PushItemWidth(150)
            imgui.Combo(u8'Выберите мероприятие', massiv.mepo,items.items.prizemep, #prizemep)
            if imgui.Button(u8'Запустить', imgui.ImVec2(150, 50)) then
                lua_thread.create(function()
                    sampSendChat('/aad MP | Уважаемые игроки, сейчас пройдёт мероприятие ' .. u8:decode(prizemep[massiv.mepo[0] + 1]))
                    wait(1000)
                    sampSendChat('/aad MP | Приз: ' .. u8:decode(prizemp[mep[0] + 1]) .. '!')
                    wait(1000)
                    sampSendChat('/aad MP | Желающие /gomp!')
                    wait(1000)
                    sampSendChat('/mp')
                end)
            end
            imgui.Separator()
            if imgui.CollapsingHeader(u8'Кастомный выбор') then
                imgui.InputText(u8'Кастомное мероприятие', tableOfNew.svoemp, 256)
                if imgui.Button(u8'Запустить свое мероприятие', imgui.ImVec2(200, 50)) then
                    lua_thread.create(function()
                        sampSendChat('/aad MP | Уважаемые игроки, сейчас пройдёт мероприятие ' .. u8:decode(ffi.string(tableOfNew.svoemp)))
                        wait(1000)
                        sampSendChat('/aad MP | Приз: ' .. u8:decode(prizemp[massiv.mep[0] + 1]) .. '!')
                        wait(1000)
                        sampSendChat('/aad MP | Желающие /gomp!')
                        wait(1000)
                        sampSendChat('/mp')
                    end)
                end
                imgui.TextWrapped(u8"Обратите внимание! Выбор не полностью кастомный!\nВыбирайте либо свое мероприятие либо свой приз")
                imgui.InputText(u8'Кастомный приз', massiv.texter, 256)
                if imgui.Button(u8'Запустить со своим призом', imgui.ImVec2(200, 50)) then
                    lua_thread.create(function()
                        sampSendChat('/aad MP | Уважаемые игроки, сейчас пройдёт мероприятие ' .. u8:decode(prizemep[massiv.mepo[0] + 1]))
                        wait(1000)
                        sampSendChat('/aad MP | Приз: ' .. u8:decode(ffi.string(massiv.texter)) .. '!')
                        wait(1000)
                        sampSendChat('/aad MP | Желающие /gomp!')
                        wait(1000)
                        sampSendChat('/mp')
                    end)
                end
            end
        end
        if menuSelect == 8 then
            imgui.SetWindowFontScale(1.1)
            imgui.Text(u8"Создать оружие:")
            imgui.SetWindowFontScale(1.0)
            imgui.Separator()
            imgui.Text(u8'Выберите оружие:')
            imgui.PushItemWidth(142)
            if imgui.Combo("##gunCreateFov", tableOfNew.numberGunCreate,items.items.arrGuns, #arrGuns) then
            end
            imgui.PopItemWidth()
            imgui.Text(u8'Выберите количество патронов:')
            imgui.SliderInt('##numberAmmo', massiv.numberAmmo, 1, 999)
            if imgui.Button(u8'Создать', imgui.ImVec2(100, 22)) then
                sampSendChat('/givegun '..getMyId()..' '..tableOfNew.numberGunCreate[0]..' '..massiv.numberAmmo[0])
            end
            imgui.Separator()
            imgui.SetWindowFontScale(1.1)
            imgui.Text(u8"Частоиспользуемое оружие:")
            imgui.SetWindowFontScale(1.0)
            for k,v in pairs(allGunsP) do
                if imgui.Button(u8(v), imgui.ImVec2(100, 0)) then
                    sampSendChat('/givegun '..getMyId()..' '..k..' '..massiv.numberAmmo[0])
                end imgui.SameLine()
            end
            imgui.NewLine()
            imgui.Separator()
        end
        if menuSelect == 3 then
            helloText1 = [[
                1. Новые стили
                2. Новый авто-репорт
                3. Новый TAB
                4. Новое меню рекона
                5. Исправлены баги
                6. Отпимизация
            ]]
            imgui.BeginChild('Новое обновление', imgui.ImVec2(490, 33), true)
            imgui.Text('                                      ')
            imgui.SameLine()
            imgui.PushFont(fsClock)
            imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), u8'Что в новом обновлении?')
            imgui.PopFont()
            imgui.EndChild()
            imgui.Text(u8(helloText1))
            if imgui.Button(u8'Команда Tool', imgui.ImVec2(490, 100)) then
                os.execute('explorer https://vk.com/02and04')
            end
        end
        if menuSelect == 49 then
            if ad.HeaderButton(menuSelect == 492, u8"Страница 1/2") then
                menuSelect = 492
            end
            imgui.SameLine()
            if ad.HeaderButton(menuSelect == 49, u8"Страница 2/2") then
                menuSelect = 49
            end
            imgui.BeginChild('##newchild', imgui.ImVec2(500, 500), true)
            if true then
                if imgui.Button(u8'INFERNO | Группа Проетка', imgui.ImVec2(350, 20)) then
                    os.execute('start ' .. 'https://vk.com/gta_inferno')
                end
                imgui.Separator()
                if imgui.Button(u8'PRIDE | Правила Администрации', imgui.ImVec2(350, 20)) then
                    os.execute('start ' .. 'https://vk.com/topic-219468725_49272153')
                end
                imgui.Separator()
                if imgui.Button(u8'ENVY | Правила Администрации', imgui.ImVec2(350, 20)) then
                    os.execute('start' .. 'https://vk.com/topic-221245909_49355189')
                end
                imgui.Separator()
                if imgui.Button(u8'PRIDE | Повышение административного состава', imgui.ImVec2(350, 20)) then
                    os.execute('start https://vk.com/topic-219468725_49272155')
                end
                imgui.Separator()
                if imgui.Button(u8'ENVY | Повышение административного состава', imgui.ImVec2(350, 20)) then
                    os.execute('start https://vk.com/topic-221245909_49355236')
                end
                imgui.Separator()
                if imgui.Button(u8'PRIDE | Система отпускных дней', imgui.ImVec2(350, 20)) then
                    os.execute('start https://vk.com/topic-219468725_49272144')
                end
                imgui.Separator()
                if imgui.Button(u8'ENVY | Система отпускных дней', imgui.ImVec2(350, 20)) then
                    os.execute('start https://vk.com/topic-221245909_49355225')
                end
                imgui.Separator()
                if imgui.Button(u8'PRIDE | Жалобы на администрацию', imgui.ImVec2(350, 20)) then
                    os.execute('start https://vk.com/topic-219468725_49272154')
                end
                imgui.Separator()
                if imgui.Button(u8'ENVY | Жалобы на администрацию', imgui.ImVec2(350, 20)) then
                    os.execute('start https://vk.com/topic-221245909_49355222')
                end
                imgui.Separator()
                if imgui.Button(u8'INFERNO | Свободная Группа', imgui.ImVec2(350, 20)) then
                    os.execute('start https://vk.com/inferno_sv')
                end
                imgui.EndChild()
            end
        end
        if menuSelect == 492 then
            if ad.HeaderButton(menuSelect == 492, u8"Страница 1/2") then
                menuSelect = 492
            end
            imgui.SameLine()
            if ad.HeaderButton(menuSelect == 49, u8"Страница 2/2") then
                menuSelect = 49
            end
            if imgui.Button(fa.ICON_FA_MICROCHIP .. u8' ВК Разработчика', imgui.ImVec2(250, 20)) then
                os.execute('explorer ' .. 'https://vk.com/guninik')
            end
            imgui.Separator()
            if imgui.Button(fa.ICON_FA_ROCKET .. u8' IN | Отзывы', imgui.ImVec2(250, 20)) then
                os.execute('explorer ' .. 'https://vk.com/topic-221279621_50027952')
            end
            if imgui.Button(fa.ICON_FA_THUMBS_UP .. u8' IN | Пожелания игроков', imgui.ImVec2(250, 20)) then
                os.execute('explorer ' .. 'https://vk.com/topic-221279621_50028063')
            end
            if imgui.Button(fa.ICON_FA_FILE_CODE .. u8' IN | Баги и Недоработки', imgui.ImVec2(250, 20)) then
                os.execute('explorer ' .. 'https://vk.com/topic-221279621_50027951')
            end
        end
        if menuSelect == 1 then
            local tt = 0
            imgui.SetWindowFontScale(1.1)
            imgui.Text(u8"Создать транспорт:")
            imgui.SetWindowFontScale(1.0)
            imgui.Separator()
            imgui.Columns(3, _, false)
            imgui.Text(u8"Выберите транспорт:")
            imgui.PushItemWidth(142)
            if imgui.Combo("##car", tableOfNew.intComboCar,items.items.tCarsName, #tCarsName) then
            end
            imgui.PopItemWidth()
            if imgui.Button(u8"Создать", imgui.ImVec2(141, 22)) then
                sampSendChat("/veh " .. tableOfNew.intComboCar[0] + 400 .. " 1 1 1")
            end
            imgui.NextColumn()
            imgui.Text(u8"Выберите цвет:")
            imgui.AlignTextToFramePadding()
            imgui.Text("#1"); imgui.SameLine();
            imgui.PushItemWidth(80)
            if imgui.InputText("##carColor1", tableOfNew.carColor1, 256) then
            end
            imgui.PopItemWidth()
            imgui.AlignTextToFramePadding()
            imgui.Text("#2"); imgui.SameLine();
            imgui.PushItemWidth(80)
            if imgui.InputText("##carColor2", tableOfNew.carColor2, 256) then 
            end
            imgui.PopItemWidth()
            imgui.NextColumn()
            imgui.Text(u8("ID: " .. tableOfNew.intComboCar[0] + 400))
            imgui.Text(u8("Транспорт: " .. tCarsName[tableOfNew.intComboCar[0] + 1]))
            local carId = tableOfNew.intComboCar[0] + 1
            local type = tCarsType[carId]
            imgui.Text(u8("Тип: " .. tCarsTypeName[type]))
            --imgui.PopStyleVar()
            imgui.Columns(1)
            imgui.Separator()
            imgui.SetWindowFontScale(1.1)
            imgui.Text(u8"Частоиспользуемые машины:")
            imgui.SetWindowFontScale(1.0)
            imgui.Separator()
            for k, v in pairs(allCarsP) do
                tt = tt + 1
                if imgui.Button(u8(v), imgui.ImVec2(100, 0)) then
                    sampSendChat('/veh '..k..' '..(ffi.string(tableOfNew.carColor1))..' '..(ffi.string(tableOfNew.carColor2))..' 1')
                end imgui.SameLine()
                if tt == 4 then
                    imgui.NewLine()
                end
            end
            imgui.NewLine()
			imgui.BeginChild('##createCar', imgui.ImVec2(463, 300), true)
			imgui.PushItemWidth(250)
            imgui.InputText('Search',tableOfNew.findText,256)
            for k,v in pairs(tCarsName) do
                if u8(v):find(ffi.string(tableOfNew.findText)) then
                    if imgui.Button(u8(v)) then
                        sampSendChat('/veh ' .. k + 400 - 1 .. ' ' ..(ffi.string(tableOfNew.carColor1))..' '..(ffi.string(tableOfNew.carColor2)).." 1")
                    end
                end
            end
			imgui.PopItemWidth()
			imgui.Separator()
			for k,v in pairs(tCarsName) do
				if tableOfNew.findText[0] ~= '' then
					if string.rlower(v):find(string.rlower(u8:decode(tableOfNew.findText[0]))) then 
						if imgui.Button(u8(v)) then
							sampSendChat('/veh '.. k + 400 - 1 ..' '..(ffi.string(tableOfNew.carColor1))..' '..(ffi.string(tableOfNew.carColor2)).." 1")
						end
					end
				end
            end
			imgui.EndChild()
			imgui.Separator()
        end
        if menuSelect == 0 then
            if ad.ToggleButton(u8'RECON меню', tableOfNew.reconmenu) then
                confq.config.recon = tableOfNew.reconmenu[0]
                save()
            end
            if imgui.Button(fa.ICON_FA_KEY..u8' Изменить местоположение KeyLogger', imgui.ImVec2(250, 25)) then
                lua_thread.create(function()
                    checkCursor = true
                    tool[0] = false
                    sampSetCursorMode(4)
                    sampAddChatMessage('{FF00FF}'..'Нажмите {0087FF}SPACE{FFFFFF} что-бы сохранить позицию')
                    while checkCursor do
                        local cX, cY = getCursorPos()
                        tableOfNew.poskey.x, tableOfNew.poskey.y = cX, cY
                        if isKeyDown(32) then
                            sampSetCursorMode(0)
                            confq.poskey.x, confq.poskey.y = cX, cY
                            checkCursor = false
                            tool[0] = true
                            sampAddChatMessage('Новое местоположение успешно установлено!', -1)
                            save()
                        end
                        wait(0)
                    end
                end)
            end
        end
        if menuSelect == 2 then
            if not massiv.PC[0] then
                imgui.Image(setting1, imgui.ImVec2(495, 100))
            end
            if imgui.CollapsingHeader(u8'Чит-меню') then
                imgui.BeginChild('##menucheat', imgui.ImVec2(495, 200), true)
                if ad.ToggleButton(u8'[ON/OFF] GM Car', elements.checkbox.gmCar) then
                    confq.config.gmCar = elements.checkbox.gmCar[0]
                    save()
                end
                if ad.ToggleButton(u8"[Вкл/выкл] Трейсер пуль", elements.checkbox.bulletTracer) then
                    confq.config.bulletTracer = elements.checkbox.bulletTracer[0]
                    save()
                end imgui.SameLine() imgui.HelpMarker(u8"Рендерит траекторию пули") imgui.SameLine() if imgui.Button(u8'Настроить', imgui.ImVec2(70, 0)) then menuSelect = 333 end 
                if ad.ToggleButton(u8'[ON/OFF] SpeedHack', elements.checkbox.speedHack) then
                    confq.config.speedHack = elements.checkbox.speedHack[0]
                    save()
                end
                imgui.SameLine()
                imgui.HelpMarker(u8'С помощью кнопки ALT вы можете ускоряться')

                if ad.ToggleButton(u8'[ON/OFF] noBike', elements.checkbox.noBike) then
                    confq.config.noBike = elements.checkbox.noBike[0]
                    save()
                end
                if ad.ToggleButton(u8"[ON/OFF] AirBrake", elements.checkbox.airBrake) then
                    confq.config.airBrake = elements.checkbox.airBrake[0]
                    save()
                end imgui.SameLine() imgui.HelpMarker(u8"Быстрое перемещение, которое активируется на нажитие клавиша RSHIFT, регулируется при помощи + и -")
                if ad.ToggleButton('WallHack', items.bool.wallhack) then
                    confq.config.wallhack = items.bool.wallhack[0]
                    save()
                end imgui.SameLine() imgui.HelpMarker(u8'Возможность видеть скелет и ник сквозь стены')
                imgui.EndChild()
                imgui.Separator()
            end
            if imgui.CollapsingHeader(u8"Сокращенные команды") then
                imgui.SetWindowFontScale(1.1)
                imgui.Text(u8"Выберите команду")
                imgui.SetWindowFontScale(1.0)
                imgui.Separator()
                if ad.ToggleButton('[ON/OFF] DM', items.sorkcomm.dm) then
                    confq.sorkcomm.dm = items.sorkcomm.dm[0]
                    save()
                end
                if ad.ToggleButton('[ON/OFF] SK', items.sorkcomm.sk) then
                    confq.sorkcomm.sk = items.sorkcomm.sk[0]
                    save()
                end
                if ad.ToggleButton('[ON/OFF] TK', items.sorkcomm.tk) then
                    confq.sorkcomm.tk = items.sorkcomm.tk[0]
                    save()
                end
                if ad.ToggleButton('[ON/OFF] Cheat[/ch]', items.sorkcomm.ch) then
                    confq.sorkcomm.ch = items.sorkcomm.ch[0]
                    save()
                end
                if ad.ToggleButton('[ON/OFF] NRP', items.sorkcomm.nrp) then
                    confq.sorkcomm.nrp = items.sorkcomm.nrp[0]
                    save()
                end
                if ad.ToggleButton('[ON/OFF] O.A[/osk]', items.sorkcomm.osk) then
                    confq.sorkcomm.osk = items.sorkcomm.osk[0]
                    save()
                end
                if ad.ToggleButton('[ON/OFF] O.R[/orp]', items.sorkcomm.orp) then
                    confq.sorkcomm.orp = items.sorkcomm.orp[0]
                    save()
                end
                if ad.ToggleButton('[ON/OFF] Vred', items.sorkcomm.vred) then
                    confq.sorkcomm.vred = items.sorkcomm.vred[0]
                    save()
                end
            end
            imgui.PushItemWidth(120)
            if imgui.Combo(u8'Выберите звук', tableOfNew.item_sounds,items.items.item_sound, #item_sound) then
                confq.config.item_sounds = tableOfNew.item_sounds[0]
                save()
            end
            if imgui.Combo(u8'Выберите тему', tableOfNew.selected_itom,items.items.item_theme, #item_theme) then
                confq.config.radios = tableOfNew.selected_itom[0]
                if tableOfNew.selected_itom[0] == 0 then
                    imgui.thememoonmonet(0.5, true)
                elseif tableOfNew.selected_itom[0] == 1 then
                    imgui.thememoonpurple(0.6, true)
                elseif tableOfNew.selected_itom[0] == 2 then
                    imgui.themoongreen(1, true)
                elseif tableOfNew.selected_itom[0] == 3 then
                    imgui.themoonred(1, true)
                elseif tableOfNew.selected_itom[0] == 4 then
                    imgui.themoonyellow(1, true)
                end
                save()
            end
            imgui.Spacing()
            imgui.BeginChild('##none', imgui.ImVec2(-1, -1), true)
                if ad.ToggleButton(u8'[ON/OFF] Звук при репорте', massiv.imBitch) then
                    confq.config.napom = massiv.imBitch[0]
                    save()
                end
                if ad.ToggleButton(u8'[ON/OFF] Слабый ПК', massiv.PC) then
                    confq.config.PC = massiv.PC[0]
                    save()
                end
                if ad.ToggleButton(u8"[ON/OFF] /slap + sp", massiv.imBitche) then
                    confq.config.sp = massiv.imBitche[0]
                    save()
                end
                if ad.ToggleButton(u8"[ON/OFF] /car ID", massiv.imCarrot) then
                    confq.config.carrot = massiv.imCarrot[0]
                    save()
                end
                if massiv.imCarrot[0] then
                    imgui.Text(u8'Выберите машину которую хотите выдать: ')
                    imgui.SameLine()
                    imgui.PushItemWidth(120)
                    if imgui.Combo(u8'##Бан блять', tableOfNew.selectedd_item,items.items.selectedd_item, #selectedd_item) then
                        confq.config.radios2 = tableOfNew.selectedd_item[0]
                        save()
                    end
                end
                if ad.ToggleButton(u8"[ON/OFF] ReactWarning", massiv.imCarco) then
                    confq.config.imCarco = massiv.imCarco[0]
                    save()
                end
                if ad.ToggleButton(u8"[ON/OFF] Радар в реконе", massiv.imCarcos) then
                    confq.config.imCarcos = massiv.imCarcos[0]
                    save()
                    sampAddChatMessage('{FF0000}[InTool] {FFFFFF}Чтобы выключить - сделайте перезагрузку игры')
                end
                if ad.ToggleButton(u8"[ON/OFF] Анти-транслит", massiv.retrans) then
                    confq.config.retrans = massiv.retrans[0]
                    save()
                end
                if ad.ToggleButton(u8("Новое меню TAB"), tableOfNew.menutab) then
                    confq.config.menutab = tableOfNew.menutab[0]
                    save()
                end
                if ad.ToggleButton(u8"[Вкл/выкл] Авто-вход как администратор", elements.checkbox.autoCome) then
                    confq.config.autoCome = elements.checkbox.autoCome[0]
                    save()
                end imgui.SameLine() imgui.HelpMarker(u8"Не надо вводить админ-пароль самому, скрипт сделает это за вас")
                if elements.checkbox.autoCome[0] then
                    imgui.Text(u8"Введите админ-пароль: ") imgui.SameLine() imgui.PushItemWidth(100)
                    if imgui.InputText("##adminPassword", elements.checkbox.adminPassword, 256) then
                        confq.config.adminPassword = u8:decode(ffi.string(elements.checkbox.adminPassword))
                        save()
                        sampAddChatMessage(ffi.string(elements.checkbox.adminPassword))
                    end
                end
            imgui.EndChild()
        end
        if menuSelect == 2222 then
            if not top3 then
                menuSelect = 0
                sampAddChatMessage('[INTool] Ошибка! Сервер не прислал данных :(', -1)
            else
                imgui.BeginChild(u8'Лидеры недели', imgui.ImVec2(480, 360), true)
                    imgui.PushFont(fsClock) imgui.CenterTextColoredRGB('                          Лучшие администраторы') imgui.PopFont()
                    local clr = imgui.Col
                    if ad.HeaderButton(menuSelect == 2222, u8"ALL Servers") then
                        menuSelect = 2222
                    end
                    imgui.SameLine()
                    if ad.HeaderButton(menuSelect == 2223, u8"Pride") then
                        menuSelect = 2223
                    end
                    imgui.BeginChild('##123', imgui.ImVec2(457, 300), true)
                        imgui.PushStyleColor(clr.Separator, imgui.ImVec4(0.0, 0.00, 0.00, 1))
                        imgui.PushStyleColor(clr.SeparatorActive, imgui.ImVec4(0.0, 0.00, 0.00, 1))
                        imgui.PushStyleColor(clr.SeparatorHovered, imgui.ImVec4(0.0, 0.00, 0.00, 1))
                        imgui.Columns(6)
                        imgui.SetColumnWidth(-1, 100); imgui.PushFont(font[20]); imgui.CenterColumnText('NICKNAME'); imgui.PopFont(); imgui.NextColumn()
                        imgui.SetColumnWidth(-1, 70); imgui.PushFont(font[20]); imgui.CenterColumnText('REPORTS'); imgui.PopFont(); imgui.NextColumn()
                        imgui.SetColumnWidth(-1, 70); imgui.PushFont(font[20]); imgui.CenterColumnText(u8'JAILS'); imgui.PopFont(); imgui.NextColumn()
                        imgui.SetColumnWidth(-1, 70); imgui.PushFont(font[20]); imgui.CenterColumnText(u8'BANS'); imgui.PopFont(); imgui.NextColumn()
                        imgui.SetColumnWidth(-1, 70); imgui.PushFont(font[20]); imgui.CenterColumnText(u8'MUTES'); imgui.PopFont(); imgui.NextColumn()
                        imgui.SetColumnWidth(-1, 70); imgui.PushFont(font[20]); imgui.CenterColumnText(u8'TOP'); imgui.PopFont(); imgui.NextColumn()
                        showTop()
                        imgui.Columns(1); imgui.Separator()
                        imgui.PushItemWidth(100)
                        local nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
                        imgui.Columns(6)
                        for i, player in ipairs(top3) do
                            if player.nickName == nick then
                                imgui.SetColumnWidth(-1, 100); imgui.PushFont(font[12]); imgui.CenterColumnText(u8'Вы('..player.nickName..')'); imgui.PopFont(); imgui.NextColumn()
                                imgui.SetColumnWidth(-1, 70); imgui.PushFont(font[25]); imgui.CenterColumnText(player.reports); imgui.PopFont(); imgui.NextColumn()
                                imgui.SetColumnWidth(-1, 70); imgui.PushFont(font[25]); imgui.CenterColumnText(player.jails); imgui.PopFont(); imgui.NextColumn()
                                imgui.SetColumnWidth(-1, 70); imgui.PushFont(font[25]); imgui.CenterColumnText(player.bans); imgui.PopFont(); imgui.NextColumn()
                                imgui.SetColumnWidth(-1, 70); imgui.PushFont(font[25]); imgui.CenterColumnText(player.mutes); imgui.PopFont(); imgui.NextColumn()
                                imgui.SetColumnWidth(-1, 70); imgui.PushFont(font[25]); imgui.CenterColumnText(tostring(i)); imgui.PopFont(); imgui.NextColumn()
                                break
                            end
                        end
                        imgui.Columns(1); imgui.Separator()
                        imgui.PopStyleColor(3)
                        imgui.Text(u8'Сортировать по: ') imgui.SameLine() if imgui.Combo(u8'##', massiv.arraynew,items.items.arraynew, #arraynew) then sortby(massiv.arraynew[0]) end
                        imgui.Text(u8'Дата:') imgui.SameLine() if imgui.Combo('##суканахуйблять', massiv.date, items.items.arrayDate, #arrayDate) then end
                        imgui.PopItemWidth()
                        imgui.SameLine()
                        if imgui.Button(u8'Обновить', imgui.ImVec2(100, 0)) then
                            getlist()
                        end
                    imgui.EndChild()
                imgui.EndChild()
                
            end
        end
        imgui.EndChild()
        imgui.End()
    end
)

function sumValuesForWeek(data)
    local result = {}

    for i, item in ipairs(data) do
        local totals = {
            mutesperweek = 0,
            reportsperweek = 0,
            bansperweek = 0,
            jailsperweek = 0,
        }

        for day = 1, 7 do
            totals.mutesperweek = totals.mutesperweek + tonumber(item["mutes_day" .. day] or 0)
            totals.reportsperweek = totals.reportsperweek + tonumber(item["reports_day" .. day] or 0)
            totals.bansperweek = totals.bansperweek + tonumber(item["bans_day" .. day] or 0)
            totals.jailsperweek = totals.jailsperweek + tonumber(item["jails_day" .. day] or 0)
        end

        table.insert(result, {
            nickName = item.nickName,
            totals = totals
        })
    end

    return result
end

function sortby(int)
    if top3 == nil then
        return
    end
    if int == 0 then
        -- Сортировка по количеству репортов (по возрастанию)
        table.sort(top3, function(a, b)
            return tonumber(a.reports) > tonumber(b.reports)
        end)
    elseif int == 1 then
        -- Сортировка по количеству jails (по возрастанию)
        table.sort(top3, function(a, b)
            return tonumber(a.jails) > tonumber(b.jails)
        end)
    elseif int == 2 then
        -- Сортировка по количеству mutes (по возрастанию)
        table.sort(top3, function(a, b)
            return tonumber(a.mutes) > tonumber(b.mutes)
        end)
    elseif int == 3 then
        -- Сортировка по количеству bans (по возрастанию)
        table.sort(top3, function(a, b)
            return tonumber(a.bans) > tonumber(b.bans)
        end)
    end
end


function coloredtop(topi)
    local clr = imgui.Col
    if topi == 1 then
        imgui.PushStyleColor(clr.Text, imgui.ImVec4(0.952, 0.878, 0.005, 1))
        imgui.CenterColumnText(tostring(topi))
        imgui.PopStyleColor()
    elseif topi == 2 then
        imgui.PushStyleColor(clr.Text, imgui.ImVec4(0.597, 0.557, 0.509, 1))
        imgui.CenterColumnText(tostring(topi))
        imgui.PopStyleColor()
    elseif topi == 3 then
        imgui.PushStyleColor(clr.Text, imgui.ImVec4(0.758, 0.446, 0.079, 1))
        imgui.CenterColumnText(tostring(topi))
        imgui.PopStyleColor()
    else
        imgui.CenterColumnText(tostring(topi))
    end
end


function comparePlayersByReports(player1, player2)
    return tonumber(player1.reports) > tonumber(player2.reports)
end

function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

local inputField = imgui.new.char[256]()
imgui.OnFrame(function() return checkbox.statistics.renderTAB[0] end,
    function(player)
		imgui.GetStyle().ScrollbarSize = 10
		imgui.GetStyle().FrameRounding = 20.0
		imgui.SetNextWindowPos(imgui.ImVec2(ex / 2, ey / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(800, 573), imgui.Cond.FirstUseEver)
		imgui.Begin("##Begin", checkbox.statistics.renderTAB, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove )
		
		imgui.Text(u8'Игроков на сервере: '..sampGetPlayerCount(false)) 
		imgui.SameLine()
		imgui.CenterText(u8(sampGetCurrentServerName()))	
		imgui.SameLine()
		imgui.SetCursorPosX( imgui.GetWindowWidth() - 151)
		imgui.PushItemWidth(110)
		imgui.GetStyle().FrameRounding = 3.0
		imgui.InputTextWithHint(u8'', u8'Поиск по ID/нику', inputField, 256)
		imgui.SameLine()
		imgui.SetCursorPosX( imgui.GetWindowWidth() - 35.85)
		imgui.Columns(5, _, false)
		imgui.Separator()
		imgui.SetColumnWidth(-1, 55) imgui.CenterColumnText('ID') imgui.NextColumn()
		imgui.SetColumnWidth(-1, 548) imgui.CenterColumnText('Nickname') imgui.NextColumn()
		imgui.SetColumnWidth(-1, 65	) imgui.CenterColumnText('Score') imgui.NextColumn()
		imgui.SetColumnWidth(-1, 65) imgui.CenterColumnText('Ping') imgui.NextColumn()
		imgui.SetColumnWidth(-1, 65) imgui.CenterColumnText('Action') imgui.NextColumn()
	
		if u8:decode(ffi.string(inputField)) == "" then
			imgui.Separator()
			local my_id = select(2,sampGetPlayerIdByCharHandle(playerPed))
			drawScoreboardPlayer(my_id)
			for id = 0, sampGetMaxPlayerId(false) do
				if my_id ~= id and sampIsPlayerConnected(id) then
					imgui.Separator()
					drawScoreboardPlayer(id)
				end
			end
		else 	
			for idd = 0, sampGetMaxPlayerId(false) do
				if sampIsPlayerConnected(idd) then
					if tostring(idd):find(ffi.string(inputField)) or string.rlower(sampGetPlayerNickname(idd)):find(string.rlower(u8:decode(ffi.string(inputField)))) then
						imgui.Separator()
						drawScoreboardPlayer(idd)
					end
				end
			end
		end
		
		imgui.NextColumn()
		imgui.End()
		
    end
)

function drawScoreboardPlayer(id)

	local nickname = sampGetPlayerNickname(id)
	local score = sampGetPlayerScore(id)
	local ping = sampGetPlayerPing(id)
	local color = sampGetPlayerColor(id)
	local r, g, b = bitex.bextract(color, 16, 8), bitex.bextract(color, 8, 8), bitex.bextract(color, 0, 8)
	local imgui_RGBA = imgui.ImVec4(r / 255.0, g / 255.0, b / 255.0, 1)
	
	
	imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(tostring(id)).x / 2)
	if true then 
		if score == 0 then
			imgui.Text(tostring(id))
		else
			imgui.TextColored(imgui_RGBA, tostring(id))
		end
	else
		imgui.Text(tostring(id))
	end
	imgui.NextColumn()
	
	
	if true then 
		if score == 0 then
			imgui.Text(" "..tostring(nickname)) imgui.SameLine() imgui.Text(u8"[Ещё не авторизовался]")
		else
			imgui.TextColored(imgui_RGBA, ' '..nickname)
		end
	else
		imgui.Text(' '..nickname)
	end
	imgui.NextColumn()	
	
	imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(tostring(score)).x / 2)
	if true then 
		if score == 0 then
			imgui.Text(tostring(score))
		else
			imgui.TextColored(imgui_RGBA, tostring(score))
		end
	else
		imgui.Text(tostring(score))
	end
	imgui.NextColumn()
	
	
	if true then
		if score == 0 then
			imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(tostring(0)).x / 2)
			imgui.Text("0")
		else
			imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(tostring(ping)).x / 2)
			if ping < 0 then
				imgui.TextColored(imgui.ImVec4(0,255,0,1), tostring(ping))
			elseif ping >= 0 and ping < 75 then
				imgui.TextColored(imgui.ImVec4(0,255,0,1), tostring(ping))
			elseif ping >= 75 and ping <= 150 then
				imgui.TextColored(imgui.ImVec4(238, 242, 0, 1), tostring(ping))
			elseif ping > 150 then
				imgui.TextColored(imgui.ImVec4(255,0,0,1), tostring(ping))
			end
		end
	else	
		imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(tostring(ping)).x / 2)
		imgui.Text(tostring(ping))
	end
	imgui.NextColumn()
	
	
	if imgui.Button(fa.ICON_FA_CAMERA_RETRO.."##"..id, imgui.ImVec2(22, 22.5)) then
		sampSendChat("/re "..id)
        checkbox.statistics.renderTAB[0] = false
	end
	if imgui.IsItemHovered() then
		imgui.SetTooltip(u8"Следить за "..nickname)
	end
	
	imgui.SameLine()
	
	if imgui.Button(fa.ICON_FA_COPY.."##"..id, imgui.ImVec2(22,22.5)) then
		setClipboardText(tostring(nickname))
	end
	if imgui.IsItemHovered() then
		imgui.SetTooltip(u8"Скопировать никнейм "..nickname..u8" в буфер обмена")
	end
	imgui.NextColumn()
	
end

imgui.OnFrame(function() return tableOfNew.windowcheck[0] end,
    function(player)
        local nick = sampGetPlayerNickname(speakid)
        imgui.SetNextWindowPos(imgui.ImVec2(ex / 2, ey / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(120, 200), imgui.Cond.Always)
        imgui.Begin('##null', tableOfNew.windowcheck, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoMove)
        imgui.TextDisabled(nick .. '[' .. speakid .. ']')
        imgui.Separator()
        if imgui.Button(u8'Проверить stats', imgui.ImVec2(110, 0)) then
            sampSendChat('/getstats ' .. speakid)
            tableOfNew.windowcheck[0] = false
        end
        if imgui.Button(u8'Начать следить', imgui.ImVec2(110, 0)) then
            sampSendChat('/re ' .. speakid)
            tableOfNew.windowcheck[0] = false
        end
        if imgui.Button(u8'Проверить offstats', imgui.ImVec2(110, 0)) then
            sampSendChat('/getoffstats ' .. nick)
            tableOfNew.windowcheck[0] = false
        end
        if imgui.Button(u8'Слапнуть', imgui.ImVec2(110, 0)) then
            sampSendChat('/slap ' .. speakid)
            tableOfNew.windowcheck[0] = false
        end
        if imgui.Button(u8'СП', imgui.ImVec2(110, 0)) then
            sampSendChat('/sp ' .. speakid)
            tableOfNew.windowcheck[0] = false
        end
        if imgui.Button(u8'Закрыть', imgui.ImVec2(110, 0)) then
            tableOfNew.windowcheck[0] = false
        end
        imgui.End()
    end
)

imgui.OnFrame(function() return tableOfNew.setstat[0] end,
    function(player)
        imgui.ShowCursor = true
        imgui.SetNextWindowPos(imgui.ImVec2(600, 100), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(600, 300), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'Меню выдачи призов', tableOfNew.setstat)
        imgui.BeginChild('##Secw', imgui.ImVec2(400, 240), true)
        imgui.Combo(u8'Выберите приз', massiv.setstatos,items.items.ImItems, #setstatis)
        imgui.Text(u8'Поле ниже обязательно должно быть заполнено!')
        imgui.InputText(u8'Введите ID победителя', massiv.idos, 256)
        imgui.InputText(u8'Введите значение', massiv.idoss, 256)
        if imgui.Button(u8'Выдать', imgui.ImVec2(120, 20)) then
            sampSendChat('/setstat ' .. ffi.string(massiv.idos)  .. ' ' ..tonumber(massiv.setstatos[0] + 1).. ' ' .. ffi.string(massiv.idoss))
        end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild('##any', imgui.ImVec2(150, 240), true)
        if imgui.Button(u8'Выдать 500kk', imgui.ImVec2(120, 20)) then
            sampSendChat('/money ' .. ffi.string(massiv.idos) .. ' 500000000')
        end
        if imgui.Button(u8'Выдать 1kkk', imgui.ImVec2(120, 20)) then
            sampSendChat('/money ' .. ffi.string(massiv.idos) .. ' 1000000000')
        end
        if imgui.Button(u8'Обьекты', imgui.ImVec2(120, 20)) then
            sampSendChat('/object ' .. ffi.string(massiv.idos))
        end
        imgui.EndChild()
        imgui.SameLine()
        imgui.End()
    end
)

imgui.OnFrame(function() return tableOfNew.third_window[0] end,
    function(player)
        local ToScreen = convertGameScreenCoordsToWindowScreenCoords
        local x, y = ToScreen(440, 0)
		local w, h = ToScreen(640, 448)
		imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(w-x, h), imgui.Cond.FirstUseEver)
		imgui.Begin(u8"##pensBar", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
		imgui.SetWindowFontScale(1.1)
		imgui.Text(u8"Таблица наказаний:")
		imgui.SetWindowFontScale(1.0)
		imgui.Separator()
		local _, hb = ToScreen(_, 416)
		imgui.BeginChild("##pens", imgui.ImVec2(w-x-2, hb))
        imgui.Columns(2, false)
		imgui.SetColumnWidth(-1, 255)
		imgui.Text(u8(pensTable))
		imgui.NextColumn()
		imgui.Text(u8(timesTable))
		imgui.Columns(1)
		imgui.EndChild()
		imgui.End()
    end
)


function to_vec4(u32)
    local a = bit.band(bit.rshift(u32, 24), 0xFF) / 0xFF
    local r = bit.band(bit.rshift(u32, 16), 0xFF) / 0xFF
    local g = bit.band(bit.rshift(u32, 8), 0xFF) / 0xFF
    local b = bit.band(u32, 0xFF) / 0xFF
    return imgui.ImVec4(r, g, b, a)
end

local colors_accent1, colors_accent2, colors_accent3, colors_neutral1, colors_neutral2 = {}, {}, {}, {}, {}

local function ARGBtoRGB(color) return bit.band(color, 0xFFFFFF) end


function ColorAccentsAdapter(color)
    local a, r, g, b = explode_argb(color)
    local c = {a = a, r = r, g = g, b = b}
    function c:apply_alpha(alpha) self.a = alpha return self end
    function c:as_u32() return join_argb(self.a, self.b, self.g, self.r) end
    function c:as_vec4() return imgui.ImVec4(self.r / 255, self.g / 255, self.b / 255, self.a / 255) end
    function c:as_argb() return join_argb(self.a, self.r, self.g, self.b) end
    function c:as_rgba() return join_argb(self.r, self.g, self.b, self.a) end
    function c:as_chat() return string.format('%06X', ARGBtoRGB(join_argb(self.a, self.r, self.g, self.b))) end
    return c
end

imgui.OnFrame(function() return tableOfNew.recon[0] end,
    function(player)
        if tableOfNew.reconmenu[0] then
            local ToScreen = convertGameScreenCoordsToWindowScreenCoords
            local isPed, pPed = sampGetCharHandleBySampPlayerId(rInfo.id)
            if sampIsPlayerConnected(rInfo.id) and rInfo.id ~= -1 and rInfo.state then
                local x, y = ToScreen(552, 230)
                local w, h = ToScreen(638, 330)
                if imgui.IsMouseClicked(1) then
                    player.HideCursor = not player.HideCursor
                end	
                local m, a = ToScreen(200, 410)
                imgui.SetNextWindowPos(imgui.ImVec2(m, a), imgui.Cond.Always)
                imgui.Begin(u8"##DownPanel", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)
                local bet = imgui.ImVec2(70, 0)
                imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(3.0, 2.5))
                if imgui.Button(u8'<< BACK', bet) then
                    if rInfo.id == 0 then
                        local onMaxId = sampGetMaxPlayerId(false)
                        if not sampIsPlayerConnected(onMaxId) or sampGetPlayerScore(onMaxId) == 0 or sampGetPlayerColor(onMaxId) == 16510045 then 
                            for i = sampGetMaxPlayerId(false), 0, -1 do
                                if sampIsPlayerConnected(i) and not sampIsPlayerNpc(i) and sampGetPlayerScore(i) > 0 and i ~= rInfo.id then                               
                                    sampSendChat('/re '..rInfo.id)
                                    break
                                end
                            end
                        else
                            sampSendChat('/re '..sampGetMaxPlayerId(false))
                        end
                    else 
                        for i = rInfo.id, 0, -1 do
                            if sampIsPlayerConnected(i) and sampGetPlayerScore(i) ~= 0 and sampGetPlayerColor(i) ~= 16510045 and not sampIsPlayerNpc(i) then
                                if i ~= tonumber(rInfo.id) then
                                    sampSendChat('/re '..i)
                                    break
                                end
                            end
                        end
                    end
                end imgui.SameLine()
                if imgui.Button(u8'/getstats', bet) then
                    sampSendChat('/getstats '..rInfo.id)
                end imgui.SameLine()
                if imgui.Button(u8'/getoffstats', bet) then
                    sampSendChat('/getoffstats '..sampGetPlayerNickname(rInfo.id))
                end imgui.SameLine()
                if imgui.Button(u8'/slap', bet) then
                    sampSendChat('/slap '..rInfo.id)
                end imgui.SameLine()
                if imgui.Button(u8'/freeze', bet) then
                    sampSendChat('/freeze '..rInfo.id)
                end imgui.SameLine()
                if imgui.Button(u8'/unfreeze', bet) then
                    sampSendChat('/unfreeze '..rInfo.id)
                end imgui.SameLine()
                if imgui.Button(u8'NEXT >>', bet) then
                    if rInfo.id == sampGetMaxPlayerId(false) then
                        if not sampIsPlayerConnected(0) or sampGetPlayerScore(0) == 0 or sampGetPlayerColor(0) == 16510045 then
                            for i = rInfo.id, sampGetMaxPlayerId(false) do 
                                if sampIsPlayerConnected(i) and sampGetPlayerScore(i) > 0 and i ~= rInfo.id and not sampIsPlayerNpc(i) then
                                    if i ~= tonumber(rInfo.id) then
                                        sampSendChat('/re '..i)
                                        break
                                    end
                                end
                            end
                        else
                            sampSendChat('/re 0')
                        end 
                    else 
                        for i = rInfo.id, sampGetMaxPlayerId(false) do 
                            if sampIsPlayerConnected(i) and sampGetPlayerScore(i) > 0 and i ~= rInfo.id and not sampIsPlayerNpc(i) then
                                if i ~= tonumber(rInfo.id) then
                                    sampSendChat('/re '..i)
                                    break
                                end
                            end
                        end
                    end
                end
                if imgui.Button(u8'/goto', bet) then
                    lua_thread.create(function()
                        sampSendChat('/re off')
                        wait(1000)
                        sampSendChat('/goto '..rInfo.id)
                    end)
                end	imgui.SameLine()
                if imgui.Button(u8'AZ', bet) then
                    lua_thread.create(function()
                        AzId = rInfo.id
                        sampSendChat('/re off')
                        wait(1000)
                        sampSendChat('/tp')
                        wait(100)
                        sampSendDialogResponse(sampGetCurrentDialogId(), 1, 0, nil)
                        sampCloseCurrentDialogWithButton(0)
                        wait(1000)
                        sampSendChat('/gethere '..AzId)
                    end)
                end imgui.SameLine()
                if imgui.Button(u8'ТП на дорогу', bet) then
                    lua_thread.create(function()
                        local function getNearestRoadCoordinates(radius)
                            local A = { getCharCoordinates(PLAYER_PED) }
                            local B = { getClosestStraightRoad(A[1], A[2], A[3], 0, radius or 600) }
                            if B[1] ~= 0 and B[2] ~= 0 and B[3] ~= 0 then
                                return true, B[1], B[2], B[3]
                            end
                            return false
                        end
                        local res, x, y, z = getNearestRoadCoordinates(1500)
                        if res then
                            rInfo.command = '/gethere '..rInfo.id
                            rInfo.position = {
                                x = x,
                                y = y,
                                z = z+2,
                            }
                            rInfo.process_teleport = true
                        else
                            sampAddChatMessage('Я не могу найти дорогу поблизости!', -1)
                        end
                    end)
                end imgui.SameLine()
                if imgui.Button(u8'/sethp', bet) then
                    imgui.OpenPopup(u8"Выдача жизней")
                end imgui.SameLine()
                if imgui.Button(u8'Машина', bet) then
                    imgui.OpenPopup(u8"Выдать машину")
                end imgui.SameLine()
                if imgui.Button(u8'Оружие', bet) then
                    imgui.OpenPopup(u8'Выберите оружие')
                end imgui.SameLine()
                if imgui.Button(u8'/uval', bet) then
                    sampSetChatInputEnabled(true)
                    sampSetChatInputText('/uval '..rInfo.id..' ')
                end
                if imgui.BeginPopupModal(u8"Выдача жизней", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
                    imgui.Text(u8'Выберите, сколько выдать ХП')
                    imgui.PushItemWidth(175) imgui.SliderInt('##giveHpSlider', tableOfNew.givehp, 0, 100) imgui.PopItemWidth()
                    if imgui.Button(u8'Выдать жизни', imgui.ImVec2(175, 0)) then
                        sampSendChat('/sethp '..rInfo.id..' '..tableOfNew.givehp[0])
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Закрыть', imgui.ImVec2(175, 0)) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
                if imgui.BeginPopupModal(u8"Выдать машину", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
                    imgui.Text(u8"Выберите транспорт:")
                    imgui.PushItemWidth(142)
                    imgui.Combo("##createiscarrecon", tableOfNew.intComboCar,items.items.tCarsName, #tCarsName)
                    imgui.PopItemWidth()
                    if imgui.Button(u8"Создать", imgui.ImVec2(175, 0)) then
                        sampSendChat("/veh " .. tableOfNew.intComboCar[0] + 400 .. " 1 1 1")
                    end
                    if imgui.Button(u8"Закрыть", imgui.ImVec2(175, 0)) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
                if imgui.BeginPopupModal(u8"Выберите оружие", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
                    imgui.Text(u8'Введите кол-во патрон')
                    imgui.InputText('##numbersAmmo', tableOfNew.inputAmmoBullets, 256)
                    imgui.Text(u8'Выберите оружие') 
                    imgui.Combo('##selecting', tableOfNew.selectGun, items.items.arrGuns, #arrGuns)
                    if imgui.Button(u8'Выдать', imgui.ImVec2(175, 0)) then
                        if ffi.string(tableOfNew.inputAmmoBullets) ~= '' then
                            sampSendChat('/givegun '..rInfo.id..' '..tonumber(tableOfNew.selectGun[0])..' '..ffi.string(tableOfNew.inputAmmoBullets))
                            imgui.CloseCurrentPopup()
                        else
                            sampAddChatMessage('{FF0000}[Ошибка] {FF8C00}Введите кол-во патрон.', stColor)
                        end
                    end
                    if imgui.Button(u8'Закрыть', imgui.ImVec2(175, 0)) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
                imgui.PopStyleVar()
                imgui.End()
                imgui.SetNextWindowPos(imgui.ImVec2(x, y - 150), imgui.Cond.FirstUseEver)
                imgui.SetNextWindowSize(imgui.ImVec2(137, 152), imgui.Cond.FirstUseEver)
                imgui.Begin(u8"Наказания", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
                if imgui.Button(u8'Выдать кик', imgui.ImVec2(120, 0)) then
                    imgui.OpenPopup(u8'Выдать кик')
                end
                if imgui.Button(u8'Выдать джайл', imgui.ImVec2(120, 0)) then
                    imgui.OpenPopup(u8'Выдать джайл')
                end
                if imgui.Button(u8'Выдать варн', imgui.ImVec2(120, 0)) then
                    imgui.OpenPopup(u8'Выдать варн')
                end
                if imgui.Button(u8'Выдать мут', imgui.ImVec2(120, 0)) then
                    imgui.OpenPopup(u8'Выдать мут')
                end
                if imgui.Button(u8'Выдать бан', imgui.ImVec2(120, 0)) then
                    imgui.OpenPopup(u8'Выдать бан')
                end	        
                if imgui.BeginPopupModal(u8"Выдать кик", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
                    bsize = imgui.ImVec2(130, 0)
                    if imgui.Button(u8'Своя причина', bsize) then
                        sampSetChatInputEnabled(true)
                        sampSetChatInputText('/kick '..rInfo.id..' ')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'AFK w/o esc', bsize) then
                        sampSendChat('/kick '..rInfo.id..' АФК без ESC')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Помеха', bsize) then
                        sampSendChat('/kick '..rInfo.id..' Помеха')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Закрыть', bsize) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
                if imgui.BeginPopupModal(u8"Выдать джайл", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
                    bsize = imgui.ImVec2(125, 0)
                    if imgui.Button(u8'Своя причина', bsize) then
                        sampSetChatInputEnabled(true)
                        sampSetChatInputText('/jail '..rInfo.id..' ')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'ДМ', bsize) then
                        sampSendChat('/jail '..rInfo.id..' 10 ДМ')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'БагоЮз', bsize) then
                        sampSendChat('/jail '..rInfo.id..' 15 БагоЮз')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'ДБ', bsize) then
                        sampSendChat('/jail '..rInfo.id..' 10 ДБ')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'ПГ', bsize) then
                        sampSendChat('/jail '..rInfo.id..' 5 ПГ')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'СК', bsize) then
                        sampSendChat('/jail '..rInfo.id..' 15 СК')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'ТК', bsize) then
                        sampSendChat('/jail '..rInfo.id..' 10 ТК')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Чит', bsize) then
                        sampSendChat('/jail '..rInfo.id..' 60 Чит')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Коп Гетто', bsize) then
                        sampSendChat('/sp '..rInfo.id..' 10 Коп в Гетто')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Чит во Фракции', bsize) then
                        lua_thread.create(function()
                            sampSendChat('/jail '..rInfo.id..' 30 Чит во фракции')
                            wait(1000)
                            sampSendChat('/uval '..rInfo.id..' Чит во фракции')
                            imgui.CloseCurrentPopup()
                        end)
                    end
                    if imgui.Button(u8'НРП', bsize) then
                        sampSendChat('/jail '..rInfo.id..' 10 НонРП')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'JetPack', bsize) then
                        sampSendChat('/jail '..rInfo.id..' 60 JetPack')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Закрыть', bsize) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
                if imgui.BeginPopupModal(u8"Выдать мут", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
                    bsize = imgui.ImVec2(150, 0)
                    if imgui.Button(u8'Своя причина', bsize) then
                        sampSetChatInputEnabled(true)
                        sampSetChatInputText('/mute '..rInfo.id..' ')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'МГ', bsize) then
                        sampSendChat('/mute '..rInfo.id..' 10 МГ')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Капс', bsize) then
                        sampSendChat('/mute '..rInfo.id..' 5 Капс')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Флуд', bsize) then
                        sampSendChat('/mute '..rInfo.id..' 10 Флуд')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Оск.Игроков', bsize) then
                        sampSendChat('/mute '..rInfo.id..' 20 Оскорбление игроков')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Оск. Адм', bsize) then
                        sampSendChat('/mute '..rInfo.id..' 20 Оскорбление Администрации')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Упом/Оск Род', bsize) then
                        sampSendChat('/mute '..rInfo.id..' 60 Упоминание/оскорбление родных')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Обман.Администрации', bsize) then
                        sampSendChat('/mute '..rInfo.id..' 25 Обман Администрации')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Транслит', bsize) then
                        sampSendChat('/mute '..rInfo.id..' 5 Транслит')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Закрыть', bsize) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
                if imgui.BeginPopupModal(u8"Выдать варн", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
                    bsize = imgui.ImVec2(175, 0)
                    if imgui.Button(u8'Своя причина', bsize) then
                        sampSetChatInputEnabled(true)
                        sampSetChatInputText('/warn '..rInfo.id..' ')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Отказ от проверки', bsize) then
                        sampSendChat('/warn '..rInfo.id..' Отказ от проверки')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Читы при проверке', bsize) then
                        sampSendChat('/warn '..rInfo.id..' Читы при проверке')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Чит Ghetto', bsize) then
                        sampSendChat('/warn '..rInfo.id..' чит Ghetto')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Закрыть', bsize) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
                if imgui.BeginPopupModal(u8"Выдать бан", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
                    bsize = imgui.ImVec2(125, 0)
                    if imgui.Button(u8'Своя причина', bsize) then
                        sampSetChatInputEnabled(true)
                        sampSetChatInputText('/ban '..rInfo.id..' ')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Вред.Читы', bsize) then
                        sampSendChat('/iban '..rInfo.id..' 7 Вредительские читы')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Чит ДМГ', bsize) then
                        sampSendChat('/ban '..rInfo.id..' 5 Читы в деморгане')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Оск.Проекта', bsize) then
                        sampSendChat('/iban '..rInfo.id..' Оскорбление проекта')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Обман Адм', bsize) then
                        sampSendChat('/mute '..rInfo.id..' 25 Обман Адм')
                        imgui.CloseCurrentPopup()
                    end
                    if imgui.Button(u8'Закрыть', bsize) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
                imgui.End()
                imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.FirstUseEver)
                imgui.SetNextWindowSize(imgui.ImVec2(w-x, 198), imgui.Cond.FirstUseEver)
                imgui.Begin(u8"Информация##reconInfo", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoTitleBar)
                local score, ping = sampGetPlayerScore(rInfo.id), sampGetPlayerPing(rInfo.id)
                local health, armor, ammo, orgActive = sampGetPlayerHealth(rInfo.id), sampGetPlayerArmor(rInfo.id), getAmmoRecon(), getActiveOrganization(rInfo.id)
                if ammo == 0 then
                    ammo = u8'Нет'
                else
                    ammo = getAmmoRecon()
                end
                if armor == 0 then
                    armor = u8'Нет'
                else
                    armor = sampGetPlayerArmor(rInfo.id)
                end
                rInfo.nickname = sampGetPlayerNickname(rInfo.id)
                if isPed and doesCharExist(pPed) then
                    local speed, model, interior = getCharSpeed(pPed), getCharModel(pPed), getCharActiveInterior(playerPed)
                    imgui.Text(u8(sampGetPlayerNickname(rInfo.id)..'['..rInfo.id..']'))
                    imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(1.0, 2.5))
                    imgui.Text(u8'Жизни: '..health)
                    imgui.Text(u8'Броня: '..armor)
                    imgui.Text(u8'Уровень: '..score)
                    imgui.Text(u8'Пинг: '..ping)
                    if isCharInAnyCar(pPed) then
                        imgui.Text(u8('Скорость: В машине'))
                    else
                        imgui.Text(u8('Скорость: '..math.floor(speed)))
                    end
                    imgui.Text(u8'Скин: '..model)
                    if orgActive ~= nil then
                        imgui.Text(u8'Организация: '..orgActive)
                    elseif orgActive == nil then
                        imgui.Text(u8'Организация: Нет')
                    end
                    imgui.Text(u8"Интерьер: "..interior)
                    imgui.Text(u8"Патроны: "..ammo)
                    imgui.PopStyleVar()
                    local y = y + 196
                    if isCharInAnyCar(pPed) then
                        local carHundle = storeCarCharIsInNoSave(pPed)
                        local carSpeed = getCarSpeed(carHundle)
                        local carModel = getCarModel(carHundle)
                        local carHealth = getCarHealth(carHundle)
                        local carEngine = isCarEngineOn(carHundle)
                        if carEngine then
                            carEngine = u8'Включён'
                        else
                            carEngine = u8'Выключен'
                        end
                        imgui.SetNextWindowPos(imgui.ImVec2(x, y), imgui.Cond.FirstUseEver, imgui.ImVec2(0.0, 0.0))
                        imgui.SetNextWindowSize(imgui.ImVec2(w-x, 97), imgui.Cond.FirstUseEver)
                        imgui.Begin(u8"##reconCarInfo", _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoSavedSettings)
                        imgui.PushStyleVarVec2(imgui.StyleVar.ItemSpacing, imgui.ImVec2(1.0, 2.5))
                        imgui.Text(u8"Транспорт: "..tCarsName[carModel-399])
                        imgui.Text(u8"Жизни: "..carHealth)
                        imgui.Text(u8"Модель: "..carModel)
                        imgui.Text(u8"Скорость: "..math.floor(carSpeed*2))
                        imgui.Text(u8"Двигатель: "..carEngine)
                        imgui.PopStyleVar()
                        imgui.End()
                    end
                else
                    imgui.Text(u8"Вы следите за ботом\nПереключитесь на\nКорректный ИД игрока.")
                end
            else
                player.HideCursor = true
            end
            local pedExist, ped = sampGetCharHandleBySampPlayerId(rInfo.id)
            target = ped
            if isPed and doesCharExist(target) then
                imgui.SetNextWindowPos(imgui.ImVec2(tableOfNew.poskey.x, tableOfNew.poskey.y), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
                imgui.Begin("##KEYS", nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)
                local plState = (isCharOnFoot(target) and "onfoot" or "vehicle")

                imgui.BeginGroup()
                    imgui.SetCursorPosX(10 + 30 + 5)
                    KeyCap("W", (keys[plState]["W"] ~= nil), imgui.ImVec2(30, 30))
                    KeyCap("A", (keys[plState]["A"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
                    KeyCap("S", (keys[plState]["S"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
                    KeyCap("D", (keys[plState]["D"] ~= nil), imgui.ImVec2(30, 30))
                imgui.EndGroup()
                imgui.SameLine(nil, 20)

                if plState == "onfoot" then
                    imgui.BeginGroup()
                        KeyCap("Shift", (keys[plState]["Shift"] ~= nil), imgui.ImVec2(75, 30)); imgui.SameLine()
                        KeyCap("Alt", (keys[plState]["Alt"] ~= nil), imgui.ImVec2(55, 30))
                        KeyCap("Space", (keys[plState]["Space"] ~= nil), imgui.ImVec2(135, 30))
                    imgui.EndGroup()
                    imgui.SameLine()
                    imgui.BeginGroup()
                        KeyCap("C", (keys[plState]["C"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
                        KeyCap("F", (keys[plState]["F"] ~= nil), imgui.ImVec2(30, 30))
                        KeyCap("RM", (keys[plState]["RKM"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
                        KeyCap("LM", (keys[plState]["LKM"] ~= nil), imgui.ImVec2(30, 30))		
                    imgui.EndGroup()
                else
                    imgui.BeginGroup()
                        KeyCap("Ctrl", (keys[plState]["Ctrl"] ~= nil), imgui.ImVec2(65, 30)); imgui.SameLine()
                        KeyCap("Alt", (keys[plState]["Alt"] ~= nil), imgui.ImVec2(65, 30))
                        KeyCap("Space", (keys[plState]["Space"] ~= nil), imgui.ImVec2(135, 30))
                    imgui.EndGroup()
                    imgui.SameLine()
                    imgui.BeginGroup()
                        KeyCap("Up", (keys[plState]["Up"] ~= nil), imgui.ImVec2(40, 30))
                        KeyCap("Down", (keys[plState]["Down"] ~= nil), imgui.ImVec2(40, 30))	
                    imgui.EndGroup()
                    imgui.SameLine()
                    imgui.BeginGroup()
                        KeyCap("H", (keys[plState]["H"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
                        KeyCap("F", (keys[plState]["F"] ~= nil), imgui.ImVec2(30, 30))
                        KeyCap("Q", (keys[plState]["Q"] ~= nil), imgui.ImVec2(30, 30)); imgui.SameLine()
                        KeyCap("E", (keys[plState]["E"] ~= nil), imgui.ImVec2(30, 30))
                    imgui.EndGroup()
                    imgui.End()
                end
            end
        end
    end
)

imgui.OnFrame(function() return tableOfNew.AutoReport[0] end,
    function(player)
        --imgui.SetNextWindowSize(imgui.ImVec2(540, 365), imgui.Cond.Always)
		imgui.SetNextWindowPos(imgui.ImVec2(ex / 2, ey / 2), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'Жалоба/Вопрос', tableOfNew.AutoReport, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        imgui.BeginChild('##i_report', imgui.ImVec2(515, 67), true)
        if #reports > 0 then
            imgui.Text(u8'Отправитель:')
            imgui.SameLine()
            imgui.TextDisabled(u8(reports[1].nickname..'['..reports[1].id..']'))
            imgui.SameLine()
            if imgui.faButton(fa.ICON_FA_COPY, imgui.ImVec2(18,18.5)) then
                setClipboardText(reports[1].nickname)
            end
            imgui.PushTextWrapPos(485)
            imgui.TextDisabled(u8'Сообщение:')
            imgui.SameLine()
            imgui.TextUnformatted(u8(reports[1].textP))
            imgui.PopTextWrapPos()
        end
        imgui.EndChild()
        imgui.Separator()
        imgui.PushItemWidth(520)
        imgui.NewInputText('##nn', tableOfNew.answer_report, 520, u8'Введите свой ответ', 2)
        imgui.PopItemWidth()
        if imgui.Button(u8'Работать по ID', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                if reports[1].textP:find('%d+') then
                    tableOfNew.AutoReport[0] = false
                    imgui.ShowCursor = false
                    lua_thread.create(function()
                        local id = reports[1].textP:match('(%d+)')
                        sampSendChat('/pm '..reports[1].id..' Уважаемый игрок, начинаю работу по вашей жалобе!')
                        wait(1000)
                        sampSendChat('/re '..id)
                        refresh_current_report()
                    end)
                else
                    sampAddChatMessage('{FF0000}[InTool]{FFFFFF} В репорте отсутствует ИД.')
                end
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Помочь автору', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                imgui.OpenPopup(u8'helper')
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Следить автору', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                lua_thread.create(function()
                    tableOfNew.AutoReport[0] = false
                    imgui.ShowCursor = false
                    sampSendChat('/re '..reports[1].id)
                    local pID = reports[1].id
                    wait(1000)
                    sampSendChat('/pm '..pID..' Уважаемый игрок, начинаю работу по вашей жалобе!')
                    refresh_current_report()
                end)
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Жалоба в СГ', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                lua_thread.create(function()
                    tableOfNew.answer_report = imgui.new.char[256](u8'Уважаемый игрок, вы можете подать жалобу в свободную группу - @inferno_sv')
                end)
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Приятной игры', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                lua_thread.create(function()
                    tableOfNew.answer_report = imgui.new.char[256](u8'Приятной игры на Inferno Role Play')
                end)
            end
        end
        if imgui.Button(u8'/gethere', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                lua_thread.create(function()
                    tableOfNew.AutoReport[0] = false
                    imgui.ShowCursor = false
                    sampSendChat('/gethere '..reports[1].id)
                    local pID = reports[1].id
                    wait(1000)
                    sampSendChat('/pm '..pID..' Уважаемый игрок, начинаю работу по вашей жалобе!')
                    refresh_current_report()
                end)
            end
        end imgui.SameLine()
        if imgui.Button(u8'Да', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                tableOfNew.answer_report = imgui.new.char[256](u8'Да.')
            end
        end imgui.SameLine()
        if imgui.Button(u8'Нет', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                tableOfNew.answer_report = imgui.new.char[256](u8'Нет.')
            end
        end imgui.SameLine()
        if imgui.Button(u8'Не знаем', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                tableOfNew.answer_report = imgui.new.char[256](u8'Не имеем информации по вашему вопросу.')
            end
        end imgui.SameLine()
        if imgui.Button(u8'РП Путём', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                tableOfNew.answer_report = imgui.new.char[256](u8'РП Путём.')
            end
        end
        local clr = imgui.Col
        imgui.PushStyleColor(clr.Button, imgui.ImVec4(0.86, 0.09, 0.09, 0.65))
        imgui.PushStyleColor(clr.ButtonHovered, imgui.ImVec4(0.74, 0.04, 0.04, 0.65))
        imgui.PushStyleColor(clr.ButtonActive, imgui.ImVec4(0.96, 0.15, 0.15, 0.50))
        if imgui.Button(u8'Оффтоп', imgui.ImVec2(100, 25)) then
            if #reports > 0 then
                imgui.OpenPopup(u8'Оффтоп')
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Оск.Адм', imgui.ImVec2(100, 25)) then
            if #reports > 0 then
                sampSendChat('/rmute '..reports[1].id..' 15 Оскорбление администрации')
                refresh_current_report()
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Оск.Род', imgui.ImVec2(100, 25)) then
            if #reports > 0 then
                sampSendChat('/rmute '..reports[1].id..' 60 Оскорбление родных')
                refresh_current_report()
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Капс', imgui.ImVec2(100, 25)) then
            if #reports > 0 then
                sampSendChat('/rmute '..reports[1].id..' 5 Капс')
                refresh_current_report()
            end
        end
        imgui.SameLine()
        if imgui.Button(u8'Обман Адм', imgui.ImVec2(100, 25)) then
            if #reports > 0 then
                sampSendChat('/rmute '..reports[1].id..' 15 Обман администрации')
                refresh_current_report()
            end
        end
        if imgui.Button(u8'Оск Проекта', imgui.ImVec2(100, 25)) then
            if #reports > 0 then
                sampSendChat('/rmute '..reports[1].id..' 60 Оскорбление проекта')
                refresh_current_report()
            end
        end imgui.SameLine()
        if imgui.Button(u8'Оск Игроков', imgui.ImVec2(100, 25)) then
            if #reports > 0 then
                sampSendChat('/rmute '..reports[1].id..' 15 Оскорбление игроков')
                refresh_current_report()
            end
        end imgui.SameLine()
        if imgui.Button(u8'Мат', imgui.ImVec2(100, 25)) then
            if #reports > 0 then
                sampSendChat('/rmute '..reports[1].id..' 5 Мат')
                refresh_current_report()
            end
        end imgui.SameLine()
        if imgui.Button(u8'Упом.Род', imgui.ImVec2(100, 25)) then
            if #reports > 0 then
                sampSendChat('/mute '..reports[1].id..' 30 Упоминание родных')
                refresh_current_report()
            end
        end imgui.SameLine()
        if imgui.Button(u8'ЧСС', imgui.ImVec2(100, 25)) then
            if #reports > 0 then
                sampSendChat('/iban '..reports[1].id..' Чсс')
                refresh_current_report()
            end
        end
        imgui.PopStyleColor(3)
        if imgui.Button(u8'Уточните', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                tableOfNew.answer_report = imgui.new.char[256](u8'Уважаемый игрок, переформулируйте вашу жалобу так, чтобы была ясна ваша просьба/утверждение.')
            end
            imgui.CloseCurrentPopup()
        end imgui.SameLine()
        if imgui.Button(u8'Ожидайте', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                tableOfNew.answer_report = imgui.new.char[256](u8'Уважаемый игрок, убедительная просьба проявить терпение.')
            end
            imgui.CloseCurrentPopup()
        end imgui.SameLine()
        if imgui.Button(u8'У.Интернете', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                tableOfNew.answer_report = imgui.new.char[256](u8'Уточните в интернете.')
            end
            imgui.CloseCurrentPopup()
        end imgui.SameLine()
        if imgui.Button(u8'Отказ', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                tableOfNew.answer_report = imgui.new.char[256](u8' Уважаемый игрок, то, что вы просите - не может быть исполнено.')
            end
            imgui.CloseCurrentPopup()
        end imgui.SameLine()
        if imgui.Button(u8'Переслать', imgui.ImVec2(100, 30)) then
            if #reports > 0 then
                lua_thread.create(function()
                    local bool = _sampSendChat(reports[1].nickname..'['..reports[1].id..']: '..reports[1].textP, 80)
                    wait(1000)
                    sampSendChat('/pm '..reports[1].id..' Уважаемый игрок, передал вашу жалобу администрации.')
                    refresh_current_report()
                end)
            end
        end
        if imgui.Button(fa.ICON_FA_COMMENT..u8' Ответить', imgui.ImVec2(170, 55)) then
            if ffi.string(tableOfNew.answer_report) == '' then
                sampAddChatMessage('{FF0000}[InTool]{FFFFFF} Введите корректный ответ.')
            else
                if #reports > 0 then
                    sampSendChat('/pm '..reports[1].id..' '..u8:decode(ffi.string(tableOfNew.answer_report)))
                    refresh_current_report()
                    tableOfNew.answer_report = imgui.new.char[256](u8'')
                end
            end
        end
        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_CODE, imgui.ImVec2(80, 55)) then
            imgui.OpenPopup(u8'commands')
        end
        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_MAP_MARKER_ALT, imgui.ImVec2(80, 55)) then
            imgui.OpenPopup(u8'maps')
        end
        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_PAPER_PLANE..u8' Пропустить', imgui.ImVec2(170, 55)) then
            refresh_current_report()
        end
        if imgui.BeginPopup(u8'commands') then
            local cmds = {'/propose', '/buycar', '/sellcar', '/pgun', '/sellhouse', '/selfie', '/mm', '/unrent', '/find', '/recorder', '/h', '/gov', '/divorce', '/buybiz', '/gps', '/buylead', '/goadminka', '/ruletka', '/drecorder', '/su', '/showudost', '/fvig', '/invite', '/clear', '/call', '/sms', '/togphone', '/business', '/drag ID', '/buyadm'}
            for i=1, 4 do
                if imgui.Button(cmds[i], imgui.ImVec2(100, 39)) then
                    tableOfNew.answer_report = imgui.new.char[256](cmds[i])
                    imgui.CloseCurrentPopup()
                end imgui.SameLine()
            end
            if imgui.Button(cmds[5], imgui.ImVec2(100, 39)) then
                tableOfNew.answer_report = imgui.new.char[256](cmds[5])
                imgui.CloseCurrentPopup()
            end
            for i=6, 9 do
                if imgui.Button(cmds[i], imgui.ImVec2(100, 39)) then
                    tableOfNew.answer_report = imgui.new.char[256](cmds[i])
                    imgui.CloseCurrentPopup()
                end imgui.SameLine()
            end
            if imgui.Button(cmds[10], imgui.ImVec2(100, 39)) then
                tableOfNew.answer_report = imgui.new.char[256](cmds[10])
                imgui.CloseCurrentPopup()
            end
            for i=11, 14 do
                if imgui.Button(cmds[i], imgui.ImVec2(100, 39)) then
                    tableOfNew.answer_report = imgui.new.char[256](cmds[i])
                    imgui.CloseCurrentPopup()
                end imgui.SameLine()
            end
            if imgui.Button(cmds[15], imgui.ImVec2(100, 39)) then
                tableOfNew.answer_report = imgui.new.char[256](cmds[15])
                imgui.CloseCurrentPopup()
            end
            for i=16, 19 do
                if imgui.Button(cmds[i], imgui.ImVec2(100, 39)) then
                    tableOfNew.answer_report = imgui.new.char[256](cmds[i])
                    imgui.CloseCurrentPopup()
                end imgui.SameLine()
            end
            if imgui.Button(cmds[20], imgui.ImVec2(100, 39)) then
                tableOfNew.answer_report = imgui.new.char[256](cmds[21])
                imgui.CloseCurrentPopup()
            end
            for i=21, 24 do
                if imgui.Button(cmds[i], imgui.ImVec2(100, 39)) then
                    tableOfNew.answer_report = imgui.new.char[256](cmds[i])
                    imgui.CloseCurrentPopup()
                end imgui.SameLine()
            end
            if imgui.Button(cmds[25], imgui.ImVec2(100, 39)) then
                tableOfNew.answer_report = imgui.new.char[256](cmds[25])
                imgui.CloseCurrentPopup()
            end
            for i=26, 29 do
                if imgui.Button(cmds[i], imgui.ImVec2(100, 39)) then
                    tableOfNew.answer_report = imgui.new.char[256](cmds[i])
                    imgui.CloseCurrentPopup()
                end imgui.SameLine()
            end
            if imgui.Button(cmds[30], imgui.ImVec2(100, 39)) then
                tableOfNew.answer_report = imgui.new.char[256](cmds[30])
                imgui.CloseCurrentPopup()
            end
            if imgui.Button(u8'Закрыть окно', imgui.ImVec2(515, 50)) then
                imgui.CloseCurrentPopup()
            end
        end
        if imgui.BeginPopup(u8'maps') then
            if imgui.Button(u8'В мэрии', imgui.ImVec2(100, 30)) then
                tableOfNew.answer_report = imgui.new.char[256](u8'В мэрии')
                imgui.CloseCurrentPopup()
            end imgui.SameLine()
            if imgui.Button(u8'На спавне', imgui.ImVec2(100, 30)) then
                tableOfNew.answer_report = imgui.new.char[256](u8'На спавне')
                imgui.CloseCurrentPopup()
            end imgui.SameLine()
            if imgui.Button(u8'В риэлторском агенстве', imgui.ImVec2(100, 30)) then
                tableOfNew.answer_report = imgui.new.char[256](u8'В риэлторском агенстве')
                imgui.CloseCurrentPopup()
            end imgui.SameLine()
            if imgui.Button(u8'На маяке', imgui.ImVec2(100, 30)) then
                tableOfNew.answer_report = imgui.new.char[256](u8'На маяке')
                imgui.CloseCurrentPopup()
            end imgui.SameLine()
            if imgui.Button(u8'На колесе обозрения', imgui.ImVec2(100, 30)) then
                tableOfNew.answer_report = imgui.new.char[256](u8'На колесе обозрения')
                imgui.CloseCurrentPopup()
            end 
            imgui.Separator()
            if imgui.Button(u8'На горе VineWood', imgui.ImVec2(100, 30)) then
                tableOfNew.answer_report = imgui.new.char[256](u8'На горе VineWood')
                imgui.CloseCurrentPopup()
            end imgui.SameLine()
            if imgui.Button(u8'В аммуниции ЛC', imgui.ImVec2(100, 30)) then
                tableOfNew.answer_report = imgui.new.char[256](u8'В аммуниции ЛС')
                imgui.CloseCurrentPopup()
            end imgui.SameLine()
            if imgui.Button(u8'В закусочной', imgui.ImVec2(100, 30)) then
                tableOfNew.answer_report = imgui.new.char[256](u8'В закусочной.')
                imgui.CloseCurrentPopup()
            end imgui.SameLine()
            if imgui.Button(u8'В магазине одежды', imgui.ImVec2(100, 30)) then
                tableOfNew.answer_report = imgui.new.char[256](u8'В магазине одежды.')
                imgui.CloseCurrentPopup()
            end imgui.SameLine()
            if imgui.Button(u8'В церкви', imgui.ImVec2(100, 30)) then
                tableOfNew.answer_report = imgui.new.char[256](u8'В церкви.')
                imgui.CloseCurrentPopup()
            end 
            imgui.Separator()
        end
        if imgui.BeginPopup(u8'helper') then
            if imgui.Button(u8'Телепортироваться к игроку', imgui.ImVec2(150, 79)) then
                lua_thread.create(function()
                    if #reports > 0 then
                        lua_thread.create(function()
                            tableOfNew.AutoReport[0] = false
                            imgui.ShowCursor = false
                            sampSendChat('/g '..reports[1].id)
                            wait(1000)
                            sampSendChat('/pm '..reports[1].id..' Уважаемый игрок, сейчас попробую вам помочь!')
                            imgui.CloseCurrentPopup()
                            refresh_current_report()
                        end)
                    end
                end)
            end imgui.SameLine()
            if imgui.Button(u8'Следить за автором', imgui.ImVec2(150, 79)) then
                if #reports > 0 then
                    lua_thread.create(function()
                        tableOfNew.AutoReport[0] = false
                        imgui.ShowCursor = false
                        sampSendChat('/re '..reports[1].id)
                        wait(1000)
                        sampSendChat('/pm '..reports[1].id..' Уважаемый игрок, сейчас попробую вам помочь!')
                        imgui.CloseCurrentPopup()
                        refresh_current_report()
                    end)
                end
            end imgui.SameLine()
            if imgui.Button(u8'Заспавнить', imgui.ImVec2(150, 79)) then
                if #reports > 0 then
                    lua_thread.create(function()
                        sampSendChat('/sp '..reports[1].id)
                        wait(1000)
                        sampSendChat('/pm '..reports[1].id..' Уважаемый игрок, ваша просьба выполнена!')
                        imgui.CloseCurrentPopup()
                        refresh_current_report()
                    end)
                end
            end imgui.SameLine()
            if imgui.Button(u8'Выдать машину', imgui.ImVec2(150, 79)) then
                if #reports > 0 then
                    tableOfNew.AutoReport[0] = false
                    imgui.ShowCursor = false
                    lua_thread.create(function()
                        sampSendChat('/re ' .. reports[1].id)
                        wait(1000)
                        sampSendChat('/veh 560 3 3 0')
                        wait(1000)
                        if carban then
                            sampAddChatMessage('{FFFF00}[InTool] {FFFFFF}Случилась ошибка при выдаче Т/С выполняю резервную функцию', -1)
                            sampSendChat('/re off')
                            wait(1000)
                            sampSendChat('/tp')
                            wait(1000)
                            sampSendDialogResponse(sampGetCurrentDialogId(), 1, 9, nil)
                            sampCloseCurrentDialogWithButton()
                            wait(1000)
                            sampSendChat('/veh 522 1 1 0')
                            wait(1000)
                            sampSendChat('/g ' .. reports[1].id)
                            wait(1000)
                            sampSendChat('/re ' .. reports[1].id)
                            wait(1000)
                            sampSendChat('/pm ' .. reports[1].id .. " Приятной игры на нашем сервере")
                        else
                            wait(1000)
                            sampSendChat('/pm ' .. reports[1].id .. " Приятной игры на нашем сервере")
                        end
                    end)
                end
            end
        end
        imgui.End()
    end
)

imgui.OnFrame(function() return tableOfNew.tempLeader[0] end,
    function(player)
        imgui.SetNextWindowSize(imgui.ImVec2(250, 400), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2(ex / 2 - 600, ey / 2 - 50), imgui.Cond.FirstUseEver)
		imgui.Begin(u8'Выдача временного лидерства', nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
		if imgui.Button(u8'Покинуть организацию', imgui.ImVec2(225, 0)) then
			sampSendChat('/uval '..getMyId()..' Leave')
		end
		for k,v in ipairs(tempLeaders) do
			if imgui.Button(v..'['..k..']', imgui.ImVec2(225, 0)) then
				sampSendChat('/templeader '..k)
			end
		end
		imgui.End()
    end
)

imgui.OnFrame(function() return checkbox.statistics.to[0] end,
    function(player)
        player.HideCursor = true
        imgui.SetNextWindowPos(imgui.ImVec2(checkbox.statistics.posX, checkbox.statistics.posY), imgui.Cond.Always)
        imgui.Begin(u8'##timer', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoTitleBar)
        if cfg.statTimers.clock then
            imgui.PushFont(fsClock)
            imgui.CenterTextColoredRGB(checkbox.statistics.nowTime)
            imgui.PopFont()
            imgui.SetCursorPosY(30)
            imgui.CenterTextColoredRGB(getStrDate(os.time()))
            if sampGetGamestate() == 3 then 
                local id = sampGetPlayerIdByNickname(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed))))
                imgui.CenterTextColoredRGB('Ваш ID: '..id)
            end
            if cfg.statTimers.sesOnline or cfg.statTimers.sesAfk or cfg.statTimers.sesFull or cfg.statTimers.dayOnline or cfg.statTimers.dayAfk or cfg.statTimers.dayFull or cfg.statTimers.weekOnline or cfg.statTimers.weekAfk or cfg.statTimers.weekFull then
                imgui.Separator()
            end
        end
        if sampGetGamestate() ~= 3 then 
            imgui.Text(u8"Подключение: "..get_clock(connectingTime))
        else
            if cfg.statTimers.sesOnline then imgui.CenterTextColoredRGB("Сессия (чистый): "..get_clock(checkbox.statistics.sesOnline[0])) end
            if cfg.statTimers.sesAfk then imgui.CenterTextColoredRGB("AFK за сессию: "..get_clock(checkbox.statistics.sesAfk[0])) end
            if cfg.statTimers.sesFull then imgui.CenterTextColoredRGB("Онлайн за сессию: "..get_clock(checkbox.statistics.sesFull[0])) end
            if cfg.statTimers.dayOnline then imgui.CenterTextColoredRGB("За день (чистый): "..get_clock(cfg.onDay.online)) end
            if cfg.statTimers.dayAfk then imgui.CenterTextColoredRGB("АФК за день: "..get_clock(cfg.onDay.afk)) end
            if cfg.statTimers.reports then imgui.CenterTextColoredRGB("Репортов за день : ".. cfg.onDay.reports) end
            if cfg.statTimers.nakaz then imgui.CenterTextColoredRGB('Выдано наказаний: ' .. cfg.onDay.nakaz) end
            if cfg.statTimers.dayFull then imgui.CenterTextColoredRGB("Онлайн за день: "..get_clock(cfg.onDay.full)) end
            if cfg.statTimers.weekAfk then imgui.CenterTextColoredRGB("АФК за неделю: "..get_clock(cfg.onWeek.afk)) end
            if cfg.statTimers.weekFull then imgui.CenterTextColoredRGB("Онлайн за неделю(чистый): "..get_clock(cfg.onWeek.online)) end
        end
        imgui.End()
    end
)

imgui.OnFrame(function() return checkbox.statistics.myOnline[0] end,
    function(player)
        player.HideCursor = false
        imgui.SetNextWindowSize(imgui.ImVec2(400, 230), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(imgui.ImVec2(ex / 2, ey / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(u8'#WeekOnline', _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize)
            imgui.SetCursorPos(imgui.ImVec2(15, 10))
            imgui.PushFont(fsClock) imgui.CenterTextColoredRGB('Онлайн за неделю') imgui.PopFont()
            imgui.CenterTextColoredRGB('{0087FF}Всего отыграно: '..get_clock(cfg.onWeek.online))
            imgui.NewLine()
            for day = 1, 6 do -- ПН -> СБ
                imgui.Text(u8(tWeekdays[day])); imgui.SameLine(250)
                imgui.Text(get_clock(cfg.myWeekOnline[day]))
            end
            imgui.Text(u8(tWeekdays[0])); imgui.SameLine(250)
            imgui.Text(get_clock(cfg.myWeekOnline[0]))

            imgui.Separator()

            ad.AlignedText(u8'Количество отвеченных репортов', 2)
            imgui.CenterTextColoredRGB('{0087FF}Всего отвечено: ' .. checkbox.statistics.reportssumm)
            for day = 1, 6 do -- ПН -> СБ
                imgui.Text(u8(tWeekdays[day])); imgui.SameLine(250)
                imgui.Text(u8(cfg.myWeekReport[day]))
            end
            imgui.Text(u8(tWeekdays[0])); imgui.SameLine(250)
            imgui.Text(u8(cfg.myWeekReport[0]))

            ad.AlignedText(u8'Количество выданных наказаний', 2)
            imgui.CenterTextColoredRGB('{0087FF}Всего выдано: ' .. checkbox.statistics.nakazsumm)
            for day = 1, 6 do -- ПН -> СБ
                imgui.Text(u8(tWeekdays[day])); imgui.SameLine(250)
                imgui.Text(u8(cfg.myWeekNakaz[day]))
            end
            imgui.Text(u8(tWeekdays[0])); imgui.SameLine(250)
            imgui.Text(u8(cfg.myWeekNakaz[0]))

            imgui.SetCursorPosX((imgui.GetWindowWidth() - 200) / 2)
            if imgui.Button(u8'Закрыть', imgui.ImVec2(200, 25)) then checkbox.statistics.myOnline[0] = false end
        imgui.End()
    end
)

function refresh_current_report()
	table.remove(reports, 1)
end

function cmd_sk(x)
    if items.sorkcomm.sk[0] == true then
        sampSendChat('/jail ' .. x .. ' 10 SK')
    end
end
function cmd_dm(x)
    if items.sorkcomm.dm[0] == true then
        sampSendChat('/jail ' .. x .. ' 10 DM')
    end
end
function cmd_tk(x)
    if items.sorkcomm.tk[0] == true then
        sampSendChat('/jail ' .. x .. ' 10 TK')
    end
end
function cmd_ch(x)
    if items.sorkcomm.ch[0] == true then
        sampSendChat('/jail ' .. x .. ' 60 Cheat')
    end
end
function cmd_nrp(x)
    if items.sorkcomm.nrp[0] == true then
        sampSendChat('/jail ' .. x .. ' 10 NRP')
    end
end
function cmd_orp(x)
    if items.sorkcomm.orp[0] == true then
        sampSendChat('/rmute ' .. x .. ' 60 О.Р')
    end
end

function cmd_churka(arg)
    if #arg == 0 then
        sampShowDialog(13, 'Выберите пункт', massiv.dialogStr, 'Тыкнуть', 'Закрыть', 2)
    end
end

function cmd_otbor(arg)
    if #arg == 0 then
        sampShowDialog(14, 'Выберите структуру', massiv.dialogOtbb, 'Тык', 'Закрыть', 2)
    end
end

function imgui.NewInputText(lable, val, width, hint, hintpos)
    local hint = hint and hint or ''
    local hintpos = tonumber(hintpos) and tonumber(hintpos) or 1
    local cPos = imgui.GetCursorPos()
    imgui.PushItemWidth(width)
    local result = imgui.InputText(lable, val, 256)
    if val[0] == 0 then
        local hintSize = imgui.CalcTextSize(hint)
        if hintpos == 2 then imgui.SameLine(cPos.x + (width - hintSize.x) / 2)
        elseif hintpos == 3 then imgui.SameLine(cPos.x + (width - hintSize.x - 5))
        else imgui.SameLine(cPos.x + 5) end
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 0.40), tostring(hint))
    end
    imgui.PopItemWidth()
    return result
end

function onWindowMessage(msg, wparam, lparam)
    if tableOfNew.menutab[0] then
        if(msg == 0x100 or msg == 0x101) then
            if (wparam == VK_ESCAPE and checkbox.statistics.renderTAB[0]) and not isPauseMenuActive() then
                consumeWindowMessage(true, false)
                if (msg == 0x101) then
                    checkbox.statistics.renderTAB[0] = false
                end
            elseif wparam == VK_TAB and not isKeyDown(VK_TAB) and not isPauseMenuActive() then
                if not checkbox.statistics.renderTAB[0] then
                    if not sampIsChatInputActive() then
                        checkbox.statistics.renderTAB[0] = true
                    end
                else
                    checkbox.statistics.renderTAB[0] = false
                end
                consumeWindowMessage(true, false)
            end
        end
    end
end

local russian_characters = {
    [168] = 'Ё', [184] = 'ё', [192] = 'А', [193] = 'Б', [194] = 'В', [195] = 'Г', [196] = 'Д', [197] = 'Е', [198] = 'Ж', [199] = 'З', [200] = 'И', [201] = 'Й', [202] = 'К', [203] = 'Л', [204] = 'М', [205] = 'Н', [206] = 'О', [207] = 'П', [208] = 'Р', [209] = 'С', [210] = 'Т', [211] = 'У', [212] = 'Ф', [213] = 'Х', [214] = 'Ц', [215] = 'Ч', [216] = 'Ш', [217] = 'Щ', [218] = 'Ъ', [219] = 'Ы', [220] = 'Ь', [221] = 'Э', [222] = 'Ю', [223] = 'Я', [224] = 'а', [225] = 'б', [226] = 'в', [227] = 'г', [228] = 'д', [229] = 'е', [230] = 'ж', [231] = 'з', [232] = 'и', [233] = 'й', [234] = 'к', [235] = 'л', [236] = 'м', [237] = 'н', [238] = 'о', [239] = 'п', [240] = 'р', [241] = 'с', [242] = 'т', [243] = 'у', [244] = 'ф', [245] = 'х', [246] = 'ц', [247] = 'ч', [248] = 'ш', [249] = 'щ', [250] = 'ъ', [251] = 'ы', [252] = 'ь', [253] = 'э', [254] = 'ю', [255] = 'я',
}

function string.rlower(s)
    s = s:lower()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:lower()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 192 and ch <= 223 then -- upper russian characters
            output = output .. russian_characters[ch + 32]
        elseif ch == 168 then
            output = output .. russian_characters[184]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end

function cmd_spv(arg)
    if massiv.imBitche[0] then
        if #arg == 0 then
            sampAddChatMessage('Введите ID', -1)
        else
            lua_thread.create(function()
                sampSendChat('/slap ' .. arg)
                wait(1000)
                sampSendChat('/sp ' .. arg)
            end)
        end
    else
        if #arg == 0 then
            sampAddChatMessage('Введите ID', -1)
        else
        sampSendChat('/sp ' .. arg)
        end
    end
end

function getActiveOrganization(id)
	local color = sampGetPlayerColor(id)
	if color == 553648127 then
		organization = u8'Нет[0]'
	elseif color == 2854633982 then
		organization = u8'LSPD[1]'
	elseif color == 2855350577 then
		organization = u8'FBI[2]'
	elseif color == 2855512627 then
		organization = u8'Армия[3]'
	elseif color == 4289014314 then
		organization = u8'МЧС[4]'
	elseif color == 4292716289 then
		organization = u8'LCN[5]'
	elseif color == 2868838400 then
		organization = u8'Якудза[6]'
	elseif color == 4279324017 then
		organization = u8'Мэрия[7]'
	elseif color == 2854633982 then
		organization = u8'SFPD[10]'
	elseif color == 4279475180 then
		organization = u8'Инструкторы[11]'
	elseif color == 4287108071 then
		organization = u8'Баллас[12]'
	elseif color == 2866533892 then
		organization = u8'Вагос[13]'
	elseif color == 4290033079 then
		organization = u8'Мафия[14]'
	elseif color == 2852167424 then
		organization = u8'Грув[15]'
	elseif color == 2856354955 then
		organization = u8'Sa News[16]'
	elseif color == 3355573503 then
		organization = u8'Ацтеки[17]'
	elseif color == 2860761023 then
		organization = u8'Рифа[18]'
	elseif color == 2854633982 then
		organization = u8'LVPD[21]'
	elseif color == 4285563024 then
		organization = u8'Хитманы[22]'
	elseif color == 4294201344 then
		organization = u8'Стритрейсеры[23]'
	elseif color == 4281240407 then
		organization = u8'SWAT[24]'
	elseif color == 2859499664 then
		organization = u8'АП[25]'
	elseif color == 2868838400 then
		organization = u8'Казино[26]'
	elseif color == 2863280947 then
		organization = u8'ПБ Red[()]'
	elseif color == 4281576191 then
		organization = u8'ПБ Blue[()]'
	elseif color == 8025703 then
		organization = u8'В маске[()]'
	end
	return organization
end

function cmd_otv(arg)
    tableOfNew.AutoReport[0] = not tableOfNew.AutoReport[0]
end

function cmd_tool(arg)
    tool[0] = not tool[0]
end

local transac_forma = false
local trans_forma = false

function sampev.onSendChat(text)
    if massiv.retrans[0] then
        local malovato = {
            [1] = {
                textdo = '.ку щаа',
                textafter = '/re off'
            },
            [2] = {
                textdo = '.ку',
                textafter = '/re'
            },
            [3] = {
                textdo = '.ещщл',
                textafter = '/tool'
            },
            [4] = {
                textdo = '.зь',
                textafter = '/pm'
            },
            [5] = {
                textdo = '.ффв',
                textafter = '/aad'
            },
            [6] = {
                textdo = '.ьгеу',
                textafter = '/mute'
            },
            [7] = {
                textdo = '.кьгеу',
                textafter = '/rmute'
            },
            [8] = {
                textdo = '.іуеіефе',
                textafter = '/setstat'
            },
            [9] = {
                textdo = '.ыуеыефе',
                textafter = '/setstat'
            },
            [10] = {
                textdo = '.ешьу',
                textafter = '/time'
            },
            [11] = {
                textdo = '.вмфдд',
                textafter = '/dvall'
            },
            [12] = {
                textdo = '.пуеруку',
                textafter = '/gethere'
            },
            [13] = {
                textdo = '.ез',
                textafter = '/tp'
            },
            [14] = {
                textdo = '.фвьшті',
                textafter = '/admins'
            },
            [15] = {
                textdo = '.фвьшты',
                textafter = '/admins'
            },
            [16] = {
                textdo = '.фіефеі',
                textafter = '/astats'
            },
            [17] = {
                textdo = '.фыефеы',
                textafter = '/astats'
            },
            [18] = {
                textdo = '.пуеыефеы',
                textafter = '/getstats'
            },
            [19] = {
                textdo = '.пуеіефеі',
                textafter = '/getstats'
            },
            [20] = {
                textdo = '.ьфлудуфвук',
                textafter = '/makeleader'
            },
            [21] = {
                textdo = '.еуьздуфвук',
                textafter = '/offleader'
            },
            [22] = {
                textdo = '.офшд',
                textafter = '/jail'
            },
            [23] = {
                textdo = '.ифтгз',
                textafter = '/banip'
            },
            [24] = {
                textdo = '.цфкт',
                textafter = '/banip'
            },
            [25] = {
                textdo = '.ыифт',
                textafter = '/sban'
            },
            [26] = {
                textdo = '.мур',
                textafter = '/veh'
            },
            [27] = {
                textdo = '.шифт',
                textafter = '/iban'
            },
            [28] = {
                textdo = '.ифт',
                textafter = '/ban'
            },
            [29] = {
                textdo = '.л',
                textafter = '/k'
            },
            [30] = {
                textdo = '.ф',
                textafter = '/a'
            },
            [31] = {
                textdo = '.п',
                textafter = '/g'
            },
        }
        for i=1, #malovato do
            if string.lower(text, imer):match('^'..malovato[i].textdo) then
                local imer = text:match('^'..malovato[i].textdo.."(.*)")
                lua_thread.create(function()
                    lasttime = os.time()
                    lasttimes = 0
                    time_out = 5
                    sampAddChatMessage('{FF0000}[InTool] {ffffff}Вы имели виду: ' .. '{FF00FF}'..malovato[i].textafter..imer..'? {FFFFFF}Да: {00ffff}X. {FFFFFF}Нет: {00FF00}Z', -1)
                    while lasttimes < time_out do
                        lasttimes = os.time() - lasttime
                        wait(0)
                        printStyledString("Anti-Translit " .. time_out - lasttimes .. " WAIT", 1000, 4)
                        if trans_forma then
                            printStyledString('Form already accepted', 1000, 4)
                            trans_forma = false
                            break
                        end
                        if lasttimes == time_out then
                            printStyledString("TIME OUT", 1000, 4)
                        end
                        if isKeyJustPressed(VK_X) and not sampIsChatInputActive() and not sampIsDialogActive() then
                            sampSendChat(malovato[i].textafter..imer)
                            transac_forma = false
                            break
                        elseif isKeyJustPressed(VK_Z) and not sampIsChatInputActive() and not sampIsDialogActive() then
                            transac_forma = false
                            break
                        end
                    end
                end)
            end
        end
    end
end


local active_forma = false
local stop_forma = false
local active_razdat = false

local cip = false
local cip_cip = ''

local lastMessageTime = 0
local messageCount = 0

function sampev.onServerMessage(color, text)
    local currentTime = os.clock()

    if currentTime - lastMessageTime < 1 then
        messageCount = messageCount + 1
        if messageCount > 15 then
            return true
        end
    else
        lastMessageTime = currentTime
        messageCount = 1
    end

    local nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
    if text:find('(.*) %| IP%: (.*)') then
        if cip then
            local Rnickname, Rip = text:match('(.*) %| IP%: (.*)')
            cip_cip = Rip
            return false
        end
    end
    if text:find("У игрока куплена функция 'скрытность'!") then
		rInfo.id = -1
	end
	if text:find("Игрок не вступил в игру!") then
		rInfo.id = -1
    end
    if text:find('Администратор следит за (.*)%[(%d+)%]') then
		rInfo.id = -1
    end
    if text:find('Запрещено создавать машину в зеленой зоне') then
        carban = true
    else
        carban = false
    end
    if text:find('Обращение от (.*)%[(%d+)%]: %{FFFFFF%}(.*)') then
        local Rnickname, Rid, RtextP = text:match('Обращение от (.*)%[(%d+)%]: %{FFFFFF%}(.*)')
        reports[#reports + 1] = {nickname = Rnickname, id = Rid, textP = RtextP}
        if massiv.imBitch[0] then
            lua_thread.create(function()
                if tableOfNew.item_sounds[0] == 0 then
                    local sound = loadAudioStream(direcories.number1)
                    setAudioStreamState(sound, ev.PLAY)
                elseif tableOfNew.item_sounds[0] == 1 then
                    local sound = loadAudioStream(direcories.number2)
                    setAudioStreamState(sound, ev.PLAY)
                end
            end)
        end
    end
    if text:find('Администратор ' .. nick .. ' отправил игрока (.*) в ад (.*)') then
        cfg.onDay.nakaz = cfg.onDay.nakaz + 1
    end
    if text:find('Администратор ' .. nick .. ' заблокировал (.*)') then
        cfg.onDay.nakaz = cfg.onDay.nakaz + 1
    end
    if text:find('%[SBAN%] Администратор ' .. nick .. ' забанил (.*)') then
        cfg.onDay.nakaz = cfg.onDay.nakaz + 1
    end
    if text:find('%[A%] ' .. nick .. '%[(%d+)%] ответил игроку (.*)') then
        if text:find('%[A%] ' .. nick .. '%[(%d+)%] ответил игроку '.. nick .. "%[(%d+)%]") then
            sampAddChatMessage('{FF0000}[InTool]{00FF00} Мне кажется, вы попытались воспользоваться хитростью! Учтите что за это вам последует наказание!')
        else
            checkbox.statistics.LsessionReport = checkbox.statistics.LsessionReport + 1
            cfg.onDay.reports = cfg.onDay.reports + 1
        end
    end
    if text:find('(.*) ' .. nick .. '(.*) РАЗДАЧА %| Кто первый напишет в %/rep ' .. u8:decode(word[massiv.slovo[0] + 1]) .. ' тот получит (.*)') then
        active_razdat = true
    end
    if text:find('Обращение от (.*)%[(%d+)%]: %{FFFFFF%}' .. u8:decode(word[massiv.slovo[0] + 1])) then
        local Rnickname, Rid = text:match('Обращение от (.*)%[(%d+)%]: %{FFFFFF%}' .. u8:decode(word[massiv.slovo[0] + 1]))
        if massiv.toggle_toggle[0] then
            if active_razdat == true then
                lua_thread.create(function()
                    active_razdat = false
                    wait(3000)
                    sampSendChat('/aad РАЗДАЧА | ' .. Rnickname .. ' выиграл ' ..  u8:decode(prizeon[massiv.razdacha_zapusk[0] + 1]) .. '!')
                end)
            end
        end
    end
    if text:find("AntiCheat | Игрок (.*)%[(%d+)] (.+)") then
        if massiv.imCarco[0] then
            active_forma = true
            local Rnikos, ridos, rtext = text:match("AntiCheat | Игрок (.*)%[(%d+)] (.+)")
            sampAddChatMessage('{FF0000}[InTool]{00FF00} Подозрение на чит: ' .. Rnikos .. '[' .. ridos .. ']' .. '. Желаете за ним проследить? R - Да. P - Нет.')
            active_forma = true
            lua_thread.create(function()
                lasttime = os.time()
                lasttimes = 0
                time_out = 10
                while lasttimes < time_out do
                    lasttimes = os.time() - lasttime
                    wait(0)
                    printStyledString("REPORT " .. time_out - lasttimes .. " WAIT", 1000, 4)
                    if stop_forma then
                        printStyledString('Form already accepted', 1000, 4)
                        stop_forma = false
                        break
                    end
                    if lasttimes == time_out then
                        printStyledString("TIME OUT", 1000, 4)
                    end
                    if isKeyJustPressed(VK_R) and not sampIsChatInputActive() and not sampIsDialogActive() then
                        sampSendChat("/re " .. ridos)
                        active_forma = false
                        break
                    elseif isKeyJustPressed(VK_P) and not sampIsChatInputActive() and not sampIsDialogActive() then
                        active_forma = false
                        break
                    end
                end
            end)
        end
    end
    if #reports > 0 then
        for k, v in pairs(reports) do
            if k == 1 then
                if not tableOfNew.AutoReport[0] then
                    if text:find('%[.%] (.*)%[(%d+)%] ответил игроку '..reports[1].nickname..'%['..reports[1].id..'%]: (.*)') then
                        refresh_current_report()
                    end
                end
            elseif #reports > 1 then
                if text:find('%[.%] (.*)%[(%d+)%] ответил игроку '..reports[k].nickname..'%['..reports[k].id..'%]: (.*)') then
                    table.remove(reports, k)
                end
            end
        end
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if elements.checkbox.autoCome[0] then
        if elements.checkbox.adminPassword ~= '' then
            lua_thread.create(function()
                while true do
                    wait(0)
                    if title:match("Доступ к панели (.*)") then
                        sampSendDialogResponse(sampGetCurrentDialogId(), 1, _, confq.config.adminPassword)
                        sampCloseCurrentDialogWithButton(0)
                        break
                    end
                end
            end)
        else
            sampAddChatMessage('{FF0000}[Ошибка] {FF8C00}Авто-вход не будет произведён, по-скольку вы не указали админ-пароль.')
            elements.checkbox.autoCome[0] = false
            confq.config.autoCome = elements.checkbox.autoCome[0]
            save()
        end
	end
end

function sampev.onShowMenu()
	if rInfo.id ~= -1 then
		return false
	end
end
function sampev.onHideMenu()
	if rInfo.id ~= -1 then
		return false
	end
end

function sampGetPlayerIdByNickname(nick)
    nick = tostring(nick)
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if nick == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1003 do
      if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then
        return i
      end
    end
end

function sampev.onShowTextDraw(textdrawId, data)
    local idPlayer = data.text:match("~n~(%d+)")
    if idPlayer then
        rInfo.id = tonumber(idPlayer)
        rInfo.state = true
    end
    if tableOfNew.reconmenu[0] then
        local minX = 49 -- Минимальная координата x
        local maxX = 582 -- Максимальная координата x
        local minY = 142 -- Минимальная координата y
        local maxY = 274 -- Максимальная координата y
        if data.position.x >= math.floor(minX) and data.position.x <= math.floor(maxX) and data.position.y >= math.floor(minY) and data.position.y <= math.floor(maxY) then
            data.position = { x = -22000, -22000, -22000, y = -22222, 22222, 22222 }
            return {textdrawId, data}
        end
    end
end

function getAmmoRecon()
	local result, recon_handle = sampGetCharHandleBySampPlayerId(rInfo.id)
	if result then
		local weapon = getCurrentCharWeapon(recon_handle)
		local struct = getCharPointer(recon_handle) + 0x5A0 + getWeapontypeSlot(weapon) * 0x1C
		return getStructElement(struct, 0x8, 4)
	end
end

function sampev.onTogglePlayerSpectating(state)
	rInfo.state = state
	if not state then
		rInfo.id = -1
        rInfo.tip = 'none'
        rInfo.playerId = -1
        rInfo.vehicleId = -1
    end
end

function cmd_osk(arg)
    if items.sorkcomm.osk[0] == true then
        sampShowDialog(250, 'Выберите пункт', massiv.dialogOskk, 'Тыкнуть', 'Закрыть', 2)
    end
    lua_thread.create(function()
        jopa = arg
    end)
end

function cmd_che(arg)
    if #arg == 0 then
        sampAddChatMessage('{FF0000}[InTool] {00FF00}Введите /twink ID')
    else
        lua_thread.create(function()
            cip = true
            sampSendChat('/getip ' .. arg)
            wait(1000)
            sampSendChat('/pgetip ' .. cip_cip)
            wait(1000)
            cip = false
        end)
    end
end

function cmd_basa(arg)
    local nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)))
    lua_thread.create(function()
        if massiv.imCarrot[0] then
            if #arg == 0 then
                sampSendChat('/veh 522 3 3 0')
            else
                sampSendChat('/re ' .. arg)
                wait(1000)
                if tableOfNew.selectedd_item[0] == 0 then
                    sampSendChat('/veh 411 1 1 0')
                elseif tableOfNew.selectedd_item[0] == 1 then
                    sampSendChat('/veh 522 1 1 0')
                elseif tableOfNew.selectedd_item[0] == 2 then
                    sampSendChat('/veh 560 3 3 0')
                end
                wait(1000)
                if carban then
                    sampAddChatMessage('{FFFF00}[InTool] {FFFFFF}Случилась ошибка при выдаче Т/С выполняю резервную функцию', -1)
                    sampSendChat('/re off')
                    wait(1000)
                    sampSendChat('/tp')
                    wait(100)
                    sampSendDialogResponse(sampGetCurrentDialogId(), 1, 9, nil)
                    sampCloseCurrentDialogWithButton()
                    wait(1000)
                    if tableOfNew.selectedd_item[0] == 0 then
                        sampSendChat('/veh 411 1 1 0')
                    elseif tableOfNew.selectedd_item[0] == 1 then
                        sampSendChat('/veh 522 1 1 0')
                    elseif tableOfNew.selectedd_item[0] == 2 then
                        sampSendChat('/veh 560 3 3 0')
                    end
                    wait(1000)
                    sampSendChat('/g ' .. arg)
                    wait(1000)
                    sampSendChat('/pm ' .. arg .. " Приятной игры на нашем сервере")
                    wait(1000)
                    sampSendChat('/re ' .. arg)
                else
                    wait(1000)
                    sampSendChat('/pm ' .. arg .. " Приятной игры на нашем сервере")
                end
            end
        else
            lua_thread.create(function()
                sampAddChatMessage('{FF0000}[InTool] {FFFFFF}Извините но вы не разрешили мне этим пользоваться.')
                wait(500)
                sampAddChatMessage('{FF0000}[InTool] {FFFFFF}Чтобы разрешить перейдите в {008000}Настройки{FFFFFF} => /car ID')
            end)
        end
    end)
end

function registercommands()
    sampRegisterChatCommand("car", cmd_basa)
    sampRegisterChatCommand('nap', cmd_churka)
    sampRegisterChatCommand('otb', cmd_otbor)
    sampRegisterChatCommand('tool', cmd_tool)
    sampRegisterChatCommand('sp', cmd_spv)
    sampRegisterChatCommand('otv', cmd_otv)
    sampRegisterChatCommand('twink', cmd_che)
    sampRegisterChatCommand('dm', cmd_dm)
    sampRegisterChatCommand('sk', cmd_sk)
    sampRegisterChatCommand('tk', cmd_tk)
    sampRegisterChatCommand('ch', cmd_ch)
    sampRegisterChatCommand('nrp', cmd_nrp)
    sampRegisterChatCommand('osk', cmd_osk)
    sampRegisterChatCommand('orp', cmd_orp)
    sampRegisterChatCommand('getherecar', carId)
    sampRegisterChatCommand('testsss', getSum)
end

function getSum()
    local tess = sumValuesForWeek(top3)
    sampAddChatMessage(cjson.encode(tess), -1)
end

function carId(idCar)
    if idCar ~= '' then
        if idCar:find('%d+') then
            local id = idCar:match('(%d+)')
            local result, vehicleHandle = sampGetCarHandleBySampVehicleId(id)
            if result then
                my_pos = {getCharCoordinates(playerPed)}
                setCarCoordinates(vehicleHandle, my_pos[1] + 4, my_pos[2], my_pos[3])
            end
        else
            sampAddChatMessage('{{FF0000}[InTool]{FFFFFF} Вы ввели некорректынй [idCar]')
        end
    else    
        sampAddChatMessage('{FF0000}[InTool]{FFFFFF} Вы не ввели [idCar]')
    end
end

function downloadFiles()
    if not doesDirectoryExist(getWorkingDirectory() .. '/InTool') then
        createDirectory(getWorkingDirectory() .. '/InTool')
        downloadUrlToFile('https://raw.githubusercontent.com/Vladislave232/scripts/main/settings.jpg', getWorkingDirectory() .. '/InTool/settings.jpg', function(id, status)
        end)
        downloadUrlToFile('https://raw.githubusercontent.com/Vladislave232/scripts/main/banner.jpg', getWorkingDirectory() .. '/InTool/banner.jpg', function(id, status)
        end)
        downloadUrlToFile('https://raw.githubusercontent.com/Vladislave232/scripts/main/logos1.png', getWorkingDirectory() .. '/InTool/logos1.png', function(id, status)
        end)
        if not doesFileExist(direcories.number1) then
            downloadUrlToFile("https://zvukogram.com/index.php?r=site/download&id=43909", direcories.number1, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                end
            end)
        end
        if not doesFileExist(direcories.number2) then
            downloadUrlToFile('https://zvukogram.com/index.php?r=site/download&id=43819', direcories.number2, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                end
            end)
        end
        if not doesFileExist(getWorkingDirectory() .. '/INCrasher.lua') then
            downloadUrlToFile('https://raw.githubusercontent.com/Vladislave232/scripts/main/EkbToolCrasher.lua', (getWorkingDirectory() .. '/INCrasher.lua'), function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage('{00FFFF}[InTool] Обнаружен файл! Чтобы он работал перезапустите скрипт! CTRL + R', -1)
                end
            end)
        end
        sampAddChatMessage('Скрипт вынужден перезапуститься чтобы подгрузить все файлы', -1)
        thisScript():reload()
    end
end

function fortimer()
    if not doesFileExist('moonloader/config/TimerOnline.ini') then
        if inicfg.save(cfg, 'TimerOnline.ini') then sampfuncsLog(checkbox.statistics.tag..'Создан файл конфигурации: TimerOnline.ini') end
    end
     if cfg.onDay.today ~= os.date("%a") then 
        cfg.onDay.today = os.date("%a")
        cfg.onDay.online = 0
        cfg.onDay.full = 0
        cfg.onDay.afk = 0
        cfg.onDay.reports = 0
        cfg.onDay.nakaz = 0
        checkbox.statistics.dayFull[0] = 0
        inicfg.save(cfg, 'TimerOnline.ini')
    end

    if cfg.onWeek.week ~= number_week() then
        cfg.onWeek.week = number_week()
        cfg.onWeek.online = 0
        cfg.onWeek.full = 0
        cfg.onWeek.afk = 0
        cfg.onWeek.report = 0
        cfg.onWeek.nakaz = 0
        checkbox.statistics.weekFull[0] = 0
        for _, v in pairs(cfg.myWeekOnline) do v = 0 end            
        inicfg.save(cfg, 'TimerOnline.ini')
    end
end

function getlist()
    async_http_request('GET', 'https://grandmanager.space/inferno/top', {
            headers = {
                ['Content-Type'] = 'application/json'
            },
        },
        function(response)
            if response.status_code == 200 then
                if not response.text then
                    return
                else

                    local RESULT = cjson.decode(response.text)
                    if not RESULT then
                        return
                    else
                        top3 = RESULT.data
                        for i=1, #top3 do
                            if top3[i] then
                                if top3[i].nickName then
                                    if top3[i].nickName == "Admin_Bot" then
                                        table.remove(top3, i)
                                    end
                                end
                            end
                        end
                        sortby(massiv.arraynew[0])
                    end
                end
            else
                print("Ошибка: HTTP код: " .. response.status_code)
                print("Текст ошибки: " .. response.text)
            end
        end,
        function(err)
            print("Ошибка: " .. err)
        end
    )
end
function imgui.HelpMarker(text)
	imgui.TextDisabled('(?)')
	if imgui.IsItemHovered() then
		imgui.BeginTooltip()
		imgui.PushTextWrapPos(450)
		imgui.TextUnformatted(text)
		imgui.PopTextWrapPos()
		imgui.EndTooltip()
	end
end

function getMyId()
    local result, id = sampGetPlayerIdByCharHandle(playerPed)
    if result then
        return id
    end
end

function fps_correction()
	return representIntAsFloat(readMemory(0xB7CB5C, 4, false))
end

function time()
	startTime = os.time()                                               -- "Точка отсчёта"
    connectingTime = 0
    while true do
        wait(1000)
        checkbox.statistics.nowTime = os.date("%H:%M:%S", os.time())
        if sampGetGamestate() == 3 then 								-- Игровой статус равен "Подключён к серверу" (Что бы онлайн считало только, когда, мы подключены к серверу)
	        checkbox.statistics.sesOnline[0] = checkbox.statistics.sesOnline[0] + 1 								-- Онлайн за сессию без учёта АФК
	        checkbox.statistics.sesFull[0] = os.time() - startTime 							-- Общий онлайн за сессию
	        checkbox.statistics.sesAfk[0] = checkbox.statistics.sesFull[0] - checkbox.statistics.sesOnline[0]							-- АФК за сессию

	        cfg.onDay.online = cfg.onDay.online + 1 					-- Онлайн за день без учёта АФК
	        cfg.onDay.full = checkbox.statistics.dayFull[0] + checkbox.statistics.sesFull[0] 						-- Общий онлайн за день
	        cfg.onDay.afk = cfg.onDay.full - cfg.onDay.online			-- АФК за день

	        cfg.onWeek.online = cfg.onWeek.online + 1 					-- Онлайн за неделю без учёта АФК
	        cfg.onWeek.full = checkbox.statistics.weekFull[0] + checkbox.statistics.sesFull[0] 						-- Общий онлайн за неделю
	        cfg.onWeek.afk = cfg.onWeek.full - cfg.onWeek.online		-- АФК за неделю

            local today = tonumber(os.date('%w', os.time()))
            cfg.myWeekOnline[today] = cfg.onDay.online
            
            local dodoo = tonumber(os.date('%w', os.time()))
            cfg.myWeekReport[dodoo] = cfg.onDay.reports

            local doddo = tonumber(os.date('%w', os.time()))
            cfg.myWeekNakaz[doddo] = cfg.onDay.nakaz

            connectingTime = 0
	    else
            connectingTime = connectingTime + 1                         -- Вермя подключения к серверу
	    	startTime = startTime + 1									-- Смещение начала отсчета таймеров
	    end
    end
end

function showTop()
    if skskaksa then
        local topperweek = sumValuesForWeek(top3)
        for i=1, 10 do
            imgui.PushFont(font[12])
            imgui.Separator()
            imgui.CenterColumnText(topperweek[i].nickName)
            imgui.PopFont()
            imgui.NextColumn()
            imgui.PushFont(font[25]);
            imgui.CenterColumnText(topperweek[i].totals.reportsperweek)
            imgui.NextColumn()
            imgui.CenterColumnText(topperweek[i].totals.jailsperweek)
            imgui.NextColumn()
            imgui.CenterColumnText(topperweek[i].totals.bansperweek)
            imgui.NextColumn()
            imgui.CenterColumnText(topperweek[i].totals.mutesperweek)
            imgui.NextColumn()
            coloredtop(i)
            imgui.NextColumn()
            imgui.PopFont()
        end
    else
        for i=1, 10 do
            imgui.PushFont(font[12])
            imgui.Separator()
            imgui.CenterColumnText(top3[i].nickName)
            imgui.PopFont()
            imgui.NextColumn()
            imgui.PushFont(font[25]);
            imgui.CenterColumnText(top3[i].reports)
            imgui.NextColumn()
            imgui.CenterColumnText(top3[i].jails)
            imgui.NextColumn()
            imgui.CenterColumnText(top3[i].bans)
            imgui.NextColumn()
            imgui.CenterColumnText(top3[i].mutes)
            imgui.NextColumn()
            coloredtop(i)
            imgui.NextColumn()
            imgui.PopFont()
        end
    end
end

function autoSave()
	while true do 
		wait(30000)
		inicfg.save(cfg, "TimerOnline")
	end
end

function getDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) + (z2-z1)*(z2-z1))
end
function rotateCarAroundUpAxis(car, vec)
    local function getVehicleRotationMatrix(car)
        local function readFloatArray(ptr, idx)
            return representIntAsFloat(readMemory(ptr + idx * 4, 4, false))
        end
        local entityPtr = getCarPointer(car)
        if entityPtr ~= 0 then
            local mat = readMemory(entityPtr + 0x14, 4, false)
            if mat ~= 0 then
                local rx, ry, rz, fx, fy, fz, ux, uy, uz
                rx = readFloatArray(mat, 0); ry = readFloatArray(mat, 1); rz = readFloatArray(mat, 2)
                fx = readFloatArray(mat, 4); fy = readFloatArray(mat, 5); fz = readFloatArray(mat, 6)
                ux = readFloatArray(mat, 8); uy = readFloatArray(mat, 9); uz = readFloatArray(mat, 10)
                return rx, ry, rz, fx, fy, fz, ux, uy, uz
            end
        end
    end
    local mat = require('matrix3x3')(getVehicleRotationMatrix(car))
    local rotAxis = Vector3D(mat.up:get())
    vec:normalize()
    rotAxis:normalize()
    local theta = math.acos(rotAxis:dotProduct(vec))
    if theta ~= 0 then
        rotAxis:crossProduct(vec)
        rotAxis:normalize()
        rotAxis:zeroNearZero()
        mat = mat:rotate(rotAxis, -theta)
    end
    local function setVehicleRotationMatrix(car, rx, ry, rz, fx, fy, fz, ux, uy, uz)
        local function writeFloatArray(ptr, idx, value)
            writeMemory(ptr + idx * 4, 4, representFloatAsInt(value), false)
        end
        local entityPtr = getCarPointer(car)
        if entityPtr ~= 0 then
            local mat = readMemory(entityPtr + 0x14, 4, false)
            if mat ~= 0 then
                writeFloatArray(mat, 0, rx)
                writeFloatArray(mat, 1, ry)
                writeFloatArray(mat, 2, rz)

                writeFloatArray(mat, 4, fx)
                writeFloatArray(mat, 5, fy)
                writeFloatArray(mat, 6, fz)

                writeFloatArray(mat, 8, ux)
                writeFloatArray(mat, 9, uy)
                writeFloatArray(mat, 10, uz)
            end
        end
    end
    setVehicleRotationMatrix(car, mat:get())
end
function createPointMarker(x, y, z)
    pointMarker = createUser3dMarker(x, y, z + 0.3, 4)
end
function removePointMarker()
    if pointMarker then
        removeUser3dMarker(pointMarker)
        pointMarker = nil
    end
end
function renderFontDrawTextCenter(font, text, x, y, color)
    return renderFontDrawText(font, text, x-tonumber(renderGetFontDrawTextLength(font, text))/2, y, color)
end
function jumpIntoCar(car)
    local function getCarFreeSeat(car)
        if doesCharExist(getDriverOfCar(car)) then
            local maxPassengers = getMaximumNumberOfPassengers(car)
            for i = 0, maxPassengers do
                if isCarPassengerSeatFree(car, i) then
                    return i + 1
                end
            end
            return nil -- no free seats
        else
            return 0 -- driver seat
        end
    end
    local seat = getCarFreeSeat(car)
    if not seat then return false end                         -- no free seats
    if seat == 0 then warpCharIntoCar(playerPed, car)         -- driver seat
    else warpCharIntoCarAsPassenger(playerPed, car, seat - 1) -- passenger seat
    end
    restoreCameraJumpcut()
    return true
end
function teleportPlayer(x, y, z)
    if isCharInAnyCar(playerPed) then setCharCoordinates(playerPed, x, y, z) end
    local function setEntityCoordinates(entityPtr, x, y, z)
        if entityPtr ~= 0 then
            local matrixPtr = readMemory(entityPtr + 0x14, 4, false)
            if matrixPtr ~= 0 then
                local posPtr = matrixPtr + 0x30
                writeMemory(posPtr + 0, 4, representFloatAsInt(x), false) -- X
                writeMemory(posPtr + 4, 4, representFloatAsInt(y), false) -- Y
                writeMemory(posPtr + 8, 4, representFloatAsInt(z), false) -- Z
            end
        end
    end
    local function setCharCoordinatesDontResetAnim(char, x, y, z)
        if doesCharExist(char) then
            local ptr = getCharPointer(char)
            setEntityCoordinates(ptr, x, y, z)
        end
    end
    setCharCoordinatesDontResetAnim(playerPed, x, y, z)
end
function setCameraDistanceActivated(active)
	memory.setuint8(0xB6F028 + 0x38, active)
	memory.setuint8(0xB6F028 + 0x39, active)
end
function setCameraDistance(distance)
	memory.setfloat(0xB6F028 + 0xD4, distance)
	memory.setfloat(0xB6F028 + 0xD8, distance)
	memory.setfloat(0xB6F028 + 0xC0, distance)
	memory.setfloat(0xB6F028 + 0xC4, distance)
end
function setValueCameraDistance(distance)
	local cam = camera_settings.distance - distance
    local cam_max = 15+3
	if cam <= 1 or cam >= cam_max then
		return false
	else
		printStringNow('Recon Camera: ~G~'..cam-2, 1000)
		camera_settings.distance = cam
	end
end

function sampev.onSpectatePlayer(playerId, camType)
    rInfo.tip = 'player'
    rInfo.playerId = playerId
    if playerId and playerId ~= -1 then
        rInfo.id = playerId
    end
end
function sampev.onSpectateVehicle(vehicleId, camType)
    rInfo.tip = 'vehicle'
    rInfo.vehicleId = vehicleId
end

function _sampSendChat(message, length) 
    length = length or #message
    repeat
        sampSendChat('/a << Репорт >> '..message:sub(1, length))
        message = message:sub(length + 1, #message)
        if #message > 0 then wait(1000) end
    until #message <= 0
end

function sampev.onSendSpectatorSync(data)
    if rInfo.process_teleport then
        rInfo.count = rInfo.count + 1
        if rInfo.count <= 8 then
            data.position.x = rInfo.position.x
            data.position.y = rInfo.position.y-2 -- /gethere -> прибавит координаты Y+2
            data.position.z = rInfo.position.z
            if rInfo.count == 3 then
                sampSendChat(rInfo.command)
            end
        else
            rInfo.process_teleport = false
            rInfo.count = 0
        end
    elseif rInfo.tip == 'player' and rInfo.playerId ~= -1 and sampIsPlayerConnected(rInfo.playerId) then
        local result, ped = sampGetCharHandleBySampPlayerId(rInfo.playerId)
        if result then
            local pX, pY, pZ = getCharCoordinates(ped)
            local sX, sY, sZ = data.position.x, data.position.y, data.position.z
            local distance = getDistance(pX, pY, pZ, sX, sY, sZ)
            if distance < 50 then
                data.position.x = pX
                data.position.y = pY
                data.position.z = pZ
            end
        end
    elseif rInfo.tip == 'vehicle' and rInfo.vehicleId ~= -1 then
        local result, car = sampGetCarHandleBySampVehicleId(rInfo.vehicleId)
        if result then
            if doesCarHaveHydraulics(car) then
                sampAddChatMessage('Disabled Hydraulics This Vehicle!', -1)
                setCarHydraulics(car, false)
            end
            local cX, cY, cZ = getCarCoordinates(car)
            local sX, sY, sZ = data.position.x, data.position.y, data.position.z
            local distance = getDistance(cX, cY, cZ, sX, sY, sZ)
            if distance < 50 then 
                data.position.x = cX
                data.position.y = cY
                data.position.z = cZ
            end
        end
    end
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() and not restart then 
		inicfg.save(cfg, 'TimerOnline.ini')
        setShowCursor(false)
        removePointMarker()
	end
    save()
end

function number_week() -- получение номера недели в году
    local current_time = os.date'*t'
    local start_year = os.time{ year = current_time.year, day = 1, month = 1 }
    local week_day = ( os.date('%w', start_year) - 1 ) % 7
    return math.ceil((current_time.yday + week_day) / 7)
end

function getStrDate(unixTime)
    local tMonths = {'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'}
    local day = tonumber(os.date('%d', unixTime))
    local month = tMonths[tonumber(os.date('%m', unixTime))]
    local weekday = tWeekdays[tonumber(os.date('%w', unixTime))]
    return string.format('%s, %s %s', weekday, day, month)
end


function get_clock(time)
    local timezone_offset = 86400 - os.date('%H', 0) * 3600
    if tonumber(time) >= 86400 then 
        onDay = true 
    else 
        onDay = false 
    end
    return os.date((onDay and math.floor(time / 86400)..'д ' or '')..'%H:%M:%S', time + timezone_offset)
end

function KeyCap(keyName, isPressed, size)
	local DL = imgui.GetWindowDrawList()
	local p = imgui.GetCursorScreenPos()
	local colors = {
		[true] = imgui.ImVec4(0.60, 0.60, 1.00, 1.00),
		[false] = imgui.ImVec4(0.60, 0.60, 1.00, 0.10)
	}

	if KEYCAP == nil then KEYCAP = {} end
	if KEYCAP[keyName] == nil then
		KEYCAP[keyName] = {
			status = isPressed,
			color = colors[isPressed],
			timer = nil
		}
	end

	local K = KEYCAP[keyName]
	if isPressed ~= K.status then
		K.status = isPressed
		K.timer = os.clock()
	end

	local rounding = 3.0
	local A = imgui.ImVec2(p.x, p.y)
	local B = imgui.ImVec2(p.x + size.x, p.y + size.y)
	if K.timer ~= nil then
		K.color = bringVec4To(colors[not isPressed], colors[isPressed], K.timer, 0.1)
	end
	local ts = imgui.CalcTextSize(keyName)
	local text_pos = imgui.ImVec2(p.x + (size.x / 2) - (ts.x / 2), p.y + (size.y / 2) - (ts.y / 2))

	imgui.Dummy(size)
	DL:AddRectFilled(A, B, u32(K.color), rounding)
	DL:AddRect(A, B, u32(colors[true]), rounding, _, 1)
	DL:AddText(text_pos, 0xFFFFFFFF, keyName)
end

function bringVec4To(from, dest, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return imgui.ImVec4(
            from.x + (count * (dest.x - from.x) / 100),
            from.y + (count * (dest.y - from.y) / 100),
            from.z + (count * (dest.z - from.z) / 100),
            from.w + (count * (dest.w - from.w) / 100)
        ), true
    end
    return (timer > duration) and dest or from, false
end

function sampev.onPlayerSync(playerId, data)
	local result, id = sampGetPlayerIdByCharHandle(target)
	if result and id == playerId then
		keys["onfoot"] = {}

		keys["onfoot"]["W"] = (data.upDownKeys == 65408) or nil
		keys["onfoot"]["A"] = (data.leftRightKeys == 65408) or nil
		keys["onfoot"]["S"] = (data.upDownKeys == 00128) or nil
		keys["onfoot"]["D"] = (data.leftRightKeys == 00128) or nil

		keys["onfoot"]["Alt"] = (bit.band(data.keysData, 1024) == 1024) or nil
		keys["onfoot"]["Shift"] = (bit.band(data.keysData, 8) == 8) or nil
		keys["onfoot"]["Space"] = (bit.band(data.keysData, 32) == 32) or nil
		keys["onfoot"]["F"] = (bit.band(data.keysData, 16) == 16) or nil
		keys["onfoot"]["C"] = (bit.band(data.keysData, 2) == 2) or nil

		keys["onfoot"]["RKM"] = (bit.band(data.keysData, 4) == 4) or nil
		keys["onfoot"]["LKM"] = (bit.band(data.keysData, 128) == 128) or nil
	end
end

function sampev.onVehicleSync(playerId, vehicleId, data)
	local result, id = sampGetPlayerIdByCharHandle(target)
	if result and id == playerId then
		keys["vehicle"] = {}

		keys["vehicle"]["W"] = (bit.band(data.keysData, 8) == 8) or nil
		keys["vehicle"]["A"] = (data.leftRightKeys == 65408) or nil
		keys["vehicle"]["S"] = (bit.band(data.keysData, 32) == 32) or nil
		keys["vehicle"]["D"] = (data.leftRightKeys == 00128) or nil

		keys["vehicle"]["H"] = (bit.band(data.keysData, 2) == 2) or nil
		keys["vehicle"]["Space"] = (bit.band(data.keysData, 128) == 128) or nil
		keys["vehicle"]["Ctrl"] = (bit.band(data.keysData, 1) == 1) or nil
		keys["vehicle"]["Alt"] = (bit.band(data.keysData, 4) == 4) or nil
		keys["vehicle"]["Q"] = (bit.band(data.keysData, 256) == 256) or nil
		keys["vehicle"]["E"] = (bit.band(data.keysData, 64) == 64) or nil
		keys["vehicle"]["F"] = (bit.band(data.keysData, 16) == 16) or nil

		keys["vehicle"]["Up"] = (data.upDownKeys == 65408) or nil
		keys["vehicle"]["Down"] = (data.upDownKeys == 00128) or nil
	end
end

function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end

function imgui.CenterTextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

function wallhack()
end

function argb2abgr(argb)
    local abgr = bit.bor(
        bit.lshift(bit.band(bit.rshift(argb, 24), 0xFF), 24),
        bit.lshift(bit.band(argb, 0xFF), 16),
        bit.lshift(bit.band(bit.rshift(argb, 8), 0xFF), 8),
        bit.band(bit.rshift(argb, 16), 0xFF)
    )
    return abgr
end

function explode_argb(argb)
    local a = bit.band(bit.rshift(argb, 24), 0xFF)
    local r = bit.band(bit.rshift(argb, 16), 0xFF)
    local g = bit.band(bit.rshift(argb, 8), 0xFF)
    local b = bit.band(argb, 0xFF)
    return a, r, g, b
end

function sampev.onBulletSync(playerid, data)
    if elements.checkbox.bulletTracer[0] then
        if data.center.x ~= 0 then
            if data.center.y ~= 0 then
                if data.center.z ~= 0 then
                    bulletSync.lastId = bulletSync.lastId + 1
                    if bulletSync.lastId < 1 or bulletSync.lastId > bulletSync.maxLines then
                        bulletSync.lastId = 1
                    end
                    bulletSync[bulletSync.lastId].other.time = os.time() + elements.int.secondToClose[0]
                    bulletSync[bulletSync.lastId].other.o.x, bulletSync[bulletSync.lastId].other.o.y, bulletSync[bulletSync.lastId].other.o.z = data.origin.x, data.origin.y, data.origin.z
                    bulletSync[bulletSync.lastId].other.t.x, bulletSync[bulletSync.lastId].other.t.y, bulletSync[bulletSync.lastId].other.t.z = data.target.x, data.target.y, data.target.z
                    if data.targetType == 0 then
                        --bulletSync[bulletSync.lastId].other.color = argb2abgr(255, confq.config.staticObject)
                        bulletSync[bulletSync.lastId].other.color = argb2abgr(confq.config.staticObject)
                    elseif data.targetType == 1 then
                        bulletSync[bulletSync.lastId].other.color = argb2abgr(confq.config.pedP)
                    elseif data.targetType == 2 then
                        bulletSync[bulletSync.lastId].other.color = argb2abgr(confq.config.carP)
                    elseif data.targetType == 3 then
                        bulletSync[bulletSync.lastId].other.color = argb2abgr(confq.config.dinamicObject)
                    end
                end
            end
        end
    end
end

function getBodyPartCoordinates(id, handle)
    local pedptr = getCharPointer(handle)
    local vec = ffi.new("float[3]")
    getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
    return vec[0], vec[1], vec[2]
end

function join_argb(a, r, g, b)
    local argb = b  -- b
    argb = bit.bor(argb, bit.lshift(g, 8))  -- g
    argb = bit.bor(argb, bit.lshift(r, 16)) -- r
    argb = bit.bor(argb, bit.lshift(a, 24)) -- a
    return argb
end

function imgui.faButton(text, width)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.00, 1.00, 1.00, 0.00))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(1.00, 1.00, 1.00, 0.00))
    imgui.Button(text, width)
    imgui.PopStyleColor(2)
end

function save()
    inicfg.save(confq, "setap.ini")
end



function async_http_request(method, url, args, resolve, reject)
    local lanes = require('lanes')
    local request_lane = lanes.gen('*', {package = {path = package.path, cpath = package.cpath}}, function()
        local requests = require 'requests'
        local ok, result = pcall(requests.request, method, url, args)
        if ok then
            result.json, result.xml = nil, nil -- cannot be passed through a lane
            return true, result
        else
            return false, result -- return error
        end
    end)
    if not reject then reject = function() end end
    lua_thread.create(function()
        local lh = request_lane()
        while true do
            local status = lh.status
            if status == 'done' then
                local ok, result = lh[1], lh[2]
                if ok then resolve(result) else reject(result) end
                return
            elseif status == 'error' then
                return reject(lh[1])
            elseif status == 'killed' or status == 'cancelled' then
                return reject(status)
            end
            wait(0)
        end
    end)
end

function imgui.thememoonmonet(chroma_multiplier, accurate_shades)
    local color = 0x00008b 
    local vec2, vec4 = imgui.ImVec2, imgui.ImVec4
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local flags = imgui.Col

    do -- style
        style.WindowPadding = imgui.ImVec2(8, 8)
        style.FramePadding = imgui.ImVec2(5, 5)
        style.ItemSpacing = imgui.ImVec2(5, 5)
        style.ItemInnerSpacing = imgui.ImVec2(2, 2)
        style.TouchExtraPadding = imgui.ImVec2(0, 0)
        style.IndentSpacing = 0
        style.ScrollbarSize = 10
        style.GrabMinSize = 10
        style.WindowBorderSize = 1
        style.ChildBorderSize = 1
    
        style.PopupBorderSize = 1
        style.FrameBorderSize = 1
        style.TabBorderSize = 1
        style.WindowRounding = 10
        style.ChildRounding = 0
        style.FrameRounding = 8
        style.PopupRounding = 10
        style.ScrollbarRounding = 10
        style.GrabRounding = 10
        style.TabRounding = 10
        style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
        style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
        style.SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    end

    do -- colors
        local function to_vec4(u32)
            local a = bit.band(bit.rshift(u32, 24), 0xFF) / 0xFF
            local r = bit.band(bit.rshift(u32, 16), 0xFF) / 0xFF
            local g = bit.band(bit.rshift(u32, 8), 0xFF) / 0xFF
            local b = bit.band(u32, 0xFF) / 0xFF
            return imgui.ImVec4(r, g, b, a)
        end

        local monet = require('MoonMonet')
        local palette = monet.buildColors(color, chroma_multiplier, accurate_shades)

        colors[flags.Text] = to_vec4(palette.neutral1.color_100)
        -- colors[flags.TextDisabled] = ImVec4
        colors[flags.WindowBg] = to_vec4(palette.accent1.color_900)
        colors[flags.ChildBg] = to_vec4(palette.accent2.color_800)
        colors[flags.PopupBg] = to_vec4(palette.accent2.color_800)
        colors[flags.Border] = to_vec4(palette.neutral1.color_1000)
        colors[flags.FrameBg] = to_vec4(palette.accent1.color_800)
        colors[flags.FrameBgHovered] = to_vec4(palette.accent1.color_700)
        colors[flags.FrameBgActive] = to_vec4(palette.accent1.color_600)
        -- colors[flags.TitleBg] = ImVec4
        colors[flags.TitleBgActive] = to_vec4(palette.accent1.color_800)
        -- colors[flags.TitleBgCollapsed] = ImVec4
        -- colors[flags.MenuBarBg] = ImVec4
        colors[flags.ScrollbarBg] = to_vec4(palette.accent1.color_800)
        colors[flags.ScrollbarGrab] = to_vec4(palette.accent2.color_600)
        colors[flags.ScrollbarGrabHovered] = to_vec4(palette.accent2.color_500)
        colors[flags.ScrollbarGrabActive] = to_vec4(palette.accent2.color_400)
        colors[flags.CheckMark] = to_vec4(palette.neutral1.color_50)
        colors[flags.SliderGrab] = to_vec4(palette.accent2.color_500)
        colors[flags.SliderGrabActive] = to_vec4(palette.accent2.color_400)
        colors[flags.Button] = to_vec4(palette.accent1.color_700)
        colors[flags.ButtonHovered] = to_vec4(palette.accent1.color_400)
        colors[flags.ButtonActive] = to_vec4(palette.accent1.color_300)
        colors[flags.Header] = to_vec4(palette.accent1.color_800)
        colors[flags.HeaderHovered] = to_vec4(palette.accent1.color_700)
        colors[flags.HeaderActive] = to_vec4(palette.accent1.color_600)
        colors[flags.Separator] = to_vec4(palette.accent2.color_200)
        colors[flags.SeparatorHovered] = to_vec4(palette.accent2.color_100)
        colors[flags.SeparatorActive] = to_vec4(palette.accent2.color_50)
        colors[flags.ResizeGrip] = to_vec4(palette.accent2.color_900)
        colors[flags.ResizeGripHovered] = to_vec4(palette.accent2.color_800)
        colors[flags.ResizeGripActive] = to_vec4(palette.accent2.color_700)
        colors[flags.Tab] = to_vec4(palette.accent1.color_700)
        colors[flags.TabHovered] = to_vec4(palette.accent1.color_600)
        colors[flags.TabActive] = to_vec4(palette.accent1.color_500)
        -- colors[flags.TabUnfocused] = ImVec4
        -- colors[flags.TabUnfocusedActive] = ImVec4
        colors[flags.PlotLines] = to_vec4(palette.accent3.color_300)
        colors[flags.PlotLinesHovered] = to_vec4(palette.accent3.color_50)
        colors[flags.PlotHistogram] = to_vec4(palette.accent3.color_300)
        colors[flags.PlotHistogramHovered] = to_vec4(palette.accent3.color_50)
        -- colors[flags.TextSelectedBg] = ImVec4
        colors[flags.DragDropTarget] = to_vec4(palette.accent3.color_700)
        -- colors[flags.NavHighlight] = ImVec4
        -- colors[flags.NavWindowingHighlight] = ImVec4
        -- colors[flags.NavWindowingDimBg] = ImVec4
        -- colors[flags.ModalWindowDimBg] = ImVec4
    end
end

function imgui.thememoonpurple(chroma_multiplier, accurate_shades)
    local color = 0x310062
    local vec2, vec4 = imgui.ImVec2, imgui.ImVec4
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local flags = imgui.Col

    do -- style
        style.WindowPadding = imgui.ImVec2(8, 8)
        style.FramePadding = imgui.ImVec2(5, 5)
        style.ItemSpacing = imgui.ImVec2(5, 5)
        style.ItemInnerSpacing = imgui.ImVec2(2, 2)
        style.TouchExtraPadding = imgui.ImVec2(0, 0)
        style.IndentSpacing = 0
        style.ScrollbarSize = 10
        style.GrabMinSize = 10
        style.WindowBorderSize = 1
        style.ChildBorderSize = 1
    
        style.PopupBorderSize = 1
        style.FrameBorderSize = 1
        style.TabBorderSize = 1
        style.WindowRounding = 10
        style.ChildRounding = 0
        style.FrameRounding = 8
        style.PopupRounding = 10
        style.ScrollbarRounding = 10
        style.GrabRounding = 10
        style.TabRounding = 10
        style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
        style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
        style.SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    end

    do -- colors
        local function to_vec4(u32)
            local a = bit.band(bit.rshift(u32, 24), 0xFF) / 0xFF
            local r = bit.band(bit.rshift(u32, 16), 0xFF) / 0xFF
            local g = bit.band(bit.rshift(u32, 8), 0xFF) / 0xFF
            local b = bit.band(u32, 0xFF) / 0xFF
            return imgui.ImVec4(r, g, b, a)
        end

        local monet = require('MoonMonet')
        local palette = monet.buildColors(color, chroma_multiplier, accurate_shades)

        colors[flags.Text] = to_vec4(palette.neutral1.color_100)
        -- colors[flags.TextDisabled] = ImVec4
        colors[flags.WindowBg] = to_vec4(palette.accent1.color_900)
        colors[flags.ChildBg] = to_vec4(palette.accent2.color_800)
        colors[flags.PopupBg] = to_vec4(palette.accent2.color_800)
        colors[flags.Border] = to_vec4(palette.neutral1.color_1000)
        colors[flags.FrameBg] = to_vec4(palette.accent1.color_800)
        colors[flags.FrameBgHovered] = to_vec4(palette.accent1.color_700)
        colors[flags.FrameBgActive] = to_vec4(palette.accent1.color_600)
        -- colors[flags.TitleBg] = ImVec4
        colors[flags.TitleBgActive] = to_vec4(palette.accent1.color_800)
        -- colors[flags.TitleBgCollapsed] = ImVec4
        -- colors[flags.MenuBarBg] = ImVec4
        colors[flags.ScrollbarBg] = to_vec4(palette.accent1.color_800)
        colors[flags.ScrollbarGrab] = to_vec4(palette.accent2.color_600)
        colors[flags.ScrollbarGrabHovered] = to_vec4(palette.accent2.color_500)
        colors[flags.ScrollbarGrabActive] = to_vec4(palette.accent2.color_400)
        colors[flags.CheckMark] = to_vec4(palette.neutral1.color_50)
        colors[flags.SliderGrab] = to_vec4(palette.accent2.color_500)
        colors[flags.SliderGrabActive] = to_vec4(palette.accent2.color_400)
        colors[flags.Button] = to_vec4(palette.accent1.color_700)
        colors[flags.ButtonHovered] = to_vec4(palette.accent1.color_400)
        colors[flags.ButtonActive] = to_vec4(palette.accent1.color_300)
        colors[flags.Header] = to_vec4(palette.accent1.color_800)
        colors[flags.HeaderHovered] = to_vec4(palette.accent1.color_700)
        colors[flags.HeaderActive] = to_vec4(palette.accent1.color_600)
        colors[flags.Separator] = to_vec4(palette.accent2.color_200)
        colors[flags.SeparatorHovered] = to_vec4(palette.accent2.color_100)
        colors[flags.SeparatorActive] = to_vec4(palette.accent2.color_50)
        colors[flags.ResizeGrip] = to_vec4(palette.accent2.color_900)
        colors[flags.ResizeGripHovered] = to_vec4(palette.accent2.color_800)
        colors[flags.ResizeGripActive] = to_vec4(palette.accent2.color_700)
        colors[flags.Tab] = to_vec4(palette.accent1.color_700)
        colors[flags.TabHovered] = to_vec4(palette.accent1.color_600)
        colors[flags.TabActive] = to_vec4(palette.accent1.color_500)
        -- colors[flags.TabUnfocused] = ImVec4
        -- colors[flags.TabUnfocusedActive] = ImVec4
        colors[flags.PlotLines] = to_vec4(palette.accent3.color_300)
        colors[flags.PlotLinesHovered] = to_vec4(palette.accent3.color_50)
        colors[flags.PlotHistogram] = to_vec4(palette.accent3.color_300)
        colors[flags.PlotHistogramHovered] = to_vec4(palette.accent3.color_50)
        -- colors[flags.TextSelectedBg] = ImVec4
        colors[flags.DragDropTarget] = to_vec4(palette.accent3.color_700)
        -- colors[flags.NavHighlight] = ImVec4
        -- colors[flags.NavWindowingHighlight] = ImVec4
        -- colors[flags.NavWindowingDimBg] = ImVec4
        -- colors[flags.ModalWindowDimBg] = ImVec4
    end
end

function imgui.themoongreen(chroma_multiplier, accurate_shades)
    local color = 0x00FF00
    local vec2, vec4 = imgui.ImVec2, imgui.ImVec4
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local flags = imgui.Col

    do -- style
        style.WindowPadding = imgui.ImVec2(8, 8)
        style.FramePadding = imgui.ImVec2(5, 5)
        style.ItemSpacing = imgui.ImVec2(5, 5)
        style.ItemInnerSpacing = imgui.ImVec2(2, 2)
        style.TouchExtraPadding = imgui.ImVec2(0, 0)
        style.IndentSpacing = 0
        style.ScrollbarSize = 10
        style.GrabMinSize = 10
        style.WindowBorderSize = 1
        style.ChildBorderSize = 1
    
        style.PopupBorderSize = 1
        style.FrameBorderSize = 1
        style.TabBorderSize = 1
        style.WindowRounding = 10
        style.ChildRounding = 0
        style.FrameRounding = 8
        style.PopupRounding = 10
        style.ScrollbarRounding = 10
        style.GrabRounding = 10
        style.TabRounding = 10
        style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
        style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
        style.SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    end

    do -- colors
        local function to_vec4(u32)
            local a = bit.band(bit.rshift(u32, 24), 0xFF) / 0xFF
            local r = bit.band(bit.rshift(u32, 16), 0xFF) / 0xFF
            local g = bit.band(bit.rshift(u32, 8), 0xFF) / 0xFF
            local b = bit.band(u32, 0xFF) / 0xFF
            return imgui.ImVec4(r, g, b, a)
        end

        local monet = require('MoonMonet')
        local palette = monet.buildColors(color, chroma_multiplier, accurate_shades)

        colors[flags.Text] = to_vec4(palette.neutral1.color_100)
        -- colors[flags.TextDisabled] = ImVec4
        colors[flags.WindowBg] = to_vec4(palette.accent1.color_900)
        colors[flags.ChildBg] = to_vec4(palette.accent2.color_800)
        colors[flags.PopupBg] = to_vec4(palette.accent2.color_800)
        colors[flags.Border] = to_vec4(palette.neutral1.color_1000)
        colors[flags.FrameBg] = to_vec4(palette.accent1.color_800)
        colors[flags.FrameBgHovered] = to_vec4(palette.accent1.color_700)
        colors[flags.FrameBgActive] = to_vec4(palette.accent1.color_600)
        -- colors[flags.TitleBg] = ImVec4
        colors[flags.TitleBgActive] = to_vec4(palette.accent1.color_800)
        -- colors[flags.TitleBgCollapsed] = ImVec4
        -- colors[flags.MenuBarBg] = ImVec4
        colors[flags.ScrollbarBg] = to_vec4(palette.accent1.color_800)
        colors[flags.ScrollbarGrab] = to_vec4(palette.accent2.color_600)
        colors[flags.ScrollbarGrabHovered] = to_vec4(palette.accent2.color_500)
        colors[flags.ScrollbarGrabActive] = to_vec4(palette.accent2.color_400)
        colors[flags.CheckMark] = to_vec4(palette.neutral1.color_50)
        colors[flags.SliderGrab] = to_vec4(palette.accent2.color_500)
        colors[flags.SliderGrabActive] = to_vec4(palette.accent2.color_400)
        colors[flags.Button] = to_vec4(palette.accent1.color_700)
        colors[flags.ButtonHovered] = to_vec4(palette.accent1.color_400)
        colors[flags.ButtonActive] = to_vec4(palette.accent1.color_300)
        colors[flags.Header] = to_vec4(palette.accent1.color_800)
        colors[flags.HeaderHovered] = to_vec4(palette.accent1.color_700)
        colors[flags.HeaderActive] = to_vec4(palette.accent1.color_600)
        colors[flags.Separator] = to_vec4(palette.accent2.color_200)
        colors[flags.SeparatorHovered] = to_vec4(palette.accent2.color_100)
        colors[flags.SeparatorActive] = to_vec4(palette.accent2.color_50)
        colors[flags.ResizeGrip] = to_vec4(palette.accent2.color_900)
        colors[flags.ResizeGripHovered] = to_vec4(palette.accent2.color_800)
        colors[flags.ResizeGripActive] = to_vec4(palette.accent2.color_700)
        colors[flags.Tab] = to_vec4(palette.accent1.color_700)
        colors[flags.TabHovered] = to_vec4(palette.accent1.color_600)
        colors[flags.TabActive] = to_vec4(palette.accent1.color_500)
        -- colors[flags.TabUnfocused] = ImVec4
        -- colors[flags.TabUnfocusedActive] = ImVec4
        colors[flags.PlotLines] = to_vec4(palette.accent3.color_300)
        colors[flags.PlotLinesHovered] = to_vec4(palette.accent3.color_50)
        colors[flags.PlotHistogram] = to_vec4(palette.accent3.color_300)
        colors[flags.PlotHistogramHovered] = to_vec4(palette.accent3.color_50)
        -- colors[flags.TextSelectedBg] = ImVec4
        colors[flags.DragDropTarget] = to_vec4(palette.accent3.color_700)
        -- colors[flags.NavHighlight] = ImVec4
        -- colors[flags.NavWindowingHighlight] = ImVec4
        -- colors[flags.NavWindowingDimBg] = ImVec4
        -- colors[flags.ModalWindowDimBg] = ImVec4
    end
end

function imgui.themoonred(chroma_multiplier, accurate_shades)
    local color = 0x8B0000
    local vec2, vec4 = imgui.ImVec2, imgui.ImVec4
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local flags = imgui.Col

    do -- style
        style.WindowPadding = imgui.ImVec2(8, 8)
        style.FramePadding = imgui.ImVec2(5, 5)
        style.ItemSpacing = imgui.ImVec2(5, 5)
        style.ItemInnerSpacing = imgui.ImVec2(2, 2)
        style.TouchExtraPadding = imgui.ImVec2(0, 0)
        style.IndentSpacing = 0
        style.ScrollbarSize = 10
        style.GrabMinSize = 10
        style.WindowBorderSize = 1
        style.ChildBorderSize = 1
    
        style.PopupBorderSize = 1
        style.FrameBorderSize = 1
        style.TabBorderSize = 1
        style.WindowRounding = 10
        style.ChildRounding = 0
        style.FrameRounding = 8
        style.PopupRounding = 10
        style.ScrollbarRounding = 10
        style.GrabRounding = 10
        style.TabRounding = 10
        style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
        style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
        style.SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    end

    do -- colors
        local function to_vec4(u32)
            local a = bit.band(bit.rshift(u32, 24), 0xFF) / 0xFF
            local r = bit.band(bit.rshift(u32, 16), 0xFF) / 0xFF
            local g = bit.band(bit.rshift(u32, 8), 0xFF) / 0xFF
            local b = bit.band(u32, 0xFF) / 0xFF
            return imgui.ImVec4(r, g, b, a)
        end

        local monet = require('MoonMonet')
        local palette = monet.buildColors(color, chroma_multiplier, accurate_shades)

        colors[flags.Text] = to_vec4(palette.neutral1.color_100)
        -- colors[flags.TextDisabled] = ImVec4
        colors[flags.WindowBg] = to_vec4(palette.accent1.color_900)
        colors[flags.ChildBg] = to_vec4(palette.accent2.color_800)
        colors[flags.PopupBg] = to_vec4(palette.accent2.color_800)
        colors[flags.Border] = to_vec4(palette.neutral1.color_1000)
        colors[flags.FrameBg] = to_vec4(palette.accent1.color_800)
        colors[flags.FrameBgHovered] = to_vec4(palette.accent1.color_700)
        colors[flags.FrameBgActive] = to_vec4(palette.accent1.color_600)
        -- colors[flags.TitleBg] = ImVec4
        colors[flags.TitleBgActive] = to_vec4(palette.accent1.color_800)
        -- colors[flags.TitleBgCollapsed] = ImVec4
        -- colors[flags.MenuBarBg] = ImVec4
        colors[flags.ScrollbarBg] = to_vec4(palette.accent1.color_800)
        colors[flags.ScrollbarGrab] = to_vec4(palette.accent2.color_600)
        colors[flags.ScrollbarGrabHovered] = to_vec4(palette.accent2.color_500)
        colors[flags.ScrollbarGrabActive] = to_vec4(palette.accent2.color_400)
        colors[flags.CheckMark] = to_vec4(palette.neutral1.color_50)
        colors[flags.SliderGrab] = to_vec4(palette.accent2.color_500)
        colors[flags.SliderGrabActive] = to_vec4(palette.accent2.color_400)
        colors[flags.Button] = to_vec4(palette.accent1.color_700)
        colors[flags.ButtonHovered] = to_vec4(palette.accent1.color_400)
        colors[flags.ButtonActive] = to_vec4(palette.accent1.color_300)
        colors[flags.Header] = to_vec4(palette.accent1.color_800)
        colors[flags.HeaderHovered] = to_vec4(palette.accent1.color_700)
        colors[flags.HeaderActive] = to_vec4(palette.accent1.color_600)
        colors[flags.Separator] = to_vec4(palette.accent2.color_200)
        colors[flags.SeparatorHovered] = to_vec4(palette.accent2.color_100)
        colors[flags.SeparatorActive] = to_vec4(palette.accent2.color_50)
        colors[flags.ResizeGrip] = to_vec4(palette.accent2.color_900)
        colors[flags.ResizeGripHovered] = to_vec4(palette.accent2.color_800)
        colors[flags.ResizeGripActive] = to_vec4(palette.accent2.color_700)
        colors[flags.Tab] = to_vec4(palette.accent1.color_700)
        colors[flags.TabHovered] = to_vec4(palette.accent1.color_600)
        colors[flags.TabActive] = to_vec4(palette.accent1.color_500)
        -- colors[flags.TabUnfocused] = ImVec4
        -- colors[flags.TabUnfocusedActive] = ImVec4
        colors[flags.PlotLines] = to_vec4(palette.accent3.color_300)
        colors[flags.PlotLinesHovered] = to_vec4(palette.accent3.color_50)
        colors[flags.PlotHistogram] = to_vec4(palette.accent3.color_300)
        colors[flags.PlotHistogramHovered] = to_vec4(palette.accent3.color_50)
        -- colors[flags.TextSelectedBg] = ImVec4
        colors[flags.DragDropTarget] = to_vec4(palette.accent3.color_700)
        -- colors[flags.NavHighlight] = ImVec4
        -- colors[flags.NavWindowingHighlight] = ImVec4
        -- colors[flags.NavWindowingDimBg] = ImVec4
        -- colors[flags.ModalWindowDimBg] = ImVec4
    end
end

function imgui.themoonyellow(chroma_multiplier, accurate_shades)
    local color = 0x00FFFF
    local vec2, vec4 = imgui.ImVec2, imgui.ImVec4
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local flags = imgui.Col

    do -- style
        style.WindowPadding = imgui.ImVec2(8, 8)
        style.FramePadding = imgui.ImVec2(5, 5)
        style.ItemSpacing = imgui.ImVec2(5, 5)
        style.ItemInnerSpacing = imgui.ImVec2(2, 2)
        style.TouchExtraPadding = imgui.ImVec2(0, 0)
        style.IndentSpacing = 0
        style.ScrollbarSize = 10
        style.GrabMinSize = 10
        style.WindowBorderSize = 1
        style.ChildBorderSize = 1
    
        style.PopupBorderSize = 1
        style.FrameBorderSize = 1
        style.TabBorderSize = 1
        style.WindowRounding = 10
        style.ChildRounding = 0
        style.FrameRounding = 8
        style.PopupRounding = 10
        style.ScrollbarRounding = 10
        style.GrabRounding = 10
        style.TabRounding = 10
        style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
        style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
        style.SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    end

    do -- colors
        local function to_vec4(u32)
            local a = bit.band(bit.rshift(u32, 24), 0xFF) / 0xFF
            local r = bit.band(bit.rshift(u32, 16), 0xFF) / 0xFF
            local g = bit.band(bit.rshift(u32, 8), 0xFF) / 0xFF
            local b = bit.band(u32, 0xFF) / 0xFF
            return imgui.ImVec4(r, g, b, a)
        end

        local monet = require('MoonMonet')
        local palette = monet.buildColors(color, chroma_multiplier, accurate_shades)

        colors[flags.Text] = to_vec4(palette.neutral1.color_100)
        -- colors[flags.TextDisabled] = ImVec4
        colors[flags.WindowBg] = to_vec4(palette.accent1.color_900)
        colors[flags.ChildBg] = to_vec4(palette.accent2.color_800)
        colors[flags.PopupBg] = to_vec4(palette.accent2.color_800)
        colors[flags.Border] = to_vec4(palette.neutral1.color_1000)
        colors[flags.FrameBg] = to_vec4(palette.accent1.color_800)
        colors[flags.FrameBgHovered] = to_vec4(palette.accent1.color_700)
        colors[flags.FrameBgActive] = to_vec4(palette.accent1.color_600)
        -- colors[flags.TitleBg] = ImVec4
        colors[flags.TitleBgActive] = to_vec4(palette.accent1.color_800)
        -- colors[flags.TitleBgCollapsed] = ImVec4
        -- colors[flags.MenuBarBg] = ImVec4
        colors[flags.ScrollbarBg] = to_vec4(palette.accent1.color_800)
        colors[flags.ScrollbarGrab] = to_vec4(palette.accent2.color_600)
        colors[flags.ScrollbarGrabHovered] = to_vec4(palette.accent2.color_500)
        colors[flags.ScrollbarGrabActive] = to_vec4(palette.accent2.color_400)
        colors[flags.CheckMark] = to_vec4(palette.neutral1.color_50)
        colors[flags.SliderGrab] = to_vec4(palette.accent2.color_500)
        colors[flags.SliderGrabActive] = to_vec4(palette.accent2.color_400)
        colors[flags.Button] = to_vec4(palette.accent1.color_700)
        colors[flags.ButtonHovered] = to_vec4(palette.accent1.color_400)
        colors[flags.ButtonActive] = to_vec4(palette.accent1.color_300)
        colors[flags.Header] = to_vec4(palette.accent1.color_800)
        colors[flags.HeaderHovered] = to_vec4(palette.accent1.color_700)
        colors[flags.HeaderActive] = to_vec4(palette.accent1.color_600)
        colors[flags.Separator] = to_vec4(palette.accent2.color_200)
        colors[flags.SeparatorHovered] = to_vec4(palette.accent2.color_100)
        colors[flags.SeparatorActive] = to_vec4(palette.accent2.color_50)
        colors[flags.ResizeGrip] = to_vec4(palette.accent2.color_900)
        colors[flags.ResizeGripHovered] = to_vec4(palette.accent2.color_800)
        colors[flags.ResizeGripActive] = to_vec4(palette.accent2.color_700)
        colors[flags.Tab] = to_vec4(palette.accent1.color_700)
        colors[flags.TabHovered] = to_vec4(palette.accent1.color_600)
        colors[flags.TabActive] = to_vec4(palette.accent1.color_500)
        -- colors[flags.TabUnfocused] = ImVec4
        -- colors[flags.TabUnfocusedActive] = ImVec4
        colors[flags.PlotLines] = to_vec4(palette.accent3.color_300)
        colors[flags.PlotLinesHovered] = to_vec4(palette.accent3.color_50)
        colors[flags.PlotHistogram] = to_vec4(palette.accent3.color_300)
        colors[flags.PlotHistogramHovered] = to_vec4(palette.accent3.color_50)
        -- colors[flags.TextSelectedBg] = ImVec4
        colors[flags.DragDropTarget] = to_vec4(palette.accent3.color_700)
        -- colors[flags.NavHighlight] = ImVec4
        -- colors[flags.NavWindowingHighlight] = ImVec4
        -- colors[flags.NavWindowingDimBg] = ImVec4
        -- colors[flags.ModalWindowDimBg] = ImVec4
    end
end

function style4()
    imgui.SwitchContext()
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
    imgui.GetStyle().WindowPadding = ImVec2(8, 8)
    imgui.GetStyle().FramePadding = ImVec2(5, 3)
    imgui.GetStyle().ItemSpacing = ImVec2(5, 4)
    imgui.GetStyle().ItemInnerSpacing = ImVec2(4, 4)
    imgui.GetStyle().TouchExtraPadding = ImVec2(0, 0)
    imgui.GetStyle().IndentSpacing = 21
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 8
    imgui.GetStyle().WindowBorderSize = 1
    imgui.GetStyle().ChildBorderSize = 1

    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1
    imgui.GetStyle().WindowRounding = 6
    imgui.GetStyle().ChildRounding = 5
    imgui.GetStyle().FrameRounding = 4
    imgui.GetStyle().PopupRounding = 8
    imgui.GetStyle().ScrollbarRounding = 13
    imgui.GetStyle().GrabRounding = 1
    imgui.GetStyle().TabRounding = 8

    imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(0.00, 0.00, 0.00, 1.00);
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00);
    imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.86, 0.86, 0.86, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ChildBg]                = ImVec4(0.71, 0.71, 0.71, 1.00);
    imgui.GetStyle().Colors[imgui.Col.PopupBg]                = ImVec4(0.79, 0.79, 0.79, 1.00);
    imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.00, 0.00, 0.00, 0.36);
    imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.10);
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(1.00, 1.00, 1.00, 1.00);
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(1.00, 1.00, 1.00, 1.00);
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(1.00, 1.00, 1.00, 1.00);
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(1.00, 1.00, 1.00, 0.81);
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(1.00, 1.00, 1.00, 1.00);
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = ImVec4(1.00, 1.00, 1.00, 0.51);
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(1.00, 1.00, 1.00, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(1.00, 1.00, 1.00, 0.86);
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.37, 0.37, 0.37, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = ImVec4(0.60, 0.60, 0.60, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = ImVec4(0.21, 0.21, 0.21, 1.00);
    imgui.GetStyle().Colors[imgui.Col.CheckMark]              = ImVec4(0.42, 0.42, 0.42, 1.00);
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.51, 0.51, 0.51, 1.00);
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.65, 0.65, 0.65, 1.00);
    imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.52, 0.52, 0.52, 0.83);
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.58, 0.58, 0.58, 0.83);
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.44, 0.44, 0.44, 0.83);
    imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.65, 0.65, 0.65, 1.00);
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.73, 0.73, 0.73, 1.00);
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.53, 0.53, 0.53, 1.00);
    imgui.GetStyle().Colors[imgui.Col.Separator]              = ImVec4(0.46, 0.46, 0.46, 1.00);
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = ImVec4(0.45, 0.45, 0.45, 1.00);
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = ImVec4(0.45, 0.45, 0.45, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = ImVec4(0.23, 0.23, 0.23, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = ImVec4(0.32, 0.32, 0.32, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = ImVec4(0.14, 0.14, 0.14, 1.00);
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = ImVec4(1.00, 0.00, 0.00, 0.27);
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = ImVec4(1.00, 0.00, 0.00, 0.48);
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = ImVec4(1.00, 0.00, 0.00, 0.60);
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = ImVec4(1.00, 0.00, 0.00, 0.27);
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = ImVec4(1.00, 0.00, 0.00, 0.54);
    imgui.GetStyle().Colors[imgui.Col.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = ImVec4(1.00, 1.00, 1.00, 1.00);
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = ImVec4(0.70, 0.70, 0.70, 1.00);
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = ImVec4(1.00, 1.00, 1.00, 1.00);
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = ImVec4(0.62, 0.62, 0.62, 1.00);
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = ImVec4(1.00, 1.00, 0.00, 0.90);
    imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = ImVec4(0.26, 0.59, 0.98, 1.00);
    imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = ImVec4(1.00, 1.00, 1.00, 0.70);
    imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = ImVec4(0.80, 0.80, 0.80, 0.20);
    imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = ImVec4(0.26, 0.26, 0.26, 0.60);
end --сделано

function style5()
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
    imgui.GetStyle().WindowPadding = ImVec2(8, 8)
    imgui.GetStyle().FramePadding = ImVec2(7, 5)
    imgui.GetStyle().ItemSpacing = ImVec2(12, 8)
    imgui.GetStyle().ItemInnerSpacing = ImVec2(5, 6)
    imgui.GetStyle().TouchExtraPadding = ImVec2(0, 0)
    imgui.GetStyle().IndentSpacing = 21
    imgui.GetStyle().ScrollbarSize = 10.0
    imgui.GetStyle().GrabMinSize = 8.0
    imgui.GetStyle().WindowBorderSize = 1
    imgui.GetStyle().ChildBorderSize = 1

    imgui.GetStyle().PopupBorderSize = 1
    imgui.GetStyle().FrameBorderSize = 1
    imgui.GetStyle().TabBorderSize = 1
    imgui.GetStyle().WindowRounding = 6
    imgui.GetStyle().ChildRounding = 8
    imgui.GetStyle().FrameRounding = 8
    imgui.GetStyle().PopupRounding = 8
    imgui.GetStyle().ScrollbarRounding = 13
    imgui.GetStyle().GrabRounding = 1
    imgui.GetStyle().TabRounding = 8

    imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(0.95, 0.96, 0.98, 1.00);
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.29, 0.29, 0.29, 1.00);
    imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.14, 0.14, 0.14, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ChildBg]                = ImVec4(0.12, 0.12, 0.12, 1.00);
    imgui.GetStyle().Colors[imgui.Col.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94);
    imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.14, 0.14, 0.14, 1.00);
    imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = ImVec4(1.00, 1.00, 1.00, 0.10);
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.22, 0.22, 0.22, 1.00);
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.18, 0.18, 0.18, 1.00);
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.09, 0.12, 0.14, 1.00);
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.19, 0.00, 0.00, 1.00);
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.14, 0.14, 0.14, 1.00);
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = ImVec4(0.14, 0.14, 0.14, 1.00);
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.20, 0.20, 0.20, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.39);
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.36, 0.36, 0.36, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = ImVec4(0.24, 0.24, 0.24, 1.00);
    imgui.GetStyle().Colors[imgui.Col.CheckMark]              = ImVec4(1.00, 0.28, 0.28, 1.00);
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(1.00, 0.28, 0.28, 1.00);
    imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(1.00, 0.28, 0.28, 1.00);
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(1.00, 0.39, 0.39, 1.00);
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(1.00, 0.21, 0.21, 1.00);
    imgui.GetStyle().Colors[imgui.Col.Separator]              = ImVec4(1.00, 0.00, 0.00, 0.41);
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.78);
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = ImVec4(1.00, 0.28, 0.28, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = ImVec4(1.00, 0.39, 0.39, 1.00);
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = ImVec4(1.00, 0.19, 0.19, 1.00);
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = ImVec4(1.00, 0.00, 0.00, 0.27);
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = ImVec4(1.00, 0.00, 0.00, 0.48);
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = ImVec4(1.00, 0.00, 0.00, 0.60);
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = ImVec4(1.00, 0.00, 0.00, 0.27);
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = ImVec4(1.00, 0.00, 0.00, 0.54);
    imgui.GetStyle().Colors[imgui.Col.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00);
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = ImVec4(1.00, 0.21, 0.21, 1.00);
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = ImVec4(1.00, 0.18, 0.18, 1.00);
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = ImVec4(1.00, 0.32, 0.32, 1.00);
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = ImVec4(1.00, 1.00, 0.00, 0.90);
    imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = ImVec4(0.26, 0.59, 0.98, 1.00);
    imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = ImVec4(1.00, 1.00, 1.00, 0.70);
    imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = ImVec4(0.80, 0.80, 0.80, 0.20);
    imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = ImVec4(0.80, 0.80, 0.80, 0.35);
end