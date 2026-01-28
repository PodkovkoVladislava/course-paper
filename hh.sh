#!/bin/bash

COMPANY_IDS=(1740 15478 78638 1122462 87021 2180 2748 4219 1793216 3529 1272486 2460946 4649269 6163938 2381 84585 5858718 780654 44272 882 1057 2036113 577743 733 2324020 115 4670572 41862 2733062 3095 856498 61166 2987  35065 3233751 26624 1420809 136929 11326478 5060211 4350075 139 2425896 3778 1161108 2800 543454 3177 3536822 5325 2238 11749 633069 1429999 127256 2562304 4080 2343 72986 662065 1532045 154 560786 64474 3343 3196854 8981150 724229 5050306 113649 1911403 745654 2417 865 1871618 1318551 3588767 3984 3415 42600 41144 133459 11297067 681672 4813742 1911144 5722585 81647 1302041 3703896 2393 2565797 1749095 1520 2104558 5063336 1949248 2575 83639 80 4181 6591)
OUTPUT_FILE="vacancies.json"
PER_PAGE=100
TEMP_FILE="temp_items.json"

> "$TEMP_FILE"

for COMPANY_ID in "${COMPANY_IDS[@]}"; do
    TOTAL=$(curl -s "https://api.hh.ru/vacancies?employer_id=$COMPANY_ID&per_page=100&page=0" | jq '.found')
    PAGES=$(( (TOTAL + PER_PAGE - 1) / PER_PAGE ))
    PAGES=$(( PAGES < 20 ? PAGES : 20 ))

    echo "Компания ID: $COMPANY_ID"
    echo "Всего вакансий: $TOTAL"
    echo "Страниц для обработки: $PAGES"

    for ((i=0; i<PAGES; i++)); do
        PAGE_DATA=$(curl -s "https://api.hh.ru/vacancies?employer_id=$COMPANY_ID&per_page=$PER_PAGE&page=$i")
        echo "Обработка страницы $i..."

        echo "$PAGE_DATA" | jq --arg name_pattern "(?i)(^|[^а-яА-Яa-zA-Z0-9])(стажер|стажёр|стажировка|junior|джуниор|trainee|intern|internship|младший)([^а-яА-Яa-zA-Z0-9]|$)" \
            --arg company "$COMPANY_ID" '
            [.items[] | select(
                (.internship == true) or
                (.name | ascii_downcase | test($name_pattern))
            )] | .[] | .company_id = ($company | tonumber)' >> "$TEMP_FILE"

        sleep 0.5
    done
done

jq -s '.' "$TEMP_FILE" > "$OUTPUT_FILE"
rm "$TEMP_FILE"

echo "Готово! Результат в $OUTPUT_FILE"
