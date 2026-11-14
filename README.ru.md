<p align="center"><img src="docs/media/banner.svg" alt="MachineSpirit" width="100%"></p>
<p align="center"><a href="README.md">English</a> · <b>Русский</b> · <a href="docs/INSTALL.md">Установка и восстановление</a> · <a href="docs/SETTINGS.md">Настройки</a> · <a href="docs/KEYBINDINGS.md">Сочетания клавиш</a></p>

**MachineSpirit** это оболочка рабочего стола для Hyprland на Quickshell: фосфорные экраны, никси, металлические корпуса и цвета от обоев. Четыре фракционных оформления (Adeptus Mechanicus, Ultramarines, Necrons и Khorne) перерисовывают всю оболочку и меняют то, как она движется, а каждый элемент управления остаётся на своём месте. Неофициальный фан-проект в эстетике Warhammer 40,000.

**0.6.0 · Visual & Motion Overhaul** · Arch Linux / CachyOS · Wayland · [GPL-3.0-only](LICENSE) · Автор: [Kukushkasus](https://github.com/Kukushkasus)

<details>
<summary><b>Я это всё читать не буду. Просто дайте команду установки.</b></summary>

Ладно. На Arch Linux или CachyOS, от обычного пользователя (не от root и не через `sudo`):

```bash
git clone https://github.com/Kukushkasus/MachineSpirit.git
cd MachineSpirit
./install.sh --full --yes
```

Потом перезагрузи ПК и войди на экране входа в сессию Hyprland.

- Работает из обычной текстовой консоли и из уже запущенной сессии Hyprland. Ничего из запущенного не перезапускается.
- Нужен `git`. Остальное установщик поставит сам и спросит `sudo`, в том числе экран входа SDDM, если менеджера входа ещё нет.
- Существующие файлы сначала копируются в резерв. Менеджер входа, которым ты уже пользуешься, не трогается.
- Автологин по умолчанию выключен. Загрузочная тема GRUB/Plymouth ставится отдельной опцией.
- Подробности, параметры и восстановление: [установка и восстановление](docs/INSTALL.md).

</details>

<p align="center"><img src="docs/media/showcase.gif?v=0.6.0" alt="MachineSpirit с темой Adeptus Mechanicus: экран входа, рабочий стол с баром и виджетами, консоль, Sanctum, календарь, панели сети и медиа, архив обоев, темы и настройки курсора, меню питания" width="100%"></p>
<p align="center"><sub><a href="docs/media/showcase.mp4">Видео в полном качестве (MP4)</a></sub></p>

## Четыре фракции

Одна оболочка, четыре оформления. Тема перерисовывает бар, корпуса, стекло, кнопки, панели, колесо питания, экран блокировки, курсор и то, как открываются окна. Раскладка, области клика и показания не меняются. У каждой фракции свои обои 4K, но твои обои тема не трогает, пока сам не попросишь.

| Adeptus Mechanicus | Ultramarines |
|---|---|
| ![Adeptus Mechanicus: пластины бара с кабелями, стекло CRT и Sanctum](docs/media/factions/mechanicus.jpg) | ![Ultramarines: тонкая бронеполоса, плиты с золотым кантом и Sanctum](docs/media/factions/ultramarines.jpg) |
| **Necrons** | **Chaos: Khorne** |
| ![Necrons: парящие осколки бара, корпуса-монолиты и Sanctum](docs/media/factions/necrons.jpg) | ![Khorne: железные плиты бара с зубьями и цепями, стекло горна и Sanctum](docs/media/factions/khorne.jpg) |

<p align="center"><img src="docs/media/themes.gif?v=0.6.0" alt="Четыре фракционные темы, переключаемые на лету при открытом Sanctum, каждая со своими обоями: Adeptus Mechanicus, Ultramarines, Necrons и Khorne" width="100%"></p>

Двигаются фракции тоже по-разному: у Mechanicus щёлкают реле и прогреваются лампы, Ultramarines включаются строго по порядку, панели Necrons фазово проявляются, плиты Khorne падают с весом и высекают искры. Подробнее в [паках тем](docs/THEMES.md).

## Что внутри

- **Бар, командная консоль с обзором рабочих столов**, пульт **Sanctum**, панели времени, погоды, ресурсов, сети и медиа, журнал уведомлений, архив обоев с онлайн-источниками и пять перемещаемых виджетов рабочего стола.
- **Центр настроек** из четырнадцати страниц с поиском: внешний вид и курсор, темы, бар, виджеты, эффекты, уведомления, мониторы, ввод, сеанс, сочетания клавиш, приватность, браузеры и обновления.
- **Паки тем** с 30-секундным предпросмотром без сохранения, применением и откатом; свои паки в виде обычных данных (выполнить код они не могут).
- **Курсоры** для каждой фракции со светлой и тёмной обводкой, чтобы их было видно на любых обоях; или оставь свой.
- **Вход, блокировка и загрузка** в том же стиле; режимы уменьшенной анимации и экономии; установка и обновление с резервными копиями.

![Настройки: страница тем с превью четырёх паков](docs/media/settings-themes.jpg)

## Установка и обновление

Нужны Arch Linux или CachyOS, Hyprland 0.55+ с Lua-конфигурацией, Quickshell (проверено на 0.3.2), Python 3.11+ и `pacman`. Быстрый путь в блоке в начале. Выбрать компоненты или сначала посмотреть план:

```sh
./install.sh --full --dry-run
./install.sh --components shell,hyprland,terminal,apps,lock,wallpapers
```

Существующие файлы резервируются, твои правки при обновлении сохраняются. Обновиться можно в **Settings → Updates** или командой `ms-update` (к GitHub она обращается только по твоей просьбе); из клона Git: `git pull` и `./install.sh update`. Параметры, загрузочный компонент, уже установленные менеджеры входа и восстановление: [установка и восстановление](docs/INSTALL.md).

## Совместимость и известные ограничения

- Разрабатывается и проверяется на Hyprland 0.57 и Quickshell 0.3.2 с виртуальной видеокартой (virtio/virgl). Реальные видеокарты, NVIDIA и системы с несколькими GPU пока не проверены. Если попробуешь на реальном железе, оставь, пожалуйста, [отчёт об установке](https://github.com/Kukushkasus/MachineSpirit/issues/new?template=install-report.yml), даже если всё заработало.
- В шрифтах фракций нет кириллицы, такой текст выводится в IBM Plex. Сам интерфейс на английском.
- До версии 1.0 формат паков тем ещё может измениться.

## Документация

Руководства пока на английском.

| Документ | О чём |
|---|---|
| [Installation and recovery](docs/INSTALL.md) | требования, компоненты, обновление, резервные копии, откат, загрузочный компонент |
| [Settings](docs/SETTINGS.md) | файл настроек, курсор, приватность, прокси, политики браузеров, обновления |
| [Theme packs](docs/THEMES.md) | четыре фракции, предпросмотр, режимы цветов, свои паки |
| [Keybindings](docs/KEYBINDINGS.md), [Desktop instruments](docs/desktop-widgets.md) | сочетания клавиш, виджеты рабочего стола |
| [Contributing](CONTRIBUTING.md), [Changelog](CHANGELOG.md), [Third-party](THIRD-PARTY.md) | участие в проекте, история изменений, сторонние компоненты и лицензии |

## Вдохновение и благодарности

- [end-4](https://github.com/end-4/dots-hyprland) и [end4-pC](https://github.com/pctrade/end4-pC): управление рабочим столом, сочетания клавиш, обработка Super и ориентиры по анимации.
- [DMS / DUX](https://github.com/duxlabs-dev/dux-shell): ранние ориентиры для панелей и анимаций.
- [Noctalia](https://github.com/noctalia-dev/noctalia-shell): организация настроек и навигация.
- [Caelestia](https://github.com/caelestia-dots/caelestia): идеи установки, настройки и оформления часов.

Основа: Hyprland, Quickshell и Matugen. Warhammer 40,000 и Adeptus Mechanicus принадлежат Games Workshop; проект с ней не связан.

## Лицензия

Copyright (c) 2026 Kukushkasus. [GPL-3.0-only](LICENSE). Авторы сторонних компонентов и лицензии шрифтов: [THIRD-PARTY.md](THIRD-PARTY.md).

Погода может обращаться к wttr.in и определять место по IP; обложки медиа ищутся через iTunes; поставщики обоев запрашиваются при использовании; проверка обновлений обращается к GitHub только по твоей просьбе. Подробности: [настройки и сетевое поведение](docs/SETTINGS.md#first-launch-and-privacy).

<p align="center"><img src="docs/media/seal.svg" width="90" alt="Оригинальная печать чистоты"><br><sub>Сохраняй труд пользователя. Береги сигнал.</sub></p>
