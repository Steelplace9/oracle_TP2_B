CREATE OR REPLACE PACKAGE pkg_gestion_securisee_des_membres AS

    TYPE r_membre_clair_type IS RECORD (
        couriel MEMBRES.EMAIL_MEMBRE%TYPE,
        telephone MEMBRES.TELEPHONE_MEMBRE%TYPE
    );

    TYPE r_membre_chiffre_type IS RECORD (
        couriel MEMBRES.EMAIL_MEMBRE%TYPE,
        telephone MEMBRES.TELEPHONE_MEMBRE%TYPE
    );

    TYPE ref_membre IS REF CURSOR;

    TYPE t_resevations_type IS TABLE OF RESERVATIONS%ROWTYPE;

    TYPE t_paiements_type IS TABLE OF PAIMENTS%ROWTYPE;

    PROCEDURE copier_infos_chiffrees(p_id_membre MEMBRES.ID_MEMBRE%TYPE);

    FUNCTION ajouter_membre(p_nom MEMBRES.NOM_MEMBRE%type, p_prenom MEMBRES.PRENOM_MEMBRE%type, p_couriel MEMBRES.EMAIL_MEMBRE%type, p_telephone MEMBRES.TELEPHONE_MEMBRE%type, p_date MEMBRES.DATE_INSCRIPTION%type, p_id_abonement MEMBRES.ID_ABONNEMENT%type) return MEMBRES.ID_MEMBRE%type;

    PROCEDURE modifier_coordonnees_membre(p_champ_a_modifier varchar2, p_id_membre MEMBRES.ID_MEMBRE%type, p_champ_modifier varchar2);

    FUNCTION get_coordonnees_dechiffrees(p_champ_a_modifier varchar2, p_id_membre MEMBRES.ID_MEMBRE%type) return varchar2;

    PROCEDURE archiver_membre_et_dependances(p_id_membre MEMBRES.ID_MEMBRE%type);

END pkg_gestion_securisee_des_membres;


CREATE OR REPLACE PACKAGE BODY pkg_gestion_securisee_des_membres AS

    PROCEDURE copier_infos_chiffrees(p_id_membre MEMBRES.ID_MEMBRE%TYPE) IS
        c_membre ref_membre;
        r_membre_claire r_membre_clair_type;
        r_membre_chiffre r_membre_chiffre_type;
    BEGIN
        OPEN c_membre FOR
            SELECT TELEPHONE_MEMBRE, EMAIL_MEMBRE from MEMBRES WHERE ID_MEMBRE = p_id_membre ;

        FETCH c_membre INTO r_membre_claire.TELEPHONE, r_membre_claire.COURIEL;

        IF c_membre%NOTFOUND THEN
            CLOSE c_membre;
            RAISE_APPLICATION_ERROR('-20001','Erreur : Aucun membre a été trouver avec cette ID');
        end if;

        CLOSE c_membre;

        r_membre_chiffre.TELEPHONE := PKG_CHIFFREMENT.CHIFFRER(r_membre_claire.TELEPHONE);
        r_membre_chiffre.COURIEL := PKG_CHIFFREMENT.CHIFFRER(r_membre_claire.COURIEL);

        INSERT INTO MEMBRES_SECURISES VALUES(p_id_membre,r_membre_chiffre.couriel, r_membre_chiffre.telephone);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('une erreur est survenue l"aure de l"execution de la procedure copier_infos_chiffrees');
    END copier_infos_chiffrees;

    FUNCTION ajouter_membre(p_nom MEMBRES.NOM_MEMBRE%type, p_prenom MEMBRES.PRENOM_MEMBRE%type, p_couriel MEMBRES.EMAIL_MEMBRE%type, p_telephone MEMBRES.TELEPHONE_MEMBRE%type, p_date MEMBRES.DATE_INSCRIPTION%type, p_id_abonement MEMBRES.ID_ABONNEMENT%type) return MEMBRES.ID_MEMBRE%type IS
    BEGIN
        INSERT INTO MEMBRES VALUES(SEQ_GENERATEUR_ID.nextval, p_nom, p_prenom, p_couriel, p_telephone, p_date, p_id_abonement);
        COMMIT;
        RETURN SEQ_GENERATEUR_ID.currval;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('une erreur est survenue l"aure de l"execution de la procedure ajouter_membre');
    END ajouter_membre;

    PROCEDURE modifier_coordonnees_membre (p_champ_a_modifier varchar2, p_id_membre MEMBRES.ID_MEMBRE%type, p_champ_modifier varchar2) IS
    BEGIN
        IF p_champ_a_modifier = 'courriel' THEN
            UPDATE MEMBRES SET EMAIL_MEMBRE = p_champ_modifier WHERE ID_MEMBRE = p_id_membre;
            UPDATE MEMBRES_SECURISES SET COURRIEL_CHIFFRE = PKG_CHIFFREMENT.CHIFFRER(p_champ_modifier) WHERE ID_MEMBRE = p_id_membre;
        ELSIF p_champ_a_modifier = 'telephone' THEN
            UPDATE MEMBRES SET TELEPHONE_MEMBRE = p_champ_modifier WHERE ID_MEMBRE = p_id_membre;
            UPDATE MEMBRES_SECURISES SET TELEPHONE_CHIFFRE = PKG_CHIFFREMENT.CHIFFRER(p_champ_modifier) WHERE ID_MEMBRE = p_id_membre;
        ELSE
            RAISE_APPLICATION_ERROR(-20002,'Erreur : Champ à modifier non reconnu');
        end if;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('aucune information n''a pas été trouver avec l''id donner');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('une erreur est survenue l"aure de l"execution de la procedure modifier_coordonnees_membre');
    END modifier_coordonnees_membre;

    FUNCTION get_coordonnees_dechiffrees(p_champ_a_modifier varchar2, p_id_membre MEMBRES.ID_MEMBRE%type) return varchar2 IS
        c_info ref_membre;
        v_chiffre VARCHAR2(1000);
        v_claire VARCHAR2(100);
    BEGIN
        IF p_champ_a_modifier = 'courriel' THEN
            OPEN c_info FOR
                SELECT EMAIL_MEMBRE
                FROM MEMBRES
                WHERE MEMBRES.ID_MEMBRE = p_id_membre;
        ELSIF p_champ_a_modifier = 'telephone' THEN
            OPEN c_info FOR
                SELECT TELEPHONE_MEMBRE
                FROM MEMBRES
                WHERE MEMBRES.ID_MEMBRE = p_id_membre;
        ELSE
            RAISE_APPLICATION_ERROR(-20003, 'Type de champ invalide (courriel ou telephone attendu)');
        END IF;

        FETCH c_info INTO v_chiffre;
        CLOSE c_info;

        v_claire := PKG_CHIFFREMENT.DECHIFFRER(v_chiffre);

        RETURN v_claire;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('aucune information n''a pas été trouver avec l''id donner');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('une erreur est survenue l"aure de l"execution de la procedure get_coordonnees_dechiffrees');
    END get_coordonnees_dechiffrees;

    PROCEDURE archiver_membre_et_dependances(p_id_membre MEMBRES.ID_MEMBRE%type) IS
        t_resvations t_resevations_type;
        t_paiements t_paiements_type;
        v_membre MEMBRES%rowtype;
    BEGIN
        SELECT * BULK COLLECT INTO t_resvations FROM RESERVATIONS WHERE RESERVATIONS.ID_MEMBRE = p_id_membre;

        SELECT * BULK COLLECT INTO t_paiements FROM PAIMENTS WHERE PAIMENTS.ID_MEMBRE = p_id_membre;

        SELECT * INTO v_membre FROM MEMBRES WHERE MEMBRES.ID_MEMBRE = p_id_membre;

        FORALL i IN t_resvations.FIRST .. t_resvations.LAST
            INSERT INTO RESERVATIONS_ARCHIVEES (ID_RESERVATION, DATE_RESERVATION, ID_MEMBRE, ID_ACTIVITE, DATE_ARCHIVAGE)
            VALUES(SEQ_GENERATEUR_ID.nextval, t_resvations(i).DATE_RESERVATION, t_resvations(i).ID_MEMBRE, t_resvations(i).ID_ACTIVITE, SYSDATE);

        FORALL i IN t_paiements.FIRST .. t_paiements.LAST
            INSERT INTO PAIEMENTS_ARCHIVES (ID_PAIEMENT, ID_MEMBRE, MONTANT, DATE_PAIEMENT, TYPE_PAIEMENT, DATE_ARCHIVAGE)
            VALUES(SEQ_GENERATEUR_ID.nextval, t_paiements(i).ID_MEMBRE, t_paiements(i).MONTANT, t_paiements(i).DATE_PAIMENT, t_paiements(i).TYPE_PAIMENT, SYSDATE);

        INSERT INTO MEMBRES_ARCHIVES VALUES(SEQ_GENERATEUR_ID.nextval, v_membre.NOM_MEMBRE, v_membre.PRENOM_MEMBRE, v_membre.EMAIL_MEMBRE, v_membre.TELEPHONE_MEMBRE, v_membre.DATE_INSCRIPTION, v_membre.ID_ABONNEMENT, SYSDATE);

        FORALL i IN t_resvations.FIRST .. t_resvations.LAST
            DELETE RESERVATIONS WHERE ID_RESERVATION = t_resvations(i).ID_RESERVATION;

        FORALL i IN t_paiements.FIRST .. t_paiements.LAST
            DELETE  PAIMENTS WHERE ID_PAIMENT = t_paiements(i).ID_PAIMENT;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('aucune information n''a pas été trouver avec l''id donner');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('une erreur est survenue l"aure de l"execution de la procedure archiver_client_et_dependances');
    END archiver_membre_et_dependances;

END pkg_gestion_securisee_des_membres;