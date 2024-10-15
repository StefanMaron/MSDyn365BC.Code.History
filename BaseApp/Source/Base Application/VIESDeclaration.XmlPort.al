xmlport 31060 "VIES Declaration"
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
                tableelement(header; "VIES Declaration Header")
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
                        Dic := Header.GetVATRegNo;
                        if Header."Taxpayer Type" = Header."Taxpayer Type"::Corporation then
                            Typds := 'P'
                        else
                            Typds := 'F';

                        DPH := 'DPH';
                        SHV := 'SHV';
                        CompanyFullName := Header.Name + Header."Name 2";

                        GetOfficialData(Header."Authorized Employee No.", AuthPersLastName, AuthPersFirstName, AuthPersTitle, TempParam);
                        GetOfficialData(Header."Filled by Employee No.", FillPersLastName, FillPersFirstName, TempParam, FillPersPhone);
                        GetOfficialData(Header."Natural Employee No.", NatPersLastName, NatPersFirstName, NatPersTitle, TempParam);

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
                    textattribute(natperslastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'prijmeni';
                    }
                    textattribute(natpersfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'jmeno';
                    }
                    textattribute(natperstitle)
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
                tableelement(Line; "VIES Declaration Line")
                {
                    XmlName = 'VetaR';
                    UseTemporary = true;
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
                            CancelCode := Line.GetCancelCode;
                        SupplyCode := Line.GetTradeRole;
                        VATRegNo := Line.GetVATRegNo;
                        Amount := Format(Line."Amount (LCY)", 0, 9);
                    end;
                }
                tableelement(CallOfStockLine; "VIES Declaration Line")
                {
                    XmlName = 'VetaS';
                    UseTemporary = true;

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

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    [Scope('OnPrem')]
    procedure SetHeader(NewVIESHeader: Record "VIES Declaration Header")
    begin
        Header := NewVIESHeader;
        Header.Insert();
    end;

    [Scope('OnPrem')]
    procedure SetLines(var TempVIESLine: Record "VIES Declaration Line")
    begin
        DeleteVIESLines(Line);
        DeleteVIESLines(CallOfStockLine);

        TempVIESLine.SetFilter("Trade Type", '<>%1', TempVIESLine."Trade Type"::" ");
        Line.Copy(TempVIESLine, true);

        TempVIESLine.SetRange("Trade Type", TempVIESLine."Trade Type"::" ");
        CallOfStockLine.Copy(TempVIESLine, true);
    end;

    [Scope('OnPrem')]
    procedure GetOfficialData(CompanyOfficial: Code[20]; var OfficialsLastName: Text[30]; var OfficialsFirstName: Text[30]; var OfficialsJobTitle: Text[30]; var OfficialsPhoneNo: Text[30])
    var
        CompanyOfficials: Record "Company Officials";
    begin
        if CompanyOfficials.Get(CompanyOfficial) then begin
            OfficialsLastName := CompanyOfficials."Last Name";
            OfficialsFirstName := CompanyOfficials."First Name";
            OfficialsJobTitle := CompanyOfficials."Job Title";
            OfficialsPhoneNo := CompanyOfficials."Phone No.";
        end;
    end;

    local procedure DeleteVIESLines(var TempVIESDeclarationLine: Record "VIES Declaration Line" temporary)
    begin
        TempVIESDeclarationLine.Reset();
        TempVIESDeclarationLine.DeleteAll();
    end;
}

