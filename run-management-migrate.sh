if [ -n "$CORE_DB_PATH" ] && [ "$CORE_DB_READONLY" != "true" ]; then
    /app/migrate --core-db "$CORE_DB_PATH" --path "/app/migrations"
fi

/app/hugr-management