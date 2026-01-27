#!/bin/bash

COMPANY_ID="${1:-1740}"
OUTPUT_FILE="vacancies.json"
PER_PAGE=100

TOTAL=$(curl -s "https://api.hh.ru/vacancies?employer_id=$COMPANY_ID&per_page=1&page=0" | jq '.found')
PAGES=$(( (TOTAL + PER_PAGE - 1) / PER_PAGE ))
PAGES=$(( PAGES < 20 ? PAGES : 20 ))

echo "Компания ID: $COMPANY_ID"
echo "Всего вакансий: $TOTAL"
echo "Страниц для обработки: $PAGES"
echo "================================="

TEMP_FILE="temp_items.json"
> "$TEMP_FILE"  

TOTAL_FILTERED=0

for ((i=0; i<PAGES; i++)); do
    echo "Обработка страницы $i..."

    PAGE_DATA=$(curl -s "https://api.hh.ru/vacancies?employer_id=$COMPANY_ID&per_page=$PER_PAGE&page=$i")

    FILTERED_ITEMS=$(echo "$PAGE_DATA" | jq --arg name_pattern "(?i)(^|[^а-яА-Яa-zA-Z0-9])(стажер|стажёр|стажировка|junior|джуниор|trainee|intern|internship|младший)([^а-яА-Яa-zA-Z0-9]|$)" '
    [.items[] | select(
        (.internship == true) or
        (.name | ascii_downcase | test($name_pattern))
    )]')

    COUNT=$(echo "$FILTERED_ITEMS" | jq 'length')
    TOTAL_FILTERED=$((TOTAL_FILTERED + COUNT))
    
    echo "  Найдено junior/стажер вакансий на странице: $COUNT"

    if [ "$COUNT" -gt 0 ]; then
        echo "$FILTERED_ITEMS" | jq '.[]' >> "$TEMP_FILE"
    fi

    sleep 0.5
done

echo "Формирование итогового файла..."
jq -s '
{
    employer_id: "'"$COMPANY_ID"'",
    total_found: '"$TOTAL"',
    filtered_found: '"$TOTAL_FILTERED"',
    pages_processed: '"$PAGES"',
    per_page: '"$PER_PAGE"',
    items: .,
    search_date: (now | strftime("%Y-%m-%d %H:%M:%S"))
}' "$TEMP_FILE" > "$OUTPUT_FILE"
rm "$TEMP_FILE"

echo "Компания ID: $COMPANY_ID"
echo "Всего вакансий: $TOTAL"
echo "Обработано страниц: $PAGES"
echo "Найдено junior/стажер позиций: $TOTAL_FILTERED"
echo "Файл: $OUTPUT_FILE"
