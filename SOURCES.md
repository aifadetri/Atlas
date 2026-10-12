# Источники и лицензии

## Звёзды и рисунки

Astronomical geometry and star data, prepared 2026-10-12.

D3 Celestial by Olaf Frohn, pinned commit 7e720a3de062059d4c5400a379146a601d9010e0
https://github.com/ofrohn/d3-celestial/tree/7e720a3de062059d4c5400a379146a601d9010e0
Files: data/constellations.json, data/constellations.lines.json, data/starnames.json.
BSD-3-Clause license; full license in d3-celestial-LICENSE.txt.
Derived constellation center labels and traditional connecting-line geometry.
Constellation names and some line modifications are by the author. Connecting lines
are illustrative conventions, NOT official IAU constellation boundaries.
Serpens's two geometry entries have been combined into one of 88 entries.

HYG v4.1 by David Nash / Astronexus, pinned GitHub commit
c7f7f883fe678cc7680169a50ccd7dcc49b060ce
https://github.com/astronexus/HYG-Database/blob/c7f7f883fe678cc7680169a50ccd7dcc49b060ce/hyg/CURRENT/hygdata_v41.csv
https://github.com/astronexus/HYG-Database/blob/c7f7f883fe678cc7680169a50ccd7dcc49b060ce/hyg/README.md
HYG data is CC BY-SA 4.0. The derived star subset within sky.json is likewise
CC BY-SA 4.0: https://creativecommons.org/licenses/by-sa/4.0/
The star catalog combines Hipparcos, Yale Bright Star, and Gliese data.
Coordinates: right ascension converted from hours to longitude degrees, normalized
-180..180; declination degrees; equinox and epoch J2000.0. Apparent visual
magnitudes are approximate catalog values, not real-time brightness. Variable
star ranges (when present) are taken from HYG, originally Hp adjusted to V.
The stars list includes catalog records brighter than or equal to V=6.0 assigned
to each constellation by HYG. Three brightest distinct apparent positions selected
for cards, skipping near companion entries within 3 arcminutes; the retained
magnitude is the brighter catalog component, NOT the summed unresolved system.
For example Rigil Kentaurus -0.01 is alpha Centauri A, not system A+B combined.
Preserve this caveat in educational documentation.

Drawing points:
The `points` field is a simplified teaching chart: HYG stars V <= 4.8 plus all
traditional line endpoints regardless of magnitude. Every endpoint is matched
against the full HYG v4.1 catalog using spherical angular separation <=0.02 deg.
No unmatched endpoints; maximum match separation 0.004517 deg (~16.3 arcseconds).
Line coordinates retained for exact connecting-line alignment; their magnitude
is measured catalog photometry, never a synthetic fallback. `lineStar` flags
these points. Full <=6.0 star subset remains available in `stars`.


Производный набор звёзд и рисунков находится в `data.js`. Для удобства распространения этот файл распространяется под CC BY-SA 4.0; также соблюдаются условия BSD для данных d3-celestial (полный текст в `licenses/d3-celestial-LICENSE.txt`). Новые факты составлены на русском языке, источники сохранены в каждой карточке. Код интерфейса — авторская часть прототипа, MIT (LICENSE).

### Изменения данных

- Оставлены 88 созвездий, две области Змеи объединены.
- Координаты — J2000; звёзды до 4,8m и все вершины соединительных линий. Вершины сопоставлены с HYG с максимальным отклонением около 16 угловых секунд; на диаграммах вершины сохраняют координаты исходных линий.
- Масштаб точек зависит от каталоговой величины; каждая карточка имеет отдельный масштаб. Стереографическая проекция относительно опорной точки d3-celestial.
- Для тесных кратных систем выбран ярчайший каталоговый компонент. Это не обязательно суммарная яркость системы: в частности, α Cen A показана как −0,01m.
- Имена ярких общеизвестных звёзд переведены на русский, остальные оставлены в каталоговой форме. Полные каталожные имена также сохранены в данных.
- Переменность отмечена по полю var каталога HYG. Диапазоны из каталога не показаны, поскольку они не являются гарантированными полными современными диапазонами.
- «У экватора» — области, содержащие небесный экватор, по диапазонам склонений данных границ d3-celestial. «Северные/южные» — учебный фильтр по опорной точке рисунка, не полный список видимости с наблюдательской широты.

## Факты в карточках

В каждом элементе `data.js` есть поле `sources` с конкретными ссылками. Основные первичные источники:

- IAU: https://iauarchive.eso.org/public/themes/constellations/
- Harvard-Smithsonian CfA: https://library.cfa.harvard.edu/iau-constellations
- NASA Science и Night Sky Network: https://science.nasa.gov/ и https://nightsky.jpl.nasa.gov/
- ESA/Hubble: https://esahubble.org/
- ESO: https://www.eso.org/

Количество и имена созвездий проверены по IAU. В наборе зодиака 13 созвездий, включая Змееносца. Это созвездия, а не 12 астрологических знаков.

Ссылки предназначены для проверки данных и могут меняться со временем. Для самой игры интернет не требуется.

## Шрифты

- Golos Text: https://github.com/google/fonts/tree/main/ofl/golostext
- Unbounded: https://github.com/google/fonts/tree/main/ofl/unbounded

Локальные WOFF2-файлы получены через Google Fonts CSS API. Шрифты сохранены без изменений; лицензия SIL Open Font License 1.1, полные тексты в licenses/.
