# Пакости по соседству — нативная 3D-игра

Основная разработка на Godot 4.4.1: **Android, iOS и Windows**, без веб-версии.

## Оригинальные персонажи и дом

Для сборки обязательно нужны **пять оригинальных моделей владельца**, а не процедурные замены:

- `source/assets/user_models/hero_rigged.glb`
- `source/assets/user_models/neighbor_rigged.glb`
- `source/assets/user_models/house_lower_quality.glb`
- `source/assets/user_models/house_upper_quality.glb`
- `source/assets/user_models/house_roof_quality.glb`

Их достоверный комплект уже находится в сохранённом полном проекте `Pakosti_24_MISSION_OWNER_3D_FIXED_2026_11_02.zip`. В самом GitHub пока **нет этих крупных бинарных файлов**. Поэтому никакую сборку из GitHub без них нельзя выдавать за игру с оригинальными персонажами и локацией.

`python3 ci/assert_original_assets.py` сравнивает SHA-256 всех пяти GLB с проверенным владельческим комплектом. GitHub Actions теперь **не выдаёт APK/EXE с подменёнными персонажами**, а завершает проверку ошибкой, пока эти оригинальные файлы не добавлены.

Двухэтажный дом, 24 миссии, управление, ловушки и AI остаются в проекте. Текущие игровые коллизии всё ещё требуют подгонки под сканированный дом. Для запуска полной версии из архива откройте `source/project.godot`.

[Разработка: PR №1](https://github.com/ishkintembur001-maker/pakosti-po-sosedstvu-web/pull/1)
