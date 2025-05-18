CREATE TABLE membres_securises (
  ID_Membre       NUMBER PRIMARY KEY,
  Courriel_chiffre   VARCHAR2(1000),
  Telephone_chiffre VARCHAR2(1000),
  CONSTRAINT fk_membre_sec FOREIGN KEY (ID_Membre) REFERENCES Membres(ID_Membre)
);

CREATE TABLE membres_archives (
  ID_Membre         NUMBER PRIMARY KEY,
  Nom_membre        VARCHAR2(100),
  Prenom_membre     VARCHAR2(100),
  courriel_membre      VARCHAR2(150),
  Telephone_membre  VARCHAR2(20),
  Date_Inscription  DATE,
  ID_Abonnement     NUMBER,
  Date_Archivage    DATE
);

CREATE TABLE paiements_archives (
  ID_Paiement      NUMBER PRIMARY KEY,
  ID_Membre        NUMBER,
  Montant          NUMBER(10, 2),
  Date_Paiement    DATE,
  Type_Paiement    VARCHAR2(50),
  Date_Archivage   DATE
);

CREATE TABLE reservations_archivees (
  ID_Reservation    NUMBER PRIMARY KEY,
  Date_Reservation  DATE,
  ID_Membre         NUMBER,
  ID_Activite       NUMBER,
  Date_Archivage    DATE
);