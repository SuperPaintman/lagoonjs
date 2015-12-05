# Шаблонизатор JADE

## Опции рендера
```coffee
pretty:         true    # Нормализация кода
debugComments:  true    # Комментарии для дебага

page:
    lang:       "ru-RU" # Язык страницы
    title:      "Title" # Заголовок страницы
    angular:    "app"   # Имя программы ангуляр, если он используется

    # SEO
    seo:
        robots:         # Нужна ли индексация
            index:  true
            follow: true
        title:          "Title"
        description:    "Description"
        keywords:       "Keywords"
        type:           "website"
        url:            "//example.com/"
        site_name:      "example.com"
        locale:         "en_US"
        image:          "http://example.com/icon-512x512.png"

        twitter:
            card:           "summary_large_image"
            title:          "Title"
            description:    "Description"
            image:          "http://example.com/icon-512x512.png"
            site:           "@FlatDev"

    # Иконки
    icons:              # Иконки
        apple:
            src: "/public/images/icons/"    # Путь до папки с иконками
            namebase: "icon"                # Общая часит имени
            sizes: [                        # Доступные размеры
                "57x57"
                "60x60"
                "72x72"
                "76x76"
                "114x114"
                "120x120"
                "144x144"
                "152x152"
                "180x180"
                "192x192"
            ]
        basic:
            src: "/public/images/icons/"
            namebase: "icon"
            sizes: [
                "192x192"
                "96x96"
                "32x32"
                "16x16"
            ]
        favicon:
            src: "/public/favicon/favicon.ico"

    # Стили
    styles: [
        id: "style"
        src: "/public/css/style.css"
    ]

    # Скрипты
    scripts_top: [
        id:     "jquery"
        src:    "/public/js/jquery-2.1.4.min.js"
        async:  false
    ]

    scripts_bot: [
        id:     "main"
        src:    "/public/js/main.min.js"
        async:  false
    ]

    # Счетчики
    counters:
        yandex: 1337
```
