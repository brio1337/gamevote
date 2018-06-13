ssh ubuntu@brio.software 'pg_dump -U games -a' | sed 's/COPY public./COPY /' > games.dump
