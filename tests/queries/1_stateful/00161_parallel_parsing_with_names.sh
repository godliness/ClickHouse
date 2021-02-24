#!/usr/bin/env bash

CURDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../shell_config.sh
. "$CURDIR"/../shell_config.sh

FORMATS=('TSVWithNames' 'CSVWithNames')
$CLICKHOUSE_CLIENT -q "DROP TABLE IF EXISTS parsing_with_names"

for format in "${FORMATS[@]}"
do
    $CLICKHOUSE_CLIENT -q "CREATE TABLE parsing_with_names(a DateTime, b String, c FixedString(16)) ENGINE=Memory()"
    
    echo "$format, false";
    $CLICKHOUSE_CLIENT --output_format_parallel_formatting=false -q \
    "SELECT ClientEventTime as a, MobilePhoneModel as b, ClientIP6 as c FROM test.hits LIMIT 50000 Format $format" | \
    $CLICKHOUSE_CLIENT --input_format_parallel_parsing=false -q "INSERT INTO parsing_with_names FORMAT $format"

    $CLICKHOUSE_CLIENT -q "SELECT count() FROM parsing_with_names;"
    $CLICKHOUSE_CLIENT -q "DROP TABLE IF EXISTS parsing_with_names"

    
    $CLICKHOUSE_CLIENT -q "CREATE TABLE parsing_with_names(a DateTime, b String, c FixedString(16)) ENGINE=Memory()"
    echo "$format, true";
    $CLICKHOUSE_CLIENT --output_format_parallel_formatting=false -q \
    "SELECT ClientEventTime as a, MobilePhoneModel as b, ClientIP6 as c FROM test.hits LIMIT 50000 Format $format" | \
    $CLICKHOUSE_CLIENT --input_format_parallel_parsing=true -q "INSERT INTO parsing_with_names FORMAT $format"

    $CLICKHOUSE_CLIENT -q "SELECT count() FROM parsing_with_names;"
    $CLICKHOUSE_CLIENT -q "DROP TABLE IF EXISTS parsing_with_names"
done