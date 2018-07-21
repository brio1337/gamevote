INSERT INTO players VALUES ('Consty');
ALTER TABLE game_owners ADD FOREIGN KEY (game) REFERENCES games, ADD FOREIGN KEY (player) REFERENCES players;
