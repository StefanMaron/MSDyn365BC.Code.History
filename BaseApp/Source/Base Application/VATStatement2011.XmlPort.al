xmlport 11762 "VAT Statement 2011"
{
    Caption = 'VAT Statement 2011';
    Encoding = UTF8;

    schema
    {
        textelement(Pisemnost)
        {
            textattribute(swversion)
            {
                Occurrence = Optional;
                XmlName = 'verzeSW';
            }
            textattribute(swname)
            {
                Occurrence = Optional;
                XmlName = 'nazevSW';
            }
            tableelement(vatstatementname; "VAT Statement Name")
            {
                MaxOccurs = Once;
                MinOccurs = Zero;
                XmlName = 'DPHDP3';
                textattribute(xmlversion)
                {
                    Occurrence = Optional;
                    XmlName = 'verzePis';
                }
                textelement(VetaD)
                {
                    MaxOccurs = Once;
                    MinOccurs = Once;
                    textattribute(formtype)
                    {
                        XmlName = 'dapdph_forma';

                        trigger OnBeforePassVariable()
                        begin
                            FormType := GetFormType();
                        end;
                    }
                    textattribute(year)
                    {
                        Occurrence = Required;
                        XmlName = 'rok';
                    }
                    textattribute(reasonsobservedon)
                    {
                        Occurrence = Optional;
                        XmlName = 'd_zjist';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(ReasonsObservedOn);
                        end;
                    }
                    textattribute(mainecactcode1)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_okec';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(MainEcActCode1);
                        end;
                    }
                    textattribute(k_uladis)
                    {
                        Occurrence = Required;

                        trigger OnBeforePassVariable()
                        begin
                            k_uladis := 'DPH';
                        end;
                    }
                    textattribute(month)
                    {
                        Occurrence = Optional;
                        XmlName = 'mesic';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(Month);
                        end;
                    }
                    textattribute(dokument)
                    {
                        Occurrence = Required;

                        trigger OnBeforePassVariable()
                        begin
                            dokument := 'DP3';
                        end;
                    }
                    textattribute(todaydate)
                    {
                        Occurrence = Optional;
                        XmlName = 'd_poddp';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(TodayDate);
                        end;
                    }
                    textattribute(quarter)
                    {
                        Occurrence = Optional;
                        XmlName = 'ctvrt';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(Quarter);
                        end;
                    }
                    textattribute(taxpayerstatus)
                    {
                        Occurrence = Required;
                        XmlName = 'typ_platce';
                    }
                    textattribute(notax)
                    {
                        Occurrence = Optional;
                        XmlName = 'trans';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(NoTax);
                        end;
                    }
                    textattribute(gtezdobd_od)
                    {
                        XmlName = 'zdobd_od';
                    }
                    textattribute(gtezdobd_do)
                    {
                        XmlName = 'zdobd_do';
                    }
                    textattribute(gtekod_zo)
                    {
                        XmlName = 'kod_zo';
                    }
                }
                textelement(VetaP)
                {
                    MaxOccurs = Once;
                    MinOccurs = Once;
                    textattribute(authemplastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_prijmeni';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(AuthEmpLastName);
                        end;
                    }
                    textattribute(natpersfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'jmeno';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(NatPersFirstName);
                        end;
                    }
                    textattribute(compemail)
                    {
                        Occurrence = Optional;
                        XmlName = 'email';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(CompEmail);
                        end;
                    }
                    textattribute(street)
                    {
                        Occurrence = Optional;
                        XmlName = 'ulice';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(Street);
                        end;
                    }
                    textattribute(houseno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_pop';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(HouseNo);
                        end;
                    }
                    textattribute(natperslastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'prijmeni';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(NatPersLastName);
                        end;
                    }
                    textattribute(compphoneno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_telef';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(CompPhoneNo);
                        end;
                    }
                    textattribute(municipalityno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_orient';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(MunicipalityNo);
                        end;
                    }
                    textattribute(companytradename)
                    {
                        Occurrence = Optional;
                        XmlName = 'zkrobchjm';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(CompanyTradeName);
                        end;
                    }
                    textattribute(taxofficenumber)
                    {
                        Occurrence = Required;
                        XmlName = 'c_ufo';
                    }
                    textattribute(taxofficeregionnumber)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_pracufo';
                    }
                    textattribute(compregion)
                    {
                        Occurrence = Optional;
                        XmlName = 'stat';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(CompRegion);
                        end;
                    }
                    textattribute(fillempfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'sest_jmeno';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(FillEmpFirstName);
                        end;
                    }
                    textattribute(vatregno)
                    {
                        XmlName = 'dic';
                    }
                    textattribute(city)
                    {
                        Occurrence = Optional;
                        XmlName = 'naz_obce';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(City);
                        end;
                    }
                    textattribute(postcode)
                    {
                        Occurrence = Optional;
                        XmlName = 'psc';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(PostCode);
                        end;
                    }
                    textattribute(taxpayertype)
                    {
                        Occurrence = Required;
                        XmlName = 'typ_ds';
                    }
                    textattribute(fillemplastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'sest_prijmeni';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(FillEmpLastName);
                        end;
                    }
                    textattribute(natperstitle)
                    {
                        Occurrence = Optional;
                        XmlName = 'titul';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(NatPersTitle);
                        end;
                    }
                    textattribute(fillempphoneno)
                    {
                        Occurrence = Optional;
                        XmlName = 'sest_telef';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(FillEmpPhoneNo);
                        end;
                    }
                    textattribute(authempjobtitle)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_postaveni';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(AuthEmpJobTitle);
                        end;
                    }
                    textattribute(authempfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_jmeno';

                        trigger OnBeforePassVariable()
                        begin
                            SkipEmptyValue(AuthEmpFirstName);
                        end;
                    }
                    textattribute(zast_dat_nar)
                    {
                        XmlName = 'zast_dat_nar';
                    }
                    textattribute(zast_ev_cislo)
                    {
                        XmlName = 'zast_ev_cislo';
                    }
                    textattribute(zast_ic)
                    {
                        XmlName = 'zast_ic';
                    }
                    textattribute(zast_jmeno)
                    {
                        XmlName = 'zast_jmeno';
                    }
                    textattribute(zast_kod)
                    {
                        XmlName = 'zast_kod';
                    }
                    textattribute(zast_nazev)
                    {
                        XmlName = 'zast_nazev';
                    }
                    textattribute(zast_prijmeni)
                    {
                        XmlName = 'zast_prijmeni';
                    }
                    textattribute(zast_typ)
                    {
                        XmlName = 'zast_typ';
                    }
                }
                textelement(Veta1)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    textattribute(dan23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan23, 'dan23');
                        end;
                    }
                    textattribute(dan_psl23_z)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_psl23_z, 'dan_psl23_z');
                        end;
                    }
                    textattribute(obrat23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(obrat23, 'obrat23');
                        end;
                    }
                    textattribute(dov_zb23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dov_zb23, 'dov_zb23');
                        end;
                    }
                    textattribute(p_sl5_z)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(p_sl5_z, 'p_sl5_z');
                        end;
                    }
                    textattribute(dan_dzb5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_dzb5, 'dan_dzb5');
                        end;
                    }
                    textattribute(p_zb5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(p_zb5, 'p_zb5');
                        end;
                    }
                    textattribute(dan_pzb5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_pzb5, 'dan_pzb5');
                        end;
                    }
                    textattribute(p_sl23_z)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(p_sl23_z, 'p_sl23_z');
                        end;
                    }
                    textattribute(dan_pzb23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_pzb23, 'dan_pzb23');
                        end;
                    }
                    textattribute(p_sl5_e)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(p_sl5_e, 'p_sl5_e');
                        end;
                    }
                    textattribute(p_zb23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(p_zb23, 'p_zb23');
                        end;
                    }
                    textattribute(dan_pdop_nrg)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_pdop_nrg, 'dan_pdop_nrg');
                        end;
                    }
                    textattribute(p_sl23_e)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(p_sl23_e, 'p_sl23_e');
                        end;
                    }
                    textattribute(dov_zb5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dov_zb5, 'dov_zb5');
                        end;
                    }
                    textattribute(dan_psl5_z)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_psl5_z, 'dan_psl5_z');
                        end;
                    }
                    textattribute(obrat5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(obrat5, 'obrat5');
                        end;
                    }
                    textattribute(dan_dzb23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_dzb23, 'dan_dzb23');
                        end;
                    }
                    textattribute(p_dop_nrg)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(p_dop_nrg, 'p_dop_nrg');
                        end;
                    }
                    textattribute(dan5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan5, 'dan5');
                        end;
                    }
                    textattribute(dan_psl23_e)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_psl23_e, 'dan_psl23_e');
                        end;
                    }
                    textattribute(dan_psl5_e)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_psl5_e, 'dan_psl5_e');
                        end;
                    }
                    textattribute(dan_rpren23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_rpren23, 'dan_rpren23');
                        end;
                    }
                    textattribute(dan_rpren5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_rpren5, 'dan_rpren5');
                        end;
                    }
                    textattribute(rez_pren23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(rez_pren23, 'rez_pren23');
                        end;
                    }
                    textattribute(rez_pren5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(rez_pren5, 'rez_pren5');
                        end;
                    }
                }
                textelement(Veta2)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    textattribute(pln_vyvoz)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(pln_vyvoz, 'pln_vyvoz');
                        end;
                    }
                    textattribute(pln_ost)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(pln_ost, 'pln_ost');
                        end;
                    }
                    textattribute(dod_dop_nrg)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dod_dop_nrg, 'dod_dop_nrg');
                        end;
                    }
                    textattribute(dod_zb)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dod_zb, 'dod_zb');
                        end;
                    }
                    textattribute(pln_sluzby)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(pln_sluzby, 'pln_sluzby');
                        end;
                    }
                    textattribute(pln_zaslani)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(pln_zaslani, 'pln_zaslani');
                        end;
                    }
                    textattribute(pln_rez_pren)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(pln_rez_pren, 'pln_rez_pren');
                        end;
                    }
                }
                textelement(Veta3)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    textattribute(tri_pozb)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(tri_pozb, 'tri_pozb');
                        end;
                    }
                    textattribute(tri_dozb)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(tri_dozb, 'tri_dozb');
                        end;
                    }
                    textattribute(dov_osv)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dov_osv, 'dov_osv');
                        end;
                    }
                    textattribute(opr_dluz)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(opr_dluz, 'opr_dluz');
                        end;
                    }
                    textattribute(opr_verit)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(opr_verit, 'opr_verit');
                        end;
                    }
                }
                textelement(Veta4)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    textattribute(odp_tuz5_nar)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_tuz5_nar, 'odp_tuz5_nar');
                        end;
                    }
                    textattribute(odp_sum_nar)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_sum_nar, 'odp_sum_nar');
                        end;
                    }
                    textattribute(odp_tuz5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_tuz5, 'odp_tuz5');
                        end;
                    }
                    textattribute(odp_rezim)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_rezim, 'odp_rezim');
                        end;
                    }
                    textattribute(odp_sum_kr)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_sum_kr, 'odp_sum_kr');
                        end;
                    }
                    textattribute(pln23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(pln23, 'pln23');
                        end;
                    }
                    textattribute(odp_rez_nar)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_rez_nar, 'odp_rez_nar');
                        end;
                    }
                    textattribute(odp_tuz23_nar)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_tuz23_nar, 'odp_tuz23_nar');
                        end;
                    }
                    textattribute(pln5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(pln5, 'pln5');
                        end;
                    }
                    textattribute(odp_tuz23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_tuz23, 'odp_tuz23');
                        end;
                    }
                    textattribute(nar_maj)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(nar_maj, 'nar_maj');
                        end;
                    }
                    textattribute(nar_zdp23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(nar_zdp23, 'nar_zdp23');
                        end;
                    }
                    textattribute(nar_zdp5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(nar_zdp5, 'nar_zdp5');
                        end;
                    }
                    textattribute(od_maj)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(od_maj, 'od_maj');
                        end;
                    }
                    textattribute(odkr_zdp23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odkr_zdp23, 'odkr_zdp23');
                        end;
                    }
                    textattribute(od_zdp23)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(od_zdp23, 'od_zdp23');
                        end;
                    }
                    textattribute(odkr_maj)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odkr_maj, 'odkr_maj');
                        end;
                    }
                    textattribute(od_zdp5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(od_zdp5, 'od_zdp5');
                        end;
                    }
                    textattribute(odkr_zdp5)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odkr_zdp5, 'odkr_zdp5');
                        end;
                    }
                    textattribute(dov_cu)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dov_cu, 'dov_cu');
                        end;
                    }
                    textattribute(odp_cu)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_cu, 'odp_cu');
                        end;
                    }
                    textattribute(odp_cu_nar)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_cu_nar, 'odp_cu_nar');
                        end;
                    }
                }
                textelement(Veta5)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    textattribute(odp_uprav_kf)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_uprav_kf, 'odp_uprav_kf');
                        end;
                    }
                    textattribute(vypor_odp)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(vypor_odp, 'vypor_odp');
                        end;
                    }
                    textattribute(koef_p20_nov)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(koef_p20_nov, 'koef_p20_nov');
                        end;
                    }
                    textattribute(plnosv_nkf)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(plnosv_nkf, 'plnosv_nkf');
                        end;
                    }
                    textattribute(koef_p20_vypor)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(koef_p20_vypor, 'koef_p20_vypor');
                        end;
                    }
                    textattribute(pln_nkf)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(pln_nkf, 'pln_nkf');
                        end;
                    }
                    textattribute(plnosv_kf)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(plnosv_kf, 'plnosv_kf');
                        end;
                    }
                }
                textelement(Veta6)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    textattribute(dan_vrac)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_vrac, 'dan_vrac');
                        end;
                    }
                    textattribute(dano)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dano, 'dano');
                        end;
                    }
                    textattribute(odp_zocelk)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(odp_zocelk, 'odp_zocelk');
                            ValidateZocelk();
                        end;
                    }
                    textattribute(dano_no)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(dan_zocelk)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(dan_zocelk, 'dan_zocelk');
                            ValidateZocelk();
                        end;
                    }
                    textattribute(dano_da)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(uprav_odp)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            GetAmtAndSkipIfEmpty(uprav_odp, 'uprav_odp');
                        end;
                    }
                }
                tableelement(commentline; "VAT Statement Comment Line")
                {
                    LinkFields = "VAT Statement Template Name" = FIELD("Statement Template Name"), "VAT Statement Name" = FIELD(Name);
                    LinkTable = VATStatementName;
                    MinOccurs = Zero;
                    XmlName = 'VetaR';
                    textattribute(sectioncode)
                    {
                        Occurrence = Optional;
                        XmlName = 'kod_sekce';
                    }
                    textattribute(commentlineno)
                    {
                        XmlName = 'poradi';
                    }
                    fieldattribute(t_prilohy; CommentLine.Comment)
                    {
                        Occurrence = Optional;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CurrNo += 1;
                        CommentLineNo := Format(CurrNo);
                        SectionCode := GetSectionCode();
                    end;

                    trigger OnPreXmlItem()
                    begin
                        CurrNo := 0;
                    end;
                }
                textelement(Prilohy)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    tableelement(attachment; "VAT Statement Attachment")
                    {
                        LinkFields = "VAT Statement Template Name" = FIELD("Statement Template Name"), "VAT Statement Name" = FIELD(Name);
                        LinkTable = VATStatementName;
                        MinOccurs = Zero;
                        XmlName = 'ObecnaPriloha';
                        SourceTableView = WHERE("File Name" = FILTER(<> ''));
                        textattribute(attachmentno)
                        {
                            XmlName = 'cislo';
                        }
                        fieldattribute(nazev; Attachment.Description)
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(jm_souboru; Attachment."File Name")
                        {
                            Occurrence = Optional;
                        }
                        textattribute(kodovani)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassVariable()
                            begin
                                kodovani := 'base64';
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            CurrNo += 1;
                            AttachmentNo := Format(CurrNo);
                        end;

                        trigger OnPreXmlItem()
                        begin
                            CurrNo := 0;
                        end;
                    }
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        CompanyInfo: Record "Company Information";
        TempXMLExportBuffer: Record "XML Export Buffer" temporary;
        DeclarationType: Option Recapitulative,Corrective,Supplementary,"Supplementary/Corrective";
        CurrNo: Integer;
        MustBeGreaterErr: Label '%1 length must not be greater than %2.', Comment = '%1 = fieldcaption; %2 = length';

    [Scope('OnPrem')]
    procedure SetParameters(Month1: Integer; Quarter1: Integer; Year1: Integer; DeclarationType1: Option Recapitulative,Corrective,Supplementary; ReasonsObservedOn1: Date; FilledByEmployeeNo1: Code[20]; NoTax1: Boolean)
    var
        CompanyOfficials: Record "Company Officials";
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        StatReportingSetup.Get;
        CompanyInfo.Get;

        SWVersion := ApplicationSystemConstants.ApplicationVersion();
        SWName := 'Microsoft Dynamics NAV';
        XMLVersion := '01.02';

        if Month1 <> 0 then
            Month := Format(Month1);
        if Quarter1 <> 0 then
            Quarter := Format(Quarter1);
        if Year1 <> 0 then
            Year := Format(Year1);

        DeclarationType := DeclarationType1;
        if ReasonsObservedOn1 <> 0D then
            ReasonsObservedOn := Format(ReasonsObservedOn1, 0, '<Day,2>.<Month,2>.<Year4>');
        TodayDate := Format(Today(), 0, '<Day,2>.<Month,2>.<Year4>');
        TaxPayerStatus := GetTaxPayerStatus();

        MainEcActCode1 :=
          CheckLen(StatReportingSetup."Main Economic Activity I Code",
            StatReportingSetup.FieldCaption("Main Economic Activity I Code"), 6);
        TaxOfficeNumber :=
          CheckLen(StatReportingSetup."Tax Office Number", StatReportingSetup.FieldCaption("Tax Office Number"), 3);

        if StatReportingSetup."Tax Office Region Number" <> '' then
            TaxOfficeRegionNumber :=
              CheckLen(StatReportingSetup."Tax Office Region Number",
                StatReportingSetup.FieldCaption("Tax Office Region Number"), 4);

        if CopyStr(CompanyInfo."VAT Registration No.", 1, 2) = CompanyInfo."Country/Region Code" then
            VATRegNo := CopyStr(CompanyInfo."VAT Registration No.", 3)
        else
            VATRegNo := CompanyInfo."VAT Registration No.";

        TaxPayerType := GetTaxPayerType();
        NatPersLastName := StatReportingSetup."Natural Person First Name";
        NatPersFirstName :=
          CheckLen(StatReportingSetup."Natural Person Surname", StatReportingSetup.FieldCaption("Natural Person Surname"), 20);
        NatPersTitle :=
          CheckLen(StatReportingSetup."Natural Person Title", StatReportingSetup.FieldCaption("Natural Person Title"), 10);

        CompanyTradeName := StatReportingSetup."Company Trade Name";
        City := CompanyInfo.City;
        Street := CheckLen(StatReportingSetup.Street, StatReportingSetup.FieldCaption(Street), 38);
        HouseNo := CheckLen(StatReportingSetup."House No.", StatReportingSetup.FieldCaption("House No."), 6);
        MunicipalityNo :=
          CheckLen(StatReportingSetup."Municipality No.", StatReportingSetup.FieldCaption("Municipality No."), 4);
        PostCode := CheckLen(DelChr(CompanyInfo."Post Code", '=', ' '), CompanyInfo.FieldCaption("Post Code"), 5);

        StatReportingSetup.TestField("VAT Stat. Auth.Employee No.");
        CompanyOfficials.Get(StatReportingSetup."VAT Stat. Auth.Employee No.");
        AuthEmpLastName := CompanyOfficials."Last Name";
        AuthEmpFirstName := CheckLen(CompanyOfficials."First Name", CompanyOfficials.FieldCaption("First Name"), 20);
        AuthEmpJobTitle := CompanyOfficials."Job Title";

        CompanyOfficials.Get(FilledByEmployeeNo1);
        FillEmpLastName := CompanyOfficials."Last Name";
        FillEmpFirstName := CheckLen(CompanyOfficials."First Name", CompanyOfficials.FieldCaption("First Name"), 20);
        FillEmpPhoneNo := CheckLen(CompanyOfficials."Phone No.", CompanyOfficials.FieldCaption("Phone No."), 14);

        NoTax := GetNoTax(NoTax1);

        CompEmail := CompanyInfo."E-Mail";
        CompPhoneNo := CheckLen(CompanyInfo."Phone No.", CompanyInfo.FieldCaption("Phone No."), 14);
        CompRegion := StatReportingSetup."VAT Statement Country Name";

        zast_kod := StatReportingSetup."Official Code";
        zast_typ := FormatCompanyType(StatReportingSetup."Official Type");
        zast_nazev := StatReportingSetup."Official Name";
        zast_jmeno := StatReportingSetup."Official First Name";
        zast_prijmeni := StatReportingSetup."Official Surname";
        zast_dat_nar := FormatDate(StatReportingSetup."Official Birth Date");
        zast_ev_cislo := StatReportingSetup."Official Reg.No.of Tax Adviser";
        zast_ic := StatReportingSetup."Official Registration No.";
    end;

    [Scope('OnPrem')]
    procedure ClearVariables()
    begin
        ClearAll();
    end;

    local procedure CheckLen(FieldValue: Text[50]; FieldCaption: Text; MaxLen: Integer): Text[50]
    begin
        if StrLen(FieldValue) > MaxLen then
            Error(MustBeGreaterErr, FieldCaption, MaxLen);
        exit(FieldValue);
    end;

    local procedure ValidateZocelk()
    var
        Amount1: Decimal;
        Amount2: Decimal;
        ExistAmount1: Boolean;
        ExistAmount2: Boolean;
    begin
        ExistAmount1 := TempXMLExportBuffer.Get(UpperCase('odp_zocelk'));
        if ExistAmount1 then
            Amount1 := TempXMLExportBuffer.Amount;

        ExistAmount2 := TempXMLExportBuffer.Get(UpperCase('dan_zocelk'));
        if ExistAmount2 then
            Amount2 := TempXMLExportBuffer.Amount;

        if ExistAmount1 and ExistAmount2 then
            if Amount1 < Amount2 then
                SetDanoDa()
            else
                SetDanoNo();

        if ExistAmount1 and not ExistAmount2 then
            SetDanoNo();

        if ExistAmount2 and not ExistAmount1 then
            SetDanoDa();
    end;

    local procedure SetDanoDa()
    begin
        dano_no := '';
        dano_da := GetAmount('dano_da');
        dano_da := DelChr(dano_da, '=', '-');
    end;

    local procedure SetDanoNo()
    begin
        dano_da := '';
        dano_no := GetAmount('dano_no');
        dano_no := DelChr(dano_no, '=', '-');
    end;

    local procedure GetFormType(): Code[1]
    begin
        case DeclarationType of
            DeclarationType::Recapitulative:
                exit('B');
            DeclarationType::Corrective:
                exit('O');
            DeclarationType::Supplementary:
                exit('D');
            DeclarationType::"Supplementary/Corrective":
                exit('E');
        end;
    end;

    local procedure GetTaxPayerStatus(): Code[1]
    begin
        case StatReportingSetup."Tax Payer Status" of
            StatReportingSetup."Tax Payer Status"::Payer:
                exit('P');
            StatReportingSetup."Tax Payer Status"::"Non-payer",
          StatReportingSetup."Tax Payer Status"::Other:
                exit('I');
            StatReportingSetup."Tax Payer Status"::"VAT Group":
                exit('S');
        end;
    end;

    local procedure GetSectionCode(): Code[1]
    begin
        case DeclarationType of
            DeclarationType::Recapitulative,
          DeclarationType::Corrective:
                exit('O');
            DeclarationType::Supplementary,
          DeclarationType::"Supplementary/Corrective":
                exit('D');
        end;
    end;

    local procedure GetNoTax(NewNoTax: Boolean): Code[1]
    begin
        if NewNoTax then
            exit('N');
        exit('A');
    end;

    local procedure GetTaxPayerType(): Code[1]
    begin
        CompanyInfo.TestField("Company Type");
        case CompanyInfo."Company Type" of
            CompanyInfo."Company Type"::Corporate:
                exit('P');
            CompanyInfo."Company Type"::Individual:
                exit('F');
        end;
    end;

    [Scope('OnPrem')]
    procedure SetVATStatementName(NewVATStatementName: Record "VAT Statement Name")
    begin
        VATStatementName.SetRange("Statement Template Name", NewVATStatementName."Statement Template Name");
        VATStatementName.SetRange(Name, NewVATStatementName.Name);
    end;

    local procedure GetAmount(XMLTag: Code[20]): Text[14]
    begin
        if TempXMLExportBuffer.Get(XMLTag) then
            if TempXMLExportBuffer.Amount <> 0 then
                exit(Format(TempXMLExportBuffer.Amount, 0, 9));
        exit('');
    end;

    [Scope('OnPrem')]
    procedure AddAmount(XMLTag: Code[20]; Amount: Decimal)
    begin
        if TempXMLExportBuffer.Get(XMLTag) then begin
            TempXMLExportBuffer.Amount += Amount;
            TempXMLExportBuffer.Modify();
        end else begin
            TempXMLExportBuffer."XML Tag" := XMLTag;
            TempXMLExportBuffer.Amount := Amount;
            TempXMLExportBuffer.Insert();
        end;
    end;

    local procedure SkipEmptyValue(Value: Text[1024])
    begin
        if IsServiceTier then
            if Value = '' then
                currXMLport.Skip();
    end;

    local procedure GetAmtAndSkipIfEmpty(var Value: Text[1024]; XMLTag: Code[20])
    begin
        Value := GetAmount(XMLTag);
        SkipEmptyValue(Value);
    end;

    [Scope('OnPrem')]
    procedure SetParam2(lopKod_zo: Option ,Q2,M10,Q,M; ldaStartDate: Date; ldaStopDate: Date)
    begin
        case lopKod_zo of
            lopKod_zo::Q2:
                gtekod_zo := 'Q2';
            lopKod_zo::M10:
                gtekod_zo := 'M10';
            lopKod_zo::Q:
                gtekod_zo := 'Q';
            lopKod_zo::M:
                gtekod_zo := 'M';
        end;

        if ldaStartDate <> 0D then
            gtezdobd_od := Format(ldaStartDate, 0, '<Day,2>.<Month,2>.<Year4>');
        if ldaStopDate <> 0D then
            gtezdobd_do := Format(ldaStopDate, 0, '<Day,2>.<Month,2>.<Year4>');
    end;

    local procedure FormatCompanyType(CompanyType: Option " ",Individual,Corporate): Text[1]
    begin
        case CompanyType of
            CompanyType::" ":
                exit('');
            CompanyType::Corporate:
                exit('P');
            CompanyType::Individual:
                exit('F');
        end;
    end;

    local procedure FormatDate(Date: Date): Text
    begin
        exit(Format(Date, 0, '<Day,2>.<Month,2>.<Year4>'));
    end;
}

