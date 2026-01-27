#!/bin/bash

COMPANY_ID="${1:-1740}"
OUTPUT_FILE="vacancies.json"
PER_PAGE=100

echo "Поиск junior/стажер вакансий в компании ID: $COMPANY_ID"

curl -s "https://api.hh.ru/vacancies?employer_id=$COMPANY_ID&per_page=$PER_PAGE&page=0" | \
jq '
  {
    employer_id: "'"$COMPANY_ID"'",
    total_found: .found,
    filtered_found: ([.items[] | select(
      .internship == true or
      (.name | test("(^|[^a-zA-Zа-яА-Я])(стажер|стажировка|junior|джуниор|trainee|intern)($|[^a-zA-Zа-яА-Я])", "i"))
    )] | length),
    items: [.items[] | select(
      .internship == true or
      (.name | test("(^|[^a-zA-Zа-яА-Я])(стажер|стажировка|junior|джуниор|trainee|intern)($|[^a-zA-Zа-яА-Я])", "i"))
    )],
    search_date: (now | strftime("%Y-%m-%d %H:%M:%S"))
  }
' > "$OUTPUT_FILE"

TOTAL=$(jq '.total_found' "$OUTPUT_FILE")
FILTERED=$(jq '.filtered_found' "$OUTPUT_FILE")

echo "Всего вакансий в компании: $TOTAL"
echo "Junior/стажер позиций: $FILTERED"
echo "Файл: $OUTPUT_FILE"