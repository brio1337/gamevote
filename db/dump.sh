ssh ubuntu@brio.software <<EOF | sed 's/COPY public./COPY games./' > games.dump
pg_dump -U games --data-only
EOF
