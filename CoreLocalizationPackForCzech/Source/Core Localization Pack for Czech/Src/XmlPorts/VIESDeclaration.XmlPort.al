xmlport 31061 "VIES Declaration CZL"
{
    Caption = 'VIES Declaration';
    Encoding = UTF8;

    schema
    {
        textelement(Pisemnost)
        {
            textelement("<dphshv>")
            {
                MaxOccurs = Once;
                MinOccurs = Zero;
                XmlName = 'DPHSHV';
                tableelement(header; "VIES Declaration Header CZL")
                {
                    XmlName = 'VetaD';
                    UseTemporary = true;
                    textattribute(dph)
                    {
                        XmlName = 'k_uladis';
                    }
                    textattribute(shv)
                    {
                        XmlName = 'dokument';
                    }
                    textattribute(month)
                    {
                        Occurrence = Optional;
                        XmlName = 'mesic';
                    }
                    textattribute(quarter)
                    {
                        Occurrence = Optional;
                        XmlName = 'ctvrt';
                    }
                    fieldattribute(rok; Header.Year)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(formtype)
                    {
                        Occurrence = Optional;
                        XmlName = 'shvies_forma';
                    }
                    textattribute(documentdate)
                    {
                        Occurrence = Optional;
                        XmlName = 'd_poddp';
                    }
                    fieldattribute(poc_radku; Header."Number of Lines")
                    {
                        Occurrence = Optional;
                    }
                    trigger OnAfterGetRecord()
                    var
                        TempParam: Text[30];
                    begin
                        if Header."Declaration Period" = Header."Declaration Period"::Month then
                            Month := Format(Header."Period No.")
                        else
                            Quarter := Format(Header."Period No.");

                        if Header."Declaration Type" = Header."Declaration Type"::Normal then
                            FormType := 'R'
                        else
                            FormType := 'N';

                        DocumentDate := Format(Header."Document Date", 0, '<Day,2>.<Month,2>.<Year4>');
                        Dic := Header.GetVATRegNo();
                        if Header."Company Type" = Header."Company Type"::Corporate then
                            Typds := 'P'
                        else
                            Typds := 'F';

                        DPH := 'DPH';
                        SHV := 'SHV';
                        CompanyFullName := Header.Name + Header."Name 2";

                        GetOfficialData(Header."Authorized Employee No.", AuthPersLastName, AuthPersFirstName, AuthPersTitle, TempParam);
                        GetOfficialData(Header."Filled by Employee No.", FillPersLastName, FillPersFirstName, TempParam, FillPersPhone);
                        GetOfficialData(Header."Individual Employee No.", indperslastname, indpersfirstname, indperstitle, TempParam);

                        TaxOfficeNumber := Header."Tax Office Number";
                        if Header."Tax Office Region Number" <> '' then
                            TaxOfficeRegionNumber := Header."Tax Office Region Number";
                        CompanyTradeNameAppendix := Header."Company Trade Name Appendix";
                        City := Header.City;
                        Street := Header.Street;
                        HouseNo := Header."House No.";
                        MunicipalityNo := Header."Municipality No.";
                        PostCode := DelChr(Header."Post Code", '=', ' ');
                    end;
                }
                textelement(VetaP)
                {
                    textattribute(taxofficenumber)
                    {
                        XmlName = 'c_ufo';
                    }
                    textattribute(taxofficeregionnumber)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_pracufo';
                    }
                    textattribute(dic)
                    {
                        Occurrence = Optional;
                        XmlName = 'dic';
                    }
                    textattribute(typds)
                    {
                        Occurrence = Optional;
                        XmlName = 'typ_ds';
                    }
                    textattribute(indperslastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'prijmeni';
                    }
                    textattribute(indpersfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'jmeno';
                    }
                    textattribute(indperstitle)
                    {
                        Occurrence = Optional;
                        XmlName = 'titul';
                    }
                    textattribute(companyfullname)
                    {
                        Occurrence = Optional;
                        XmlName = 'zkrobchjm';
                    }
                    textattribute(companytradenameappendix)
                    {
                        Occurrence = Optional;
                        XmlName = 'dodobchjm';
                    }
                    textattribute(city)
                    {
                        Occurrence = Optional;
                        XmlName = 'naz_obce';
                    }
                    textattribute(street)
                    {
                        Occurrence = Optional;
                        XmlName = 'ulice';
                    }
                    textattribute(houseno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_pop';
                    }
                    textattribute(municipalityno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_orient';
                    }
                    textattribute(postcode)
                    {
                        Occurrence = Optional;
                        XmlName = 'psc';
                    }
                    textattribute(authperslastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_prijmeni';
                    }
                    textattribute(authpersfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_jmeno';
                    }
                    textattribute(authperstitle)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_postaveni';
                    }
                    textattribute(fillperslastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'sest_prijmeni';
                    }
                    textattribute(fillpersfirstname)
                    {
                        XmlName = 'sest_jmeno';
                    }
                    textattribute(fillpersphone)
                    {
                        XmlName = 'sest_telef';
                    }
                }
                tableelement(Line; "VIES Declaration Line CZL")
                {
                    XmlName = 'VetaR';
                    UseTemporary = true;
                    MinOccurs = Zero;
                    textattribute(cancelcode)
                    {
                        Occurrence = Optional;
                        XmlName = 'k_storno';
                    }
                    fieldattribute(k_stat; Line."Country/Region Code")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(c_rad; Line."Report Line Number")
                    {
                    }
                    fieldattribute(por_c_stran; Line."Report Page Number")
                    {
                    }
                    textattribute(vatregno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_vat';
                    }
                    textattribute(supplycode)
                    {
                        Occurrence = Optional;
                        XmlName = 'k_pln_eu';
                    }
                    fieldattribute(pln_pocet; Line."Number of Supplies")
                    {
                        Occurrence = Optional;
                    }
                    textattribute(amount)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln_hodnota';
                    }
                    trigger OnAfterGetRecord()
                    begin
                        if FormType = 'N' then
                            CancelCode := Line.GetCancelCode();
                        SupplyCode := Line.GetTradeRole();
                        VATRegNo := Line.GetVATRegNo();
                        Amount := Format(Line."Amount (LCY)", 0, 9);
                    end;
                }
                tableelement(CallOfStockLine; "VIES Declaration Line CZL")
                {
                    XmlName = 'VetaS';
                    UseTemporary = true;
                    MinOccurs = Zero;
                    fieldattribute(coslineno; CallOfStockLine."Report Line Number")
                    {
                        Occurrence = Optional;
                        XmlName = 'c_rad';
                    }
                    textattribute(cosvatregno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_vat';
                    }
                    textattribute(cosorigvatregno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_vat_puv';
                    }
                    textattribute(cosrecordcode)
                    {
                        Occurrence = Optional;
                        XmlName = 'k_cos';
                    }
                    fieldattribute(k_stat; CallOfStockLine."Country/Region Code")
                    {
                        Occurrence = Optional;
                        XmlName = 'k_stat';
                    }
                    trigger OnAfterGetRecord()
                    begin
                        cosvatregno := CallOfStockLine.GetVATRegNo();
                        cosorigvatregno := CallOfStockLine.GetOrigCustVATRegNo();
                        cosrecordcode := Format(CallOfStockLine."Record Code");
                    end;
                }
            }
        }
    }
    procedure SetHeader(NewVIESHeaderCZL: Record "VIES Declaration Header CZL")
    begin
        Header := NewVIESHeaderCZL;
        Header.Insert();
    end;

    procedure SetLines(var TempVIESLineCZL: Record "VIES Declaration Line CZL")
    begin
        DeleteVIESLines(Line);
        TempVIESLineCZL.SetFilter("Trade Type", '<>%1', TempVIESLineCZL."Trade Type"::" ");
        Line.Copy(TempVIESLineCZL, true);

        DeleteVIESLines(CallOfStockLine);
        TempVIESLineCZL.SetRange("Trade Type", TempVIESLineCZL."Trade Type"::" ");
        CallOfStockLine.Copy(TempVIESLineCZL, true);
    end;

    procedure GetOfficialData(CompanyOfficialCode: Code[20]; var OfficialLastName: Text[30]; var OfficialFirstName: Text[30]; var OfficialJobTitle: Text[30]; var OfficialPhoneNo: Text[30])
    var
        CompanyOfficialCZL: Record "Company Official CZL";
    begin
        if not CompanyOfficialCZL.Get(CompanyOfficialCode) then
            Clear(CompanyOfficialCZL);
        OfficialLastName := CompanyOfficialCZL."Last Name";
        OfficialFirstName := CompanyOfficialCZL."First Name";
        OfficialJobTitle := CompanyOfficialCZL."Job Title";
        OfficialPhoneNo := CompanyOfficialCZL."Phone No.";
    end;

    local procedure DeleteVIESLines(var TempVIESDeclarationLineCZL: Record "VIES Declaration Line CZL" temporary)
    begin
        TempVIESDeclarationLineCZL.Reset();
        TempVIESDeclarationLineCZL.DeleteAll();
    end;
}
