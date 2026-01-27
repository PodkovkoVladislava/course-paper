#!/bin/bash

COMPANY_IDS=(1740 15478 78638 1122462) #добавить все айдишники + переписать логику работы в readme.md!!!!
OUTPUT_FILE="vacancies.json"
PER_PAGE=100
TEMP_FILE="temp_items.json"

> "$TEMP_FILE"

for COMPANY_ID in "${COMPANY_IDS[@]}"; do
    TOTAL=$(curl -s "https://api.hh.ru/vacancies?employer_id=$COMPANY_ID&per_page=1&page=0" | jq '.found')
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
