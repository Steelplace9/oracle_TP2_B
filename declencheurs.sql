CREATE OR REPLACE TRIGGER trg_ajout_membre_securises
    AFTER INSERT ON MEMBRES
    FOR EACH ROW
DECLARE
    v_courriel_chiffre MEMBRES_SECURISES.COURRIEL_CHIFFRE%TYPE;
    v_telephone_chiffre MEMBRES_SECURISES.TELEPHONE_CHIFFRE%TYPE;
BEGIN
    v_courriel_chiffre := PKG_CHIFFREMENT.CHIFFRER(:NEW.EMAIL_MEMBRE);
    v_telephone_chiffre := PKG_CHIFFREMENT.CHIFFRER(:NEW.TELEPHONE_MEMBRE);

    INSERT INTO MEMBRES_SECURISES (
        ID_MEMBRE,
        COURRIEL_CHIFFRE,
        TELEPHONE_CHIFFRE
    ) VALUES (
        :NEW.ID_MEMBRE,
        v_courriel_chiffre,
        v_telephone_chiffre
    );
end;

CREATE OR REPLACE TRIGGER trg_archiver_membre_et_dependances
    BEFORE DELETE ON MEMBRES
    FOR EACH ROW
BEGIN
    PKG_GESTION_SECURISEE_DES_MEMBRES.ARCHIVER_MEMBRE_ET_DEPENDANCES(:OLD.ID_MEMBRE);
end;

CREATE OR REPLACE TRIGGER trg_supprimer_membre_chiffre
    AFTER DELETE ON MEMBRES
    FOR EACH ROW
BEGIN
    DELETE MEMBRES_SECURISES WHERE ID_MEMBRE = :OLD.ID_MEMBRE;
end;

CREATE OR REPLACE TRIGGER trg_not_double_mail_telephone
    BEFORE INSERT ON MEMBRES
    FOR EACH ROW
DECLARE
    v_membre_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_membre_existe FROM MEMBRES WHERE TELEPHONE_MEMBRE = :NEW.TELEPHONE_MEMBRE OR EMAIL_MEMBRE = :NEW.EMAIL_MEMBRE;

    IF v_membre_existe > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'telephone ou couriel deja utiliser');
    END IF;
end;

CREATE OR REPLACE TRIGGER trg_empecher_double_reservation
    BEFORE INSERT ON RESERVATIONS
    FOR EACH ROW
DECLARE
    v_membre_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_membre_existe FROM RESERVATIONS WHERE ID_MEMBRE = :NEW.ID_MEMBRE AND ID_ACTIVITE = :NEW.ID_ACTIVITE AND DATE_RESERVATION = :NEW.DATE_RESERVATION ;

    IF v_membre_existe > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'cette reservation existe deja');
    END IF;
end;

CREATE OR REPLACE TRIGGER trg_empecher_modification_membre_archivre
    BEFORE UPDATE ON MEMBRES_ARCHIVES
BEGIN
    RAISE_APPLICATION_ERROR(-20006, 'modification de la table membre archivre impossible');
end;

CREATE OR REPLACE TRIGGER trg_empecher_modification_paiment_archivre
    BEFORE UPDATE ON PAIEMENTS_ARCHIVES
BEGIN
    RAISE_APPLICATION_ERROR(-20007, 'modification de la table paiment archivre impossible');
end;

CREATE OR REPLACE TRIGGER trg_empecher_modification_reservation_archivre
    BEFORE UPDATE ON RESERVATIONS_ARCHIVEES
BEGIN
    RAISE_APPLICATION_ERROR(-20008, 'modification de la table reservation archivre impossible');
end;

CREATE OR REPLACE TRIGGER trg_max_5_activiter_coach
    BEFORE INSERT OR UPDATE OF ID_COACH ON ACTIVITES
    FOR EACH ROW
DECLARE
    v_nb_activity_coach NUMBER;
BEGIN
    IF INSERTING OR (:OLD.ID_COACH != :NEW.ID_COACH) THEN
        SELECT COUNT(*) INTO v_nb_activity_coach FROM ACTIVITES WHERE ID_COACH = :NEW.ID_COACH;

        IF v_nb_activity_coach >= 5 THEN
            RAISE_APPLICATION_ERROR(-20009, 'le nombre maximal d''activiter a ete atiend avec ce coach');
        end if;
    end if;
END;