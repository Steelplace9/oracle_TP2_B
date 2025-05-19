DECLARE
  v_id_membre     MEMBRES.ID_Membre%TYPE;
  v_nouv_courriel  VARCHAR2(200) := 'nouveau.imane@garneau.ca';
  v_nouv_tel      VARCHAR2(20) := '418-222-1111';
  v_courriel_chiffre  VARCHAR2(1000);
  v_tel_chiffre       VARCHAR2(1000);
BEGIN
  FOR membre IN (SELECT ID_Membre FROM Membres) LOOP
    pkg_gestion_securisee_des_membres.copier_infos_chiffrees(membre.ID_Membre);
  END LOOP;

  v_id_membre := pkg_gestion_securisee_des_membres.ajouter_membre('Meziane', 'Imane', 'imane@garneau.ca','418-111-2222', SYSDATE, 1);

  pkg_gestion_securisee_des_membres.copier_infos_chiffrees(v_id_membre);

  pkg_gestion_securisee_des_membres.modifier_coordonnees_membre('COURRIEL', v_id_membre, v_nouv_courriel);

  pkg_gestion_securisee_des_membres.modifier_coordonnees_membre('TELEPHONE', v_id_membre, v_nouv_tel);

  v_courriel_chiffre := pkg_gestion_securisee_des_membres.get_coordonnees_dechiffrees('COURRIEL', v_id_membre);

  DBMS_OUTPUT.PUT_LINE('Courriel déchiffré : ' || v_courriel_chiffre);

  v_tel_chiffre := pkg_gestion_securisee_des_membres.get_coordonnees_dechiffrees('TELEPHONE', v_id_membre);

  DBMS_OUTPUT.PUT_LINE('Téléphone déchiffré : ' || v_tel_chiffre);

  pkg_gestion_securisee_des_membres.archiver_membre_et_dependances(v_id_membre);

  DELETE MEMBRES_SECURISES WHERE ID_MEMBRE = v_id_membre;
  DELETE MEMBRES WHERE ID_MEMBRE = v_id_membre;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END;

