xmlport 31100 "VAT Control Report"
{
    Caption = 'VAT Control Report';
    Direction = Export;
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
            textelement("<dphkh1>")
            {
                MaxOccurs = Once;
                MinOccurs = Zero;
                XmlName = 'DPHKH1';
                textelement(VetaD)
                {
                    MaxOccurs = Once;
                    MinOccurs = Once;
                    textattribute(year)
                    {
                        Occurrence = Optional;
                        XmlName = 'rok';
                    }
                    textattribute(formtype)
                    {
                        XmlName = 'khdph_forma';
                    }
                    textattribute(kh1)
                    {
                        XmlName = 'dokument';
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
                    textattribute(vyzva_odp)
                    {
                        Occurrence = Optional;
                        XmlName = 'vyzva_odp';
                    }
                    textattribute(quarter)
                    {
                        Occurrence = Optional;
                        XmlName = 'ctvrt';
                    }
                    textattribute(month)
                    {
                        Occurrence = Optional;
                        XmlName = 'mesic';
                    }
                    textattribute(todaydate)
                    {
                        Occurrence = Optional;
                        XmlName = 'd_poddp';
                    }
                    textattribute(dph)
                    {
                        Occurrence = Optional;
                        XmlName = 'k_uladis';
                    }
                    textattribute(c_jed_vyzvy)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_jed_vyzvy';
                    }
                }
                textelement(VetaP)
                {
                    MaxOccurs = Once;
                    MinOccurs = Once;
                    textattribute(fillempphoneno)
                    {
                        Occurrence = Optional;
                        XmlName = 'sest_telef';
                    }
                    textattribute(houseno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_pop';
                    }
                    textattribute(natperstitle)
                    {
                        Occurrence = Optional;
                        XmlName = 'titul';
                    }
                    textattribute(opr_prijmeni)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_prijmeni';
                    }
                    textattribute(compemail)
                    {
                        XmlName = 'email';
                    }
                    textattribute(postcode)
                    {
                        Occurrence = Optional;
                        XmlName = 'psc';
                    }
                    textattribute(zast_ic)
                    {
                        Occurrence = Optional;
                        XmlName = 'zast_ic';
                    }
                    textattribute(taxpayertype)
                    {
                        Occurrence = Optional;
                        XmlName = 'typ_ds';
                    }
                    textattribute(zast_nazev)
                    {
                        Occurrence = Optional;
                        XmlName = 'zast_nazev';
                    }
                    textattribute(compphoneno)
                    {
                        XmlName = 'c_telef';
                    }
                    textattribute(zast_jmeno)
                    {
                        Occurrence = Optional;
                        XmlName = 'zast_jmeno';
                    }
                    textattribute(zast_prijmeni)
                    {
                        XmlName = 'zast_prijmeni';
                    }
                    textattribute(city)
                    {
                        Occurrence = Optional;
                        XmlName = 'naz_obce';
                    }
                    textattribute(zast_typ)
                    {
                        Occurrence = Optional;
                        XmlName = 'zast_typ';
                    }
                    textattribute(c_ufo)
                    {
                        Occurrence = Required;
                        XmlName = 'c_ufo';
                    }
                    textattribute(companytradename)
                    {
                        Occurrence = Optional;
                        XmlName = 'zkrobchjm';
                    }
                    textattribute(c_pracufo)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_pracufo';
                    }
                    textattribute(compregion)
                    {
                        Occurrence = Optional;
                        XmlName = 'stat';
                    }
                    textattribute(authempjobtitle)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_postaveni';
                    }
                    textattribute(zast_dat_nar)
                    {
                        Occurrence = Optional;
                        XmlName = 'zast_dat_nar';
                    }
                    textattribute(natpersfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'jmeno';
                    }
                    textattribute(fillemplastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'sest_prijmeni';
                    }
                    textattribute(zast_ev_cislo)
                    {
                        Occurrence = Optional;
                        XmlName = 'zast_ev_cislo';
                    }
                    textattribute(municipalityno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_orient';
                    }
                    textattribute(authemplastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_prijmeni';
                    }
                    textattribute(fillempfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'sest_jmeno';
                    }
                    textattribute(natperslastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'prijmeni';
                    }
                    textattribute(street)
                    {
                        Occurrence = Optional;
                        XmlName = 'ulice';
                    }
                    textattribute(zast_kod)
                    {
                        Occurrence = Optional;
                        XmlName = 'zast_kod';
                    }
                    textattribute(vatregno)
                    {
                        XmlName = 'dic';
                    }
                    textattribute(authempfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_jmeno';
                    }
                    textattribute(id_dats)
                    {
                        Occurrence = Optional;
                        XmlName = 'id_dats';
                    }
                }
                tableelement(a1; "VAT Control Report Buffer")
                {
                    MinOccurs = Zero;
                    XmlName = 'VetaA1';
                    UseTemporary = true;
                    textattribute(a1_c_evid_dd)
                    {
                        Occurrence = Required;
                        XmlName = 'c_evid_dd';
                    }
                    textattribute(a1_zakl_dane1)
                    {
                        Occurrence = Required;
                        XmlName = 'zakl_dane1';
                    }
                    textattribute(a1_c_radku)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_radku';
                    }
                    textattribute(a1_duzp)
                    {
                        Occurrence = Required;
                        XmlName = 'duzp';
                    }
                    textattribute(a1_dic_odb)
                    {
                        Occurrence = Required;
                        XmlName = 'dic_odb';
                    }
                    textattribute(a1_kod_pred_pl)
                    {
                        Occurrence = Required;
                        XmlName = 'kod_pred_pl';
                    }

                    trigger OnAfterGetRecord()
                    begin
                        A1_c_evid_dd := A1."Document No.";
                        A1_zakl_dane1 := FormatDec(A1."Base 1" + A1."Base 2" + A1."Base 3");
                        A1_c_radku := FormatInt(A1."Line No.");
                        A1_duzp := FormatDate(A1."VAT Date");
                        A1_dic_odb := FormatVATRegistration(A1."VAT Registration No.");
                        A1_kod_pred_pl := LowerCase(A1."Commodity Code");

                        if A1."Original Document VAT Date" <> 0D then
                            A1_duzp := FormatDate(A1."Original Document VAT Date");
                    end;

                    trigger OnPreXmlItem()
                    begin
                        CopyBufferToSection(A1, 'A1');
                    end;
                }
                tableelement(a2; "VAT Control Report Buffer")
                {
                    MinOccurs = Zero;
                    XmlName = 'VetaA2';
                    UseTemporary = true;
                    textattribute(a2_c_evid_dd)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_evid_dd';
                    }
                    textattribute(a2_dan1)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan1';
                    }
                    textattribute(a2_c_radku)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_radku';
                    }
                    textattribute(a2_dppd)
                    {
                        Occurrence = Required;
                        XmlName = 'dppd';
                    }
                    textattribute(a2_zakl_dane2)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane2';
                    }
                    textattribute(a2_dan2)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan2';
                    }
                    textattribute(a2_dan3)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan3';
                    }
                    textattribute(a2_vatid_dod)
                    {
                        Occurrence = Optional;
                        XmlName = 'vatid_dod';
                    }
                    textattribute(a2_zakl_dane1)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane1';
                    }
                    textattribute(a2_zakl_dane3)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane3';
                    }
                    textattribute(a2_k_stat)
                    {
                        Occurrence = Optional;
                        XmlName = 'k_stat';
                    }

                    trigger OnAfterGetRecord()
                    begin
                        A2_c_evid_dd := A2."Document No.";
                        A2_dan1 := FormatDec(A2."Amount 1");
                        A2_c_radku := FormatInt(A2."Line No.");
                        A2_dppd := FormatDate(A2."VAT Date");
                        A2_zakl_dane2 := FormatDec(A2."Base 2");
                        A2_dan2 := FormatDec(A2."Amount 2");
                        A2_dan3 := FormatDec(A2."Amount 3");
                        A2_vatid_dod := FormatVATRegistration(A2."VAT Registration No.");
                        A2_zakl_dane1 := FormatDec(A2."Base 1");
                        A2_zakl_dane3 := FormatDec(A2."Base 3");
                        A2_k_stat := GetCountryCodeFromVATRegistrationNo(A2."VAT Registration No.");

                        if A2."Original Document VAT Date" <> 0D then
                            A2_dppd := FormatDate(A2."Original Document VAT Date");
                    end;

                    trigger OnPreXmlItem()
                    begin
                        CopyBufferToSection(A2, 'A2');
                    end;
                }
                tableelement(a3; "VAT Control Report Buffer")
                {
                    MinOccurs = Zero;
                    XmlName = 'VetaA3';
                    UseTemporary = true;
                    textattribute(a3_jm_prijm_obch)
                    {
                        Occurrence = Optional;
                        XmlName = 'jm_prijm_obch';
                    }
                    textattribute(a3_m_pobytu_sidlo)
                    {
                        Occurrence = Optional;
                        XmlName = 'm_pobytu_sidlo';
                    }
                    textattribute(a3_c_evid_dd)
                    {
                        XmlName = 'c_evid_dd';
                    }
                    textattribute(a3_k_stat)
                    {
                        Occurrence = Optional;
                        XmlName = 'k_stat';
                    }
                    textattribute(a3_c_radku)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_radku';
                    }
                    textattribute(a3_vatid_odb)
                    {
                        Occurrence = Optional;
                        XmlName = 'vatid_odb';
                    }
                    textattribute(a3_osv_plneni)
                    {
                        Occurrence = Required;
                        XmlName = 'osv_plneni';
                    }
                    textattribute(a3_d_narozeni)
                    {
                        Occurrence = Optional;
                        XmlName = 'd_narozeni';
                    }
                    textattribute(a3_dup)
                    {
                        XmlName = 'dup';
                    }

                    trigger OnAfterGetRecord()
                    begin
                        A3_jm_prijm_obch := A3.Name;
                        A3_m_pobytu_sidlo := A3."Place of stay";
                        A3_c_evid_dd := A3."Document No.";
                        A3_c_radku := FormatInt(A3."Line No.");
                        A3_vatid_odb := FormatVATRegistration(A3."VAT Registration No.");
                        A3_osv_plneni := FormatDec(A3."Base 1" + A3."Amount 1");
                        A3_d_narozeni := FormatDate(A3."Birth Date");
                        A3_dup := FormatDate(A3."VAT Date");
                        A3_k_stat := GetCountryCodeFromVATRegistrationNo(A3."VAT Registration No.");

                        if A3."Original Document VAT Date" <> 0D then
                            A3_dup := FormatDate(A3."Original Document VAT Date");
                    end;

                    trigger OnPreXmlItem()
                    begin
                        CopyBufferToSection(A3, 'A3');
                    end;
                }
                tableelement(a4; "VAT Control Report Buffer")
                {
                    MinOccurs = Zero;
                    XmlName = 'VetaA4';
                    UseTemporary = true;
                    textattribute(a4_c_evid_dd)
                    {
                        XmlName = 'c_evid_dd';
                    }
                    textattribute(a4_zakl_dane1)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane1';
                    }
                    textattribute(a4_zakl_dane2)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane2';
                    }
                    textattribute(a4_dan1)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan1';
                    }
                    textattribute(a4_dic_odb)
                    {
                        Occurrence = Required;
                        XmlName = 'dic_odb';
                    }
                    textattribute(a4_dppd)
                    {
                        Occurrence = Required;
                        XmlName = 'dppd';
                    }
                    textattribute(a4_dan2)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan2';
                    }
                    textattribute(a4_kod_rezim_pl)
                    {
                        XmlName = 'kod_rezim_pl';
                    }
                    textattribute(a4_zdph_44)
                    {
                        XmlName = 'zdph_44';
                    }
                    textattribute(a4_c_radku)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_radku';
                    }
                    textattribute(a4_zakl_dane3)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane3';
                    }
                    textattribute(a4_dan3)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan3';
                    }

                    trigger OnAfterGetRecord()
                    begin
                        A4_c_evid_dd := A4."Document No.";
                        A4_zakl_dane1 := FormatDec(A4."Base 1");
                        A4_zakl_dane2 := FormatDec(A4."Base 2");
                        A4_dan1 := FormatDec(A4."Amount 1");
                        A4_dic_odb := FormatVATRegistration(A4."VAT Registration No.");
                        A4_dppd := FormatDate(A4."VAT Date");
                        A4_dan2 := FormatDec(A4."Amount 2");
                        A4_kod_rezim_pl := Format(A4."Supplies Mode Code");
                        A4_zdph_44 := FormatCorrectionsForBadReceivable(A4."Corrections for Bad Receivable");
                        A4_c_radku := FormatInt(A4."Line No.");
                        A4_zakl_dane3 := FormatDec(A4."Base 3");
                        A4_dan3 := FormatDec(A4."Amount 3");

                        if A4."Original Document VAT Date" <> 0D then
                            A4_dppd := FormatDate(A4."Original Document VAT Date");

                        if A4."Corrections for Bad Receivable" = A4."Corrections for Bad Receivable"::"Insolvency Proceedings (p.44)" then begin
                            A4_zakl_dane1 := '';
                            A4_zakl_dane2 := '';
                            A4_zakl_dane3 := '';
                        end;
                    end;

                    trigger OnPreXmlItem()
                    begin
                        CopyBufferToSection(A4, 'A4');
                    end;
                }
                tableelement(a5; "VAT Control Report Buffer")
                {
                    MinOccurs = Zero;
                    XmlName = 'VetaA5';
                    UseTemporary = true;
                    textattribute(a5_zakl_dane2)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane2';
                    }
                    textattribute(a5_dan2)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan2';
                    }
                    textattribute(a5_dan3)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan3';
                    }
                    textattribute(a5_dan1)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan1';
                    }
                    textattribute(a5_zakl_dane3)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane3';
                    }
                    textattribute(a5_zakl_dane1)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane1';
                    }

                    trigger OnAfterGetRecord()
                    begin
                        A5_dan1 := FormatDec(A5."Amount 1");
                        A5_dan2 := FormatDec(A5."Amount 2");
                        A5_dan3 := FormatDec(A5."Amount 3");
                        A5_zakl_dane1 := FormatDec(A5."Base 1");
                        A5_zakl_dane2 := FormatDec(A5."Base 2");
                        A5_zakl_dane3 := FormatDec(A5."Base 3");
                    end;

                    trigger OnPreXmlItem()
                    begin
                        CopyBufferToSection(A5, 'A5');
                    end;
                }
                tableelement(b1; "VAT Control Report Buffer")
                {
                    MinOccurs = Zero;
                    XmlName = 'VetaB1';
                    UseTemporary = true;
                    textattribute(b1_zakl_dane2)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane2';
                    }
                    textattribute(b1_zakl_dane3)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane3';
                    }
                    textattribute(b1_dan3)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan3';
                    }
                    textattribute(b1_duzp)
                    {
                        Occurrence = Required;
                        XmlName = 'duzp';
                    }
                    textattribute(b1_dan2)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan2';
                    }
                    textattribute(b1_c_radku)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_radku';
                    }
                    textattribute(b1_dan1)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan1';
                    }
                    textattribute(b1_kod_pred_pl)
                    {
                        Occurrence = Required;
                        XmlName = 'kod_pred_pl';
                    }
                    textattribute(b1_dic_dod)
                    {
                        Occurrence = Required;
                        XmlName = 'dic_dod';
                    }
                    textattribute(b1_zakl_dane1)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane1';
                    }
                    textattribute(b1_c_evid_dd)
                    {
                        Occurrence = Required;
                        XmlName = 'c_evid_dd';
                    }

                    trigger OnAfterGetRecord()
                    begin
                        B1_zakl_dane2 := FormatDec(B1."Base 2");
                        B1_zakl_dane3 := FormatDec(B1."Base 3");
                        B1_dan3 := FormatDec(B1."Amount 3");
                        B1_duzp := FormatDate(B1."VAT Date");
                        B1_dan2 := FormatDec(B1."Amount 2");
                        B1_c_radku := FormatInt(B1."Line No.");
                        B1_dan1 := FormatDec(B1."Amount 1");
                        B1_kod_pred_pl := LowerCase(B1."Commodity Code");
                        B1_dic_dod := FormatVATRegistration(B1."VAT Registration No.");
                        B1_zakl_dane1 := FormatDec(B1."Base 1");
                        B1_c_evid_dd := B1."Document No.";

                        if B1."Original Document VAT Date" <> 0D then
                            B1_duzp := FormatDate(B1."Original Document VAT Date");
                    end;

                    trigger OnPreXmlItem()
                    begin
                        CopyBufferToSection(B1, 'B1');
                    end;
                }
                tableelement(b2; "VAT Control Report Buffer")
                {
                    MinOccurs = Zero;
                    XmlName = 'VetaB2';
                    UseTemporary = true;
                    textattribute(b2_zakl_dane3)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane3';
                    }
                    textattribute(b2_pomer)
                    {
                        Occurrence = Optional;
                        XmlName = 'pomer';
                    }
                    textattribute(b2_dppd)
                    {
                        Occurrence = Required;
                        XmlName = 'dppd';
                    }
                    textattribute(b2_c_radku)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_radku';
                    }
                    textattribute(b2_dan2)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan2';
                    }
                    textattribute(b2_zakl_dane1)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane1';
                    }
                    textattribute(b2_zdph_44)
                    {
                        XmlName = 'zdph_44';
                    }
                    textattribute(b2_dic_dod)
                    {
                        XmlName = 'dic_dod';
                    }
                    textattribute(b2_zakl_dane2)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane2';
                    }
                    textattribute(b2_dan1)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan1';
                    }
                    textattribute(b2_c_evid_dd)
                    {
                        XmlName = 'c_evid_dd';
                    }
                    textattribute(b2_dan3)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan3';
                    }

                    trigger OnAfterGetRecord()
                    begin
                        B2_zakl_dane3 := FormatDec(B2."Base 3");
                        B2_pomer := FormatBool(B2."Ratio Use");
                        B2_dppd := FormatDate(B2."VAT Date");
                        B2_c_radku := FormatInt(B2."Line No.");
                        B2_dan2 := FormatDec(B2."Amount 2");
                        B2_zakl_dane1 := FormatDec(B2."Base 1");
                        B2_zdph_44 := FormatCorrectionsForBadReceivable(B2."Corrections for Bad Receivable");
                        B2_dic_dod := FormatVATRegistration(B2."VAT Registration No.");
                        B2_zakl_dane2 := FormatDec(B2."Base 2");
                        B2_dan1 := FormatDec(B2."Amount 1");
                        B2_c_evid_dd := B2."Document No.";
                        B2_dan3 := FormatDec(B2."Amount 3");

                        if B2."Original Document VAT Date" <> 0D then
                            B2_dppd := FormatDate(B2."Original Document VAT Date");

                        if B2."Corrections for Bad Receivable" = B2."Corrections for Bad Receivable"::"Insolvency Proceedings (p.44)" then begin
                            B2_zakl_dane1 := '';
                            B2_zakl_dane2 := '';
                            B2_zakl_dane3 := '';
                        end;
                    end;

                    trigger OnPreXmlItem()
                    begin
                        CopyBufferToSection(B2, 'B2');
                    end;
                }
                tableelement(b3; "VAT Control Report Buffer")
                {
                    MinOccurs = Zero;
                    XmlName = 'VetaB3';
                    UseTemporary = true;
                    textattribute(b3_zakl_dane2)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane2';
                    }
                    textattribute(b3_dan3)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan3';
                    }
                    textattribute(b3_zakl_dane3)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane3';
                    }
                    textattribute(b3_dan2)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan2';
                    }
                    textattribute(b3_dan1)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan1';
                    }
                    textattribute(b3_zakl_dane1)
                    {
                        Occurrence = Optional;
                        XmlName = 'zakl_dane1';
                    }

                    trigger OnAfterGetRecord()
                    begin
                        B3_dan1 := FormatDec(B3."Amount 1");
                        B3_dan2 := FormatDec(B3."Amount 2");
                        B3_dan3 := FormatDec(B3."Amount 3");
                        B3_zakl_dane1 := FormatDec(B3."Base 1");
                        B3_zakl_dane2 := FormatDec(B3."Base 2");
                        B3_zakl_dane3 := FormatDec(B3."Base 3");
                    end;

                    trigger OnPreXmlItem()
                    begin
                        CopyBufferToSection(B3, 'B3');
                    end;
                }
                textelement(VetaC)
                {
                    MaxOccurs = Once;
                    MinOccurs = Zero;
                    textattribute(celk_zd_a2)
                    {
                        Occurrence = Optional;
                        XmlName = 'celk_zd_a2';
                    }
                    textattribute(obrat23)
                    {
                        Occurrence = Optional;
                        XmlName = 'obrat23';
                    }
                    textattribute(obrat5)
                    {
                        Occurrence = Optional;
                        XmlName = 'obrat5';
                    }
                    textattribute(pln23)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln23';
                    }
                    textattribute(pln5)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln5';
                    }
                    textattribute(pln_rez_pren)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln_rez_pren';
                    }
                    textattribute(rez_pren23)
                    {
                        Occurrence = Optional;
                        XmlName = 'rez_pren23';
                    }
                    textattribute(rez_pren5)
                    {
                        Occurrence = Optional;
                        XmlName = 'rez_pren5';
                    }

                    trigger OnBeforePassVariable()
                    begin
                        if PrintOnlyHeader then
                            currXMLport.Skip;

                        CalcTotalAmounts;
                    end;
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
        LengthMustBeErr: Label '%1 length must not be greater than %2.', Comment = '%1=Field;%2=Field Length';
        TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary;
        PrintOnlyHeader: Boolean;
        XmlFormat: Option "KH 02.01.03","KH 03.01.01";

    [Scope('OnPrem')]
    procedure SetParameters(Month1: Integer; Quarter1: Integer; Year1: Integer; DeclarationType1: Option Recapitulative,"Recapitulative-Corrective",Supplementary,"Supplementary-Corrective"; ReasonsObservedOn1: Date; FilledByEmployeeNo1: Code[20]; FastAppelReaction1: Option " ",B,P; AppelDocumentNo1: Text; XmlFormat1: Option)
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        CompanyInfo: Record "Company Information";
        CompanyOfficials: Record "Company Officials";
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        StatReportingSetup.Get;
        CompanyInfo.Get;

        SWVersion := ApplicationSystemConstants.ApplicationVersion;
        SWName := 'Microsoft Dynamics NAV';

        // 'D'
        DPH := 'DPH';
        KH1 := 'KH1';
        if Month1 <> 0 then
            Month := Format(Month1);
        if Quarter1 <> 0 then
            Quarter := Format(Quarter1);
        if Year1 <> 0 then
            Year := Format(Year1);
        FormType := FormatDeclarationType(DeclarationType1);
        if ReasonsObservedOn1 <> 0D then
            ReasonsObservedOn := FormatDate(ReasonsObservedOn1);
        TodayDate := FormatDate(Today);
        vyzva_odp := FormatFastAppelReaction(FastAppelReaction1);
        c_jed_vyzvy := AppelDocumentNo1;
        XmlFormat := XmlFormat1;

        PrintOnlyHeader := FastAppelReaction1 <> FastAppelReaction1::" ";

        // 'P'
        CheckLen(StatReportingSetup."Tax Office Number", StatReportingSetup.FieldCaption("Tax Office Number"), 3);
        c_ufo := StatReportingSetup."Tax Office Number";
        c_pracufo := StatReportingSetup."Tax Office Region Number";
        VATRegNo := FormatVATRegistration(CompanyInfo."VAT Registration No.");
        CompanyInfo.TestField("Company Type");
        case CompanyInfo."Company Type" of
            CompanyInfo."Company Type"::Corporate:
                TaxPayerType := 'P';
            CompanyInfo."Company Type"::Individual:
                TaxPayerType := 'F';
        end;
        NatPersLastName := StatReportingSetup."Natural Person First Name";
        CheckLen(StatReportingSetup."Natural Person Surname", StatReportingSetup.FieldCaption("Natural Person Surname"), 20);
        NatPersFirstName := StatReportingSetup."Natural Person Surname";
        CheckLen(StatReportingSetup."Natural Person Title", StatReportingSetup.FieldCaption("Natural Person Title"), 10);
        NatPersTitle := StatReportingSetup."Natural Person Title";
        CompanyTradeName := StatReportingSetup."Company Trade Name";
        City := CompanyInfo.City;
        CheckLen(StatReportingSetup.Street, StatReportingSetup.FieldCaption(Street), 38);
        Street := StatReportingSetup.Street;
        CheckLen(StatReportingSetup."House No.", StatReportingSetup.FieldCaption("House No."), 6);
        HouseNo := StatReportingSetup."House No.";
        CheckLen(StatReportingSetup."Municipality No.", StatReportingSetup.FieldCaption("Municipality No."), 4);
        MunicipalityNo := StatReportingSetup."Municipality No.";
        PostCode := DelChr(CompanyInfo."Post Code", '=', ' ');
        CheckLen(PostCode, CompanyInfo.FieldCaption("Post Code"), 5);
        if CompanyOfficials.Get(StatReportingSetup."VAT Stat. Auth.Employee No.") then begin
            AuthEmpLastName := CompanyOfficials."Last Name";
            CheckLen(CompanyOfficials."First Name", CompanyOfficials.FieldCaption("First Name"), 20);
            AuthEmpFirstName := CompanyOfficials."First Name";
            AuthEmpJobTitle := CompanyOfficials."Job Title";
        end;
        if CompanyOfficials.Get(FilledByEmployeeNo1) then begin
            FillEmpLastName := CompanyOfficials."Last Name";
            CheckLen(CompanyOfficials."First Name", CompanyOfficials.FieldCaption("First Name"), 20);
            FillEmpFirstName := CompanyOfficials."First Name";
            CheckLen(CompanyOfficials."Phone No.", CompanyOfficials.FieldCaption("Phone No."), 14);
            FillEmpPhoneNo := CompanyOfficials."Phone No.";
        end;

        CheckLen(CompanyInfo."Phone No.", CompanyInfo.FieldCaption("Phone No."), 14);
        CompPhoneNo := CompanyInfo."Phone No.";
        CompRegion := StatReportingSetup."VAT Statement Country Name";
        id_dats := StatReportingSetup."Data Box ID";
        CompEmail := StatReportingSetup."VAT Control Report E-mail";

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
    procedure CopyBuffer(var TempVATCtrlRptBuf2: Record "VAT Control Report Buffer" temporary)
    begin
        if PrintOnlyHeader then
            exit;

        if TempVATCtrlRptBuf2.FindSet then
            repeat
                TempVATCtrlRptBuf := TempVATCtrlRptBuf2;
                TempVATCtrlRptBuf.Insert;
            until TempVATCtrlRptBuf2.Next = 0;
    end;

    local procedure CopyBufferToSection(var TempVATCtrlRptBuf2: Record "VAT Control Report Buffer" temporary; SectionCode: Code[20])
    begin
        TempVATCtrlRptBuf2.Reset;
        TempVATCtrlRptBuf2.DeleteAll;

        TempVATCtrlRptBuf.Reset;
        TempVATCtrlRptBuf.SetRange("VAT Control Rep. Section Code", SectionCode);
        if TempVATCtrlRptBuf.FindSet then
            repeat
                if ((TempVATCtrlRptBuf."Base 1" + TempVATCtrlRptBuf."Amount 1") <> 0) or
                   ((TempVATCtrlRptBuf."Base 2" + TempVATCtrlRptBuf."Amount 2") <> 0) or
                   ((TempVATCtrlRptBuf."Base 3" + TempVATCtrlRptBuf."Amount 3") <> 0)
                then begin
                    TempVATCtrlRptBuf2 := TempVATCtrlRptBuf;
                    if TempVATCtrlRptBuf2."VAT Control Rep. Section Code" in ['A1', 'A3', 'A4', 'A5'] then begin
                        TempVATCtrlRptBuf2."Base 1" *= -1;
                        TempVATCtrlRptBuf2."Amount 1" *= -1;
                        TempVATCtrlRptBuf2."Base 2" *= -1;
                        TempVATCtrlRptBuf2."Amount 2" *= -1;
                        TempVATCtrlRptBuf2."Base 3" *= -1;
                        TempVATCtrlRptBuf2."Amount 3" *= -1;
                        TempVATCtrlRptBuf2."Total Base" *= -1;
                        TempVATCtrlRptBuf2."Total Amount" *= -1;
                    end;
                    TempVATCtrlRptBuf2.Insert;
                end;
            until TempVATCtrlRptBuf.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure ClearVariables()
    begin
        ClearAll;
    end;

    [Scope('OnPrem')]
    procedure CheckLen(FieldNam: Code[50]; FieldCapt: Text[50]; MaxLen: Integer)
    begin
        if StrLen(FieldNam) > MaxLen then
            Error(LengthMustBeErr, FieldCapt, MaxLen);
    end;

    local procedure CalcTotalAmounts()
    begin
        CalcTotalAmountsBuffer(A1);
        CalcTotalAmountsBuffer(A2);
        CalcTotalAmountsBuffer(A4);
        CalcTotalAmountsBuffer(A5);
        CalcTotalAmountsBuffer(B1);
        CalcTotalAmountsBuffer(B2);
        CalcTotalAmountsBuffer(B3);

        celk_zd_a2 := FormatDec(A2."Base 1" + A2."Base 2" + A2."Base 3");
        obrat23 := FormatDec(A4."Base 1" + A5."Base 1");
        obrat5 := FormatDec(A4."Base 2" + A4."Base 3" + A5."Base 2" + A5."Base 3");
        pln23 := FormatDec(B2."Base 1" + B3."Base 1");
        pln5 := FormatDec(B2."Base 2" + B2."Base 3" + B3."Base 2" + B3."Base 3");
        pln_rez_pren := FormatDec(A1."Base 1" + A1."Base 2" + A1."Base 3");
        rez_pren23 := FormatDec(B1."Base 1");
        rez_pren5 := FormatDec(B1."Base 2" + B1."Base 3");
    end;

    local procedure CalcTotalAmountsBuffer(var TempVATCtrlRptBuf: Record "VAT Control Report Buffer" temporary)
    begin
        TempVATCtrlRptBuf.Reset;
        TempVATCtrlRptBuf.SetFilter("Corrections for Bad Receivable", '%1|%2',
            TempVATCtrlRptBuf."Corrections for Bad Receivable"::" ",
            TempVATCtrlRptBuf."Corrections for Bad Receivable"::"Bad Receivable (p.46 resp. 74a)");
        TempVATCtrlRptBuf.CalcSums("Base 1", "Base 2", "Base 3");
    end;

    local procedure SkipEmptyValue(Value: Text[1024])
    begin
        if Value = '' then
            currXMLport.Skip;
    end;

    local procedure FormatDec(DecLoc: Decimal): Text
    begin
        exit(Format(DecLoc, 0, '<Sign><Integer><Decimals><Comma,.>'));
    end;

    local procedure FormatInt(IntLoc: Integer): Text
    begin
        exit(Format(IntLoc, 0, 1));
    end;

    local procedure FormatDate(DateLoc: Date): Text
    begin
        exit(Format(DateLoc, 0, '<Day,2>.<Month,2>.<Year4>'));
    end;

    local procedure FormatBool(BoolLoc: Boolean): Text
    begin
        if BoolLoc then
            exit('A');
        exit('N');
    end;

    local procedure FormatVATRegistration(VATRegistration: Text): Text
    begin
        exit(CopyStr(VATRegistration, 3));
    end;

    local procedure FormatFastAppelReaction(FastAppelReaction: Option " ",B,P): Text
    begin
        case FastAppelReaction of
            FastAppelReaction::" ":
                exit('');
            FastAppelReaction::B:
                exit('B');
            FastAppelReaction::P:
                exit('P');
        end;
    end;

    local procedure FormatDeclarationType(DeclarationType: Option Recapitulative,"Recapitulative-Corrective",Supplementary,"Supplementary-Corrective"): Text
    begin
        case DeclarationType of
            DeclarationType::Recapitulative:
                exit('B');
            DeclarationType::"Recapitulative-Corrective":
                exit('O');
            DeclarationType::Supplementary:
                exit('N');
            DeclarationType::"Supplementary-Corrective":
                exit('E');
        end;
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

    local procedure FormatCorrectionsForBadReceivable(CorrectionsForBadReceivable: Option " ","Insolvency Proceedings (p.44)","Bad Receivable (p.46 resp. 74a)"): Text[1];
    begin
        case CorrectionsForBadReceivable of
            CorrectionsForBadReceivable::" ":
                exit('N');
            CorrectionsForBadReceivable::"Insolvency Proceedings (p.44)":
                exit('A');
            CorrectionsForBadReceivable::"Bad Receivable (p.46 resp. 74a)":
                begin
                    if XmlFormat = XmlFormat::"KH 02.01.03" then
                        exit('A');
                    exit('P');
                end;
        end;
    end;

    local procedure GetCountryCodeFromVATRegistrationNo(VATRegistrationNo: Code[20]): Code[20]
    begin
        if not (CopyStr(VATRegistrationNo, 1, 1) in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) then
            exit(CopyStr(VATRegistrationNo, 1, 2));
        exit('');
    end;
}

