CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD 'auth';
CREATE ROLE anon;
GRANT anon TO authenticator;
