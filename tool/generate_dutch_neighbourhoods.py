"""Generate the Dart municipality/wijk/buurt hierarchy from the CBS GeoPackage.

Usage:
  python3 tool/generate_dutch_neighbourhoods.py /path/to/wijkenbuurten.gpkg
"""

from __future__ import annotations

import sqlite3
import sys
from collections import defaultdict
from pathlib import Path


CBS_TO_APP_NAME = {
    "'s-Gravenhage": "Den Haag",
    "'s-Hertogenbosch": "Den Bosch",
    "Beek (L.)": "Beek",
    "Bergen (L.)": "Bergen (Limburg)",
    "Bergen (NH.)": "Bergen (Noord-Holland)",
    "Dantumadiel": "Dantumadeel",
    "De Fryske Marren": "De Friese Meren",
    "Hengelo (O.)": "Hengelo",
    "Laren (NH.)": "Laren",
    "Middelburg (Z.)": "Middelburg",
    "Rijswijk (ZH.)": "Rijswijk",
    "Stein (L.)": "Stein",
    "Tytsjerksteradiel": "Tietjerksteradeel",
}


def dart_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\n", " ")
    )
    return f"'{escaped}'"


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Pass the CBS GeoPackage path as the only argument.")

    database = Path(sys.argv[1]).resolve()
    if not database.is_file():
        raise SystemExit(f"GeoPackage not found: {database}")

    hierarchy: dict[str, dict[str, list[str]]] = defaultdict(dict)
    with sqlite3.connect(database) as connection:
        rows = connection.execute(
            """
            SELECT w.gemeentenaam, w.wijknaam, b.buurtnaam
            FROM wijken AS w
            LEFT JOIN buurten AS b
              ON b.wijkcode = w.wijkcode AND b.water = 'NEE'
            WHERE w.water = 'NEE'
            ORDER BY w.gemeentenaam, w.wijknaam, b.buurtnaam
            """
        )
        for cbs_municipality, district, neighbourhood in rows:
            municipality = CBS_TO_APP_NAME.get(cbs_municipality, cbs_municipality)
            neighbourhoods = hierarchy[municipality].setdefault(district, [])
            if neighbourhood is not None and neighbourhood not in neighbourhoods:
                neighbourhoods.append(neighbourhood)

    lines = [
        "// GENERATED FILE — do not edit by hand.",
        "// Source: CBS Wijk- en buurtkaart 2025 v1; watergebieden excluded.",
        "// Regenerate with tool/generate_dutch_neighbourhoods.py.",
        "const Map<String, Map<String, List<String>>> ",
        "    dutchDistrictsAndNeighbourhoods = {",
    ]
    for municipality, districts in hierarchy.items():
        lines.append(f"  {dart_string(municipality)}: {{")
        for district, neighbourhoods in districts.items():
            lines.append(f"    {dart_string(district)}: [")
            lines.extend(
                f"      {dart_string(neighbourhood)},"
                for neighbourhood in neighbourhoods
            )
            lines.append("    ],")
        lines.append("  },")
    lines.append("};")

    output = Path(__file__).parents[1] / "lib/data/dutch_neighbourhoods.dart"
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    district_count = sum(len(districts) for districts in hierarchy.values())
    neighbourhood_count = sum(
        len(neighbourhoods)
        for districts in hierarchy.values()
        for neighbourhoods in districts.values()
    )
    print(
        f"Generated {len(hierarchy)} municipalities, {district_count} districts "
        f"and {neighbourhood_count} neighbourhoods in {output}"
    )


if __name__ == "__main__":
    main()
