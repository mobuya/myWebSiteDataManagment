CREATE TABLE Kunde (
  Email VARCHAR(255) primary key,
  Vorname VARCHAR(255) not null,
  Nachname VARCHAR(255) not null
);

CREATE TABLE Bestellung(
  Bestellungsnummer NUMBER(25) generated by default as identity primary key,
  Abholungsdatum DATE not null,
  Gesamtpreis NUMBER(6,2) default 0 not null,
  Kunde_Email VARCHAR(255) not null,
  FOREIGN KEY  (Kunde_Email) REFERENCES Kunde (Email) ON DELETE CASCADE
);

CREATE TABLE Rechnung(
  RechnungsNummer NUMBER(15),
  BestellungsNummer NUMBER(25),
  Ausstellungsdatum DATE not null,
  Zahlungsart VARCHAR(255) not null,
  PRIMARY KEY(RechnungsNummer, BestellungsNummer),
  FOREIGN KEY(BestellungsNummer)REFERENCES Bestellung(BestellungsNummer) ON DELETE CASCADE
);

-- * * sequence trigger fuer rechnuhg * * 

CREATE SEQUENCE rechnung_seq
  start with 1
  increment by 3;
  
CREATE OR REPLACE TRIGGER rechnungs_trigger
  before insert on Rechnung
  for each row
  when (new.RechnungsNummer is null)
  begin
  :new.Rechnungsnummer:=rechnung_seq.nextval;
  
END;
/

-- ** ende  ** 

CREATE TABLE Ohrring(
  ProduktID NUMBER(25) primary key,
  Preis NUMBER(4,2) default 0 not null,
  Name VARCHAR(255) not null,
  BestellungsNummer NUMBER(25),
  FOREIGN KEY(BestellungsNummer)REFERENCES Bestellung(BestellungsNummer) ON DELETE CASCADE
);

-- * * sequence trigger fuer ohrring  * *  

CREATE SEQUENCE ohrring_seq
  start with 2
  increment by 2;
  
 
CREATE OR REPLACE TRIGGER ohrring_trig
  before insert on ohrring
  for each row
  when (new.ProduktID is null)
  begin
  :new.ProduktID:=ohrring_seq.nextval; 

END;
/

 -- * * ende * *

CREATE TABLE Halskette(
  ProduktID NUMBER(25) primary key,
  Preis NUMBER(4,2) default 0 not null,
  Name VARCHAR(255) not null,
  Groesse CHAR(2) default 'M' check(Groesse in ('XS', 'S', 'M', 'L', 'XL')),
  BestellungsNummer NUMBER(25),
  FOREIGN KEY(BestellungsNummer)REFERENCES Bestellung(BestellungsNummer) ON DELETE CASCADE
);

-- * *  sequence trigger fuer halskette * * 

CREATE SEQUENCE halskette_seq
  start with 3
  increment by 2;
  
CREATE OR REPLACE TRIGGER halskette_trig
  before insert on halskette
  for each row
  when (new.ProduktID is null)
  begin
  :new.ProduktID:=halskette_seq.nextval; 

END;
/ 

-- * * ende * * 


-- !! TRIGGER FUER DEN GESAMTPREIS !!  (trigger der kein auto-increment ist) 

CREATE OR REPLACE TRIGGER gesamtpreis_update
  after insert on ohrring
  for each row
  begin
    update bestellung
    set gesamtpreis = gesamtpreis + :new.preis
    where bestellungsnummer = :NEW.bestellungsnummer;
 END;
 /
 
CREATE OR REPLACE TRIGGER gesamtpreisH_update
  after insert on halskette
  for each row
  begin
    update bestellung
    set gesamtpreis = gesamtpreis + :new.preis
    where bestellungsnummer = :NEW.bestellungsnummer;
 END;
 /
 

-- !! ENDE !! 

CREATE TABLE Ohrring_paar(
  Ohrring_1 NUMBER(25),
  Ohrring_2 NUMBER(25),
  PRIMARY KEY(ohrring_1, ohrring_2),
  FOREIGN KEY(ohrring_1) REFERENCES ohrring(ProduktID) ON DELETE CASCADE,
  FOREIGN KEY(ohrring_2) REFERENCES ohrring(ProduktID) ON DELETE CASCADE,
  CHECK(ohrring_1 <> ohrring_2)
);

CREATE TABLE Designer(
  DesignerID NUMBER(25) generated by default as identity primary key,
  EMail VARCHAR(255) unique not null,
  D_Name VARCHAR(255) not null
);

CREATE TABLE Assistent(
  AssistentID NUMBER(25) generated by default as identity primary key,
  A_Name VARCHAR(255) not null,
  Jahre_erfahrung NUMBER(2) not null
);

CREATE TABLE KreirenBestellung(
  BestellungsNummer NUMBER(25),
  DesignerID NUMBER(25),
  AssistentID NUMBER(25),
  FOREIGN KEY(BestellungsNummer) REFERENCES Bestellung(BestellungsNummer) ON DELETE CASCADE,
  FOREIGN KEY(DesignerID) REFERENCES Designer(DesignerID) ON DELETE CASCADE,
  FOREIGN KEY(AssistentID) REFERENCES Assistent(AssistentID) ON DELETE CASCADE,
  PRIMARY KEY (DesignerID, BestellungsNummer)
);

CREATE TABLE HabenKontakt(
  DesignerID NUMBER(25),
  Kunde_Email VARCHAR(255),
  PRIMARY KEY(DesignerID, Kunde_Email),
  FOREIGN KEY(DesignerID) REFERENCES Designer(DesignerID) ON DELETE CASCADE,
  FOREIGN KEY(Kunde_Email) REFERENCES Kunde(Email) ON DELETE CASCADE
);


-- * * * * CUSTOM VIEW  * * * *

CREATE VIEW MitarbeitDaten AS
    SELECT D.D_Name AS DesignerName, A.A_Name AS AssistentName, 
           COUNT(DISTINCT O.ProduktID) AS AnzahlOhrringe,
           COUNT(DISTINCT H.ProduktID) AS AnzahlHalsketten
  FROM KreirenBestellung KB
    INNER JOIN Designer D ON D.DesignerID = KB.DesignerID
    INNER JOIN Assistent A ON A.AssistentID = KB.AssistentID
    LEFT JOIN Ohrring O ON O.BestellungsNummer = KB.BestellungsNummer
    LEFT JOIN Halskette H ON H.BestellungsNummer = KB.BestellungsNummer
  WHERE O.ProduktID IS NOT NULL OR H.ProduktID IS NOT NULL
    GROUP BY D.D_Name, A.A_Name
    HAVING COUNT(DISTINCT O.ProduktID) >= 1 OR COUNT(DISTINCT H.ProduktID) >= 1;

-- * * * * * ende  * * * * *


ALTER TABLE Ohrring_paar
ADD CONSTRAINT UK_Ohrring_paar_Ohrring_1 UNIQUE (Ohrring_1);

ALTER TABLE Bestellung
MODIFY Abholungsdatum DATE DEFAULT (SYSDATE + INTERVAL '10' DAY);


CREATE OR REPLACE TRIGGER Ohrring_Preis_Trigger
BEFORE INSERT ON Ohrring
FOR EACH ROW
BEGIN
  :NEW.Preis := ROUND(DBMS_RANDOM.VALUE(7.00, 23.00), 2);
END;
/


CREATE OR REPLACE TRIGGER Halskette_Preis_Trigger
BEFORE INSERT ON Halskette
FOR EACH ROW
BEGIN
  :NEW.Preis := ROUND(DBMS_RANDOM.VALUE(13.00, 64.00), 2);
END;
/


CREATE OR REPLACE PROCEDURE ErstelleRechnung(
  p_BestellungsNummer NUMBER,
  p_Zahlungsart VARCHAR2,
  p_RechnungsNummer OUT NUMBER
)
AS
  v_RechnungsNummer Rechnung.RechnungsNummer%TYPE;
  CURSOR c_RechnungsNummer IS
    SELECT RechnungsNummer
    FROM Rechnung
    WHERE BestellungsNummer = p_BestellungsNummer;
BEGIN
  INSERT INTO Rechnung (BestellungsNummer, Ausstellungsdatum, Zahlungsart)
  VALUES (p_BestellungsNummer, SYSDATE, p_Zahlungsart);
  
  OPEN c_RechnungsNummer;
  FETCH c_RechnungsNummer INTO v_RechnungsNummer;
  CLOSE c_RechnungsNummer;
  
  p_RechnungsNummer := v_RechnungsNummer;
  
  COMMIT;
END;
/

commit;

select * from user_tables;