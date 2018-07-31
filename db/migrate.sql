ALTER TABLE players ADD birth_month integer, ADD birth_day integer;

UPDATE players SET birth_month = 7, birth_day = 20 WHERE player = 'Mark';
UPDATE players SET birth_month = 7, birth_day = 26 WHERE player = 'Brian';
UPDATE players set birth_month = 6, birth_day = 7 WHERE player = 'Roland';