drop view MitarbeitDaten;
drop table habenkontakt;
drop table kreirenbestellung;
drop table assistent;
drop table designer;
drop table ohrring_paar;
drop trigger gesamtpreisH_update;
drop trigger gesamtpreis_update;
drop trigger halskette_trig;
drop sequence halskette_seq;
drop table halskette;
drop trigger ohrring_trig;
drop sequence ohrring_seq;
drop table ohrring;
drop trigger rechnungs_trigger;
drop sequence rechnung_seq;
drop table rechnung;
drop table bestellung;
drop table kunde;

commit;
select count(*) from user_tables;