<div align="center">

# ✨ GlassTabBar для TikTok (`47.9.0`)

**Новый Liquid Glass таббар из iOS 26 с плавным сжатием при скролле и отдельными настройками каждого A/B-флага**

[![Build](https://img.shields.io/badge/Build-GitHub%20Actions%20arm64-0A84FF?style=for-the-badge&logo=githubactions&logoColor=white)](../../actions)
[![TikTok](https://img.shields.io/badge/TikTok-v47.9.0%20(479032)-FE2C55?style=for-the-badge&logo=tiktok&logoColor=white)](#)
[![Made by](https://img.shields.io/badge/Made%20by-t.me%2Fwingmane-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/wingmane)

*made by [t.me/wingmane](https://t.me/wingmane)*

</div>

---

## О твике

**GlassTabBar** — лёгкий нативный `.dylib`-твик для `TikTok 47.9.0`, написанный на чистом Objective-C (`objc/runtime.h`) без зависимостей от Theos, Substrate или ElleKit.

Твик активирует системный стиль **Liquid Glass**, анимацию сжатия нижней капсулы при прокрутке ленты и профилей, а также добавляет прямо в настройки TikTok красивый экран с **раздельным управлением** всеми 33 подфункциями.

### Основные возможности
- **Стеклянный таббар (Core)** — главный переключатель Liquid Glass, TUX-движок, поддержка экранов `< 450pt`, снятие блоклиста устройств и опциональный обход проверки версии iOS.
- **Сжатие при скролле и переходы** — уменьшение капсулы таббара при скролле (`scrollScaleEnabled`), пропуск синхронного layout, отложенная смена вкладок, стеклянный снапшот и защита альфы при переходах.
- **Внешний вид и иконки** — режим без подписей под иконками (только стекло), фикс размера кнопки «+», центрирование иконок, градиентная подложка и сплошной фон стекла.
- **Окна, iPad и производительность** — кэш геометрии рамки, Split View / Duo / Fold поддержка и фиксы iPad на iOS 26.
- **Готовые пресеты в UI** — «Всё + Анимации», «Без текста» и быстрый сброс настроек.
- **Обфускация и защита бинарника** — зашифрованные строки (XOR), скрытие символов (`-fvisibility=hidden`), обфускация внутренних классов/селекторов и `strip -x -S` при сборке.

---

## Где открыть настройки в TikTok

1. Откройте **TikTok** → **Профиль**
2. Нажмите **≡** → **Настройки и конфиденциальность**
3. Нажмите кнопку **✨ Glass** в правом верхнем углу
4. Выберите нужные подфункции или готовый пресет и нажмите **Рестарт**

---

## Установка (Sideload)

1. Перейдите во вкладку [**Actions**](../../actions) → **Build GlassTabBar dylib** → скачайте готовый артефакт **`GlassTabBar`** (`GlassTabBar.dylib`), либо скачайте файл из [**Releases**](../../releases).
2. Вшейте `GlassTabBar.dylib` в ваш `.ipa` TikTok с помощью **Sideloadly**, **ESign**, **Feather** или **Azule**.
3. Установите подписанный `.ipa` на iPhone / iPad.

---

## Автор

<p align="left">
  <a href="https://t.me/wingmane">
    <img src="https://img.shields.io/badge/Telegram-t.me%2Fwingmane-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" alt="t.me/wingmane" />
  </a>
</p>

**made by [t.me/wingmane](https://t.me/wingmane)**
