#if not CLEAN17
xmlport 11761 "VAT Statement"
{
    Caption = 'VAT Statement';
    Encoding = UTF8;
    ObsoleteState = Pending;
    ObsoleteReason = 'Unsupported functionality';
    ObsoleteTag = '17.0';

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
            textelement("<dphdp2>")
            {
                MaxOccurs = Once;
                MinOccurs = Zero;
                XmlName = 'DPHDP2';
                textattribute(xmlversion)
                {
                    Occurrence = Optional;
                    XmlName = 'verzePis';
                }
                textelement(VetaD)
                {
                    textattribute(formtype)
                    {
                        XmlName = 'dapdph_forma';
                    }
                    textattribute(year)
                    {
                        Occurrence = Optional;
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
                    }
                    textattribute(dph)
                    {
                        XmlName = 'k_uladis';
                    }
                    textattribute(month)
                    {
                        Occurrence = Optional;
                        XmlName = 'mesic';
                    }
                    textattribute(dp2)
                    {
                        XmlName = 'dokument';
                    }
                    textattribute(todaydate)
                    {
                        Occurrence = Optional;
                        XmlName = 'd_poddp';
                    }
                    textattribute(quarter)
                    {
                        Occurrence = Optional;
                        XmlName = 'ctvrt';
                    }
                    textattribute(taxpayerstatus)
                    {
                        Occurrence = Optional;
                        XmlName = 'typ_platce';
                    }
                    textattribute(notax)
                    {
                        Occurrence = Optional;
                        XmlName = 'trans';
                    }
                }
                textelement(VetaP)
                {
                    textattribute(authemplastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_prijmeni';
                    }
                    textattribute(natpersfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'jmeno';
                    }
                    textattribute(compemail)
                    {
                        XmlName = 'email';
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
                    textattribute(natperslastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'prijmeni';
                    }
                    textattribute(companytradenameappendix)
                    {
                        Occurrence = Optional;
                        XmlName = 'dodobchjm';
                    }
                    textattribute(compphoneno)
                    {
                        XmlName = 'c_telef';
                    }
                    textattribute(municipalityno)
                    {
                        Occurrence = Optional;
                        XmlName = 'c_orient';
                    }
                    textattribute(companytradename)
                    {
                        Occurrence = Optional;
                        XmlName = 'zkrobchjm';
                    }
                    textattribute(taxofficenumber)
                    {
                        Occurrence = Required;
                        XmlName = 'c_ufo';
                    }
                    textattribute(compregion)
                    {
                        Occurrence = Optional;
                        XmlName = 'stat';
                    }
                    textattribute(fillempfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'sest_jmeno';
                    }
                    textattribute(vatregno)
                    {
                        XmlName = 'dic';
                    }
                    textattribute(city)
                    {
                        Occurrence = Optional;
                        XmlName = 'naz_obce';
                    }
                    textattribute(postcode)
                    {
                        Occurrence = Optional;
                        XmlName = 'psc';
                    }
                    textattribute(taxpayertype)
                    {
                        Occurrence = Optional;
                        XmlName = 'typ_ds';
                    }
                    textattribute(fillemplastname)
                    {
                        Occurrence = Optional;
                        XmlName = 'sest_prijmeni';
                    }
                    textattribute(natperstitle)
                    {
                        Occurrence = Optional;
                        XmlName = 'titul';
                    }
                    textattribute(fillempphoneno)
                    {
                        Occurrence = Optional;
                        XmlName = 'sest_telef';
                    }
                    textattribute(authempjobtitle)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_postaveni';
                    }
                    textattribute(authempfirstname)
                    {
                        Occurrence = Optional;
                        XmlName = 'opr_jmeno';
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
                    textattribute(amount2)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan23';
                    }
                    textattribute(amount26)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_psl23_z';
                    }
                    textattribute(amount1)
                    {
                        Occurrence = Optional;
                        XmlName = 'obrat23';
                    }
                    textattribute(amount21)
                    {
                        Occurrence = Optional;
                        XmlName = 'dov_zb23';
                    }
                    textattribute(amount27)
                    {
                        Occurrence = Optional;
                        XmlName = 'p_sl5_z';
                    }
                    textattribute(amount24)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_dzb5';
                    }
                    textattribute(amount7)
                    {
                        Occurrence = Optional;
                        XmlName = 'p_zb5';
                    }
                    textattribute(amount8)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_pzb5';
                    }
                    textattribute(amount25)
                    {
                        Occurrence = Optional;
                        XmlName = 'p_sl23_z';
                    }
                    textattribute(amount6)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_pzb23';
                    }
                    textattribute(amount11)
                    {
                        Occurrence = Optional;
                        XmlName = 'p_sl5_e';
                    }
                    textattribute(amount5)
                    {
                        Occurrence = Optional;
                        XmlName = 'p_zb23';
                    }
                    textattribute(amount20)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_pdop_nrg';
                    }
                    textattribute(amount9)
                    {
                        Occurrence = Optional;
                        XmlName = 'p_sl23_e';
                    }
                    textattribute(amount23)
                    {
                        Occurrence = Optional;
                        XmlName = 'dov_zb5';
                    }
                    textattribute(amount28)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_psl5_z';
                    }
                    textattribute(amount3)
                    {
                        Occurrence = Optional;
                        XmlName = 'obrat5';
                    }
                    textattribute(amount22)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_dzb23';
                    }
                    textattribute(amount19)
                    {
                        Occurrence = Optional;
                        XmlName = 'p_dop_nrg';
                    }
                    textattribute(amount4)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan5';
                    }
                    textattribute(amount10)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_psl23_e';
                    }
                    textattribute(amount12)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_psl5_e';
                    }
                    textattribute(amount91)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan-zlato';
                    }
                    textattribute(amount92)
                    {
                        Occurrence = Optional;
                        XmlName = 'zlato';
                    }
                }
                textelement(Veta2)
                {
                    textattribute(amount72)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln_vyvoz';
                    }
                    textattribute(amount73)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln_ost';
                    }
                    textattribute(amount71)
                    {
                        Occurrence = Optional;
                        XmlName = 'dod_dop_nrg';
                    }
                    textattribute(amount69)
                    {
                        Occurrence = Optional;
                        XmlName = 'dod_zb';
                    }
                    textattribute(amount93)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln_sluzby';
                    }
                    textattribute(amount94)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln_zaslani';
                    }
                }
                textelement(Veta3)
                {
                    textattribute(amount89)
                    {
                        Occurrence = Optional;
                        XmlName = 'tri_pozb';
                    }
                    textattribute(amount90)
                    {
                        Occurrence = Optional;
                        XmlName = 'tri_dozb';
                    }
                }
                textelement(Veta4)
                {
                    textattribute(amount33)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_tuz5_nar';
                    }
                    textattribute(amount68)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_sum_nar';
                    }
                    textattribute(amount34)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_tuz5';
                    }
                    textattribute(amount66)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_rezim';
                    }
                    textattribute(amount67)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_sum_kr';
                    }
                    textattribute(amount29)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln23';
                    }
                    textattribute(amount65)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_rez_nar';
                    }
                    textattribute(amount30)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_tuz23_nar';
                    }
                    textattribute(amount32)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln5';
                    }
                    textattribute(amount31)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_tuz23';
                    }
                    textattribute(amount95)
                    {
                        Occurrence = Optional;
                        XmlName = 'dov_cu23';
                    }
                    textattribute(amount96)
                    {
                        Occurrence = Optional;
                        XmlName = 'dov_cu5';
                    }
                    textattribute(amount97)
                    {
                        Occurrence = Optional;
                        XmlName = 'nar_maj';
                    }
                    textattribute(amount98)
                    {
                        Occurrence = Optional;
                        XmlName = 'nar_zdp23';
                    }
                    textattribute(amount99)
                    {
                        Occurrence = Optional;
                        XmlName = 'nar_zdp5';
                    }
                    textattribute(amount100)
                    {
                        Occurrence = Optional;
                        XmlName = 'od_maj';
                    }
                    textattribute(amount101)
                    {
                        Occurrence = Optional;
                        XmlName = 'od_zdp23';
                    }
                    textattribute(amount102)
                    {
                        Occurrence = Optional;
                        XmlName = 'odkr_maj';
                    }
                    textattribute(amount103)
                    {
                        Occurrence = Optional;
                        XmlName = 'od_zdp5';
                    }
                    textattribute(amount104)
                    {
                        Occurrence = Optional;
                        XmlName = 'odkr_zdp5';
                    }
                    textattribute(amount105)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_cu23';
                    }
                    textattribute(amount106)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_cu23_nar';
                    }
                    textattribute(amount107)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_cu5';
                    }
                    textattribute(amount108)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_cu5_nar';
                    }
                }
                textelement(Veta5)
                {
                    textattribute(amount78)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_uprav_kf';
                    }
                    textattribute(amount79)
                    {
                        Occurrence = Optional;
                        XmlName = 'vypor_odp';
                    }
                    textattribute(coef1)
                    {
                        Occurrence = Optional;
                        XmlName = 'koef_p20_nov';
                    }
                    textattribute(amount77)
                    {
                        Occurrence = Optional;
                        XmlName = 'plnosv_nkf';
                    }
                    textattribute(coef2)
                    {
                        Occurrence = Optional;
                        XmlName = 'koef_p20_vypor';
                    }
                    textattribute(amount75)
                    {
                        Occurrence = Optional;
                        XmlName = 'pln_nkf';
                    }
                    textattribute(amount76)
                    {
                        Occurrence = Optional;
                        XmlName = 'plnosv_kf';
                    }
                }
                textelement(Veta6)
                {
                    textattribute(amount81)
                    {
                        Occurrence = Optional;
                        XmlName = 'vyrov_odp';
                    }
                    textattribute(amount82)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_vrac';
                    }
                    textattribute(amount88)
                    {
                        Occurrence = Optional;
                        XmlName = 'dano';
                    }
                    textattribute(amount85)
                    {
                        Occurrence = Optional;
                        XmlName = 'odp_zocelk';
                    }
                    textattribute(amount87)
                    {
                        Occurrence = Optional;
                        XmlName = 'dano_no';
                    }
                    textattribute(amount84)
                    {
                        Occurrence = Optional;
                        XmlName = 'dan_zocelk';
                    }
                    textattribute(amount86)
                    {
                        Occurrence = Optional;
                        XmlName = 'dano_da';
                    }
                    textattribute(amount80)
                    {
                        Occurrence = Optional;
                        XmlName = 'uprav_odp';
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
        MustBeGreaterErr: Label '%1 length must not be greater than %2.', Comment = '%1 = fieldcaption; %2 = length';
        WrongCoefValueErr: Label 'The value of a coefficient must be between 0 and 1.';

    [Scope('OnPrem')]
    procedure SetParameters(Month1: Integer; Quarter1: Integer; Year1: Integer; DeclarationType1: Option Recapitulative,Corrective,Supplementary; ReasonsObservedOn1: Date; FilledByEmployeeNo1: Code[20]; NoTax1: Boolean)
    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        CompanyInfo: Record "Company Information";
        CompanyOfficials: Record "Company Officials";
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        StatReportingSetup.Get();
        CompanyInfo.Get();

        SWVersion := ApplicationSystemConstants.ApplicationVersion;
        SWName := 'Microsoft Dynamics NAV';
        XMLVersion := '01.02';

        // Element 'D'
        DPH := 'DPH';
        DP2 := 'DP2';
        if Month1 <> 0 then
            Month := Format(Month1);
        if Quarter1 <> 0 then
            Quarter := Format(Quarter1);
        if Year1 <> 0 then
            Year := Format(Year1);
        case DeclarationType1 of
            DeclarationType1::Recapitulative:
                FormType := 'B';
            DeclarationType1::Corrective:
                FormType := 'O';
            DeclarationType1::Supplementary:
                FormType := 'D';
        end;
        if ReasonsObservedOn1 <> 0D then
            ReasonsObservedOn := Format(ReasonsObservedOn1, 0, '<Day,2>.<Month,2>.<Year4>');
        TodayDate := Format(Today, 0, '<Day,2>.<Month,2>.<Year4>');
        case StatReportingSetup."Tax Payer Status" of
            StatReportingSetup."Tax Payer Status"::Payer:
                TaxPayerStatus := 'P';
            StatReportingSetup."Tax Payer Status"::"Non-payer",
          StatReportingSetup."Tax Payer Status"::Other:
                TaxPayerStatus := 'I';
            StatReportingSetup."Tax Payer Status"::"VAT Group":
                TaxPayerStatus := 'S';
        end;
        CheckLen(StatReportingSetup."Main Economic Activity I Code", StatReportingSetup.FieldCaption("Main Economic Activity I Code"), 6);
        MainEcActCode1 := StatReportingSetup."Main Economic Activity I Code";
        // Element 'P'
        CheckLen(StatReportingSetup."Tax Office Number", StatReportingSetup.FieldCaption("Tax Office Number"), 3);
        TaxOfficeNumber := StatReportingSetup."Tax Office Number";
        VATRegNo := CopyStr(CompanyInfo."VAT Registration No.", 1, 2);
        if VATRegNo = 'CZ' then
            VATRegNo := CopyStr(CompanyInfo."VAT Registration No.", 3)
        else
            VATRegNo := CompanyInfo."VAT Registration No.";
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
        CompanyTradeNameAppendix := StatReportingSetup."Company Trade Name Appendix";
        City := CompanyInfo.City;
        CheckLen(StatReportingSetup.Street, StatReportingSetup.FieldCaption(Street), 38);
        Street := StatReportingSetup.Street;
        CheckLen(StatReportingSetup."House No.", StatReportingSetup.FieldCaption("House No."), 6);
        HouseNo := StatReportingSetup."House No.";
        CheckLen(StatReportingSetup."Municipality No.", StatReportingSetup.FieldCaption("Municipality No."), 4);
        MunicipalityNo := StatReportingSetup."Municipality No.";
        PostCode := DelChr(CompanyInfo."Post Code", '=', ' ');
        CheckLen(PostCode, CompanyInfo.FieldCaption("Post Code"), 5);
        CompanyOfficials.Get(StatReportingSetup."VAT Stat. Auth.Employee No.");
        AuthEmpLastName := CompanyOfficials."Last Name";
        CheckLen(CompanyOfficials."First Name", CompanyOfficials.FieldCaption("First Name"), 20);
        AuthEmpFirstName := CompanyOfficials."First Name";
        AuthEmpJobTitle := CompanyOfficials."Job Title";
        CompanyOfficials.Get(FilledByEmployeeNo1);
        FillEmpLastName := CompanyOfficials."Last Name";
        CheckLen(CompanyOfficials."First Name", CompanyOfficials.FieldCaption("First Name"), 20);
        FillEmpFirstName := CompanyOfficials."First Name";
        CheckLen(CompanyOfficials."Phone No.", CompanyOfficials.FieldCaption("Phone No."), 14);
        FillEmpPhoneNo := CompanyOfficials."Phone No.";

        if NoTax1 then
            NoTax := 'N'
        else
            NoTax := 'A';

        CompEmail := CompanyInfo."E-Mail";
        CheckLen(CompanyInfo."Phone No.", CompanyInfo.FieldCaption("Phone No."), 14);
        CompPhoneNo := CompanyInfo."Phone No.";
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
    procedure SetAttributeValue(VATStatementLine: Record "VAT Statement Line"; AttributeValue: Decimal)
    var
        VATAttributeCode: Record "VAT Attribute Code";
        TempValue: Decimal;
    begin
        VATAttributeCode.Get(VATStatementLine."Statement Template Name", VATStatementLine."Attribute Code");
        VATAttributeCode.TestField("XML Code");
        case LowerCase(VATAttributeCode."XML Code") of
            'obrat23':
                begin
                    if Evaluate(TempValue, Amount1) then;
                    Amount1 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan23':
                begin
                    if Evaluate(TempValue, Amount2) then;
                    Amount2 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'obrat5':
                begin
                    if Evaluate(TempValue, Amount3) then;
                    Amount3 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan5':
                begin
                    if Evaluate(TempValue, Amount4) then;
                    Amount4 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'p_zb23':
                begin
                    if Evaluate(TempValue, Amount5) then;
                    Amount5 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_pzb23':
                begin
                    if Evaluate(TempValue, Amount6) then;
                    Amount6 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'p_zb5':
                begin
                    if Evaluate(TempValue, Amount7) then;
                    Amount7 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_pzb5':
                begin
                    if Evaluate(TempValue, Amount8) then;
                    Amount8 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'p_sl23_e':
                begin
                    if Evaluate(TempValue, Amount9) then;
                    Amount9 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_psl23_e':
                begin
                    if Evaluate(TempValue, Amount10) then;
                    Amount10 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'p_sl5_e':
                begin
                    if Evaluate(TempValue, Amount11) then;
                    Amount11 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_psl5_e':
                begin
                    if Evaluate(TempValue, Amount12) then;
                    Amount12 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'p_dop_nrg':
                begin
                    if Evaluate(TempValue, Amount19) then;
                    Amount19 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_pdop_nrg':
                begin
                    if Evaluate(TempValue, Amount20) then;
                    Amount20 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dov_zb23':
                begin
                    if Evaluate(TempValue, Amount21) then;
                    Amount21 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_dzb23':
                begin
                    if Evaluate(TempValue, Amount22) then;
                    Amount22 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dov_zb5':
                begin
                    if Evaluate(TempValue, Amount23) then;
                    Amount23 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_dzb5':
                begin
                    if Evaluate(TempValue, Amount24) then;
                    Amount24 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'p_sl23_z':
                begin
                    if Evaluate(TempValue, Amount25) then;
                    Amount25 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_psl23_z':
                begin
                    if Evaluate(TempValue, Amount26) then;
                    Amount26 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'p_sl5_z':
                begin
                    if Evaluate(TempValue, Amount27) then;
                    Amount27 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_psl5_z':
                begin
                    if Evaluate(TempValue, Amount28) then;
                    Amount28 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'pln23':
                begin
                    if Evaluate(TempValue, Amount29) then;
                    Amount29 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_tuz23_nar':
                begin
                    if Evaluate(TempValue, Amount30) then;
                    Amount30 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_tuz23':
                begin
                    if Evaluate(TempValue, Amount31) then;
                    Amount31 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'pln5':
                begin
                    if Evaluate(TempValue, Amount32) then;
                    Amount32 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_tuz5_nar':
                begin
                    if Evaluate(TempValue, Amount33) then;
                    Amount33 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_tuz5':
                begin
                    if Evaluate(TempValue, Amount34) then;
                    Amount34 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_rez_nar':
                begin
                    if Evaluate(TempValue, Amount65) then;
                    Amount65 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_rezim':
                begin
                    if Evaluate(TempValue, Amount66) then;
                    Amount66 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_sum_kr':
                begin
                    if Evaluate(TempValue, Amount67) then;
                    Amount67 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_sum_nar':
                begin
                    if Evaluate(TempValue, Amount68) then;
                    Amount68 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dod_zb':
                begin
                    if Evaluate(TempValue, Amount69) then;
                    Amount69 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dod_dop_nrg':
                begin
                    if Evaluate(TempValue, Amount71) then;
                    Amount71 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'pln_vyvoz':
                begin
                    if Evaluate(TempValue, Amount72) then;
                    Amount72 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'pln_ost':
                begin
                    if Evaluate(TempValue, Amount73) then;
                    Amount73 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'pln_nkf':
                begin
                    if Evaluate(TempValue, Amount75) then;
                    Amount75 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'plnosv_kf':
                begin
                    if Evaluate(TempValue, Amount76) then;
                    Amount76 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'plnosv_nkf':
                begin
                    if Evaluate(TempValue, Amount77) then;
                    Amount77 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_uprav_kf':
                begin
                    if Evaluate(TempValue, Amount78) then;
                    Amount78 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'vypor_odp':
                begin
                    if Evaluate(TempValue, Amount79) then;
                    Amount79 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'uprav_odp':
                begin
                    if Evaluate(TempValue, Amount80) then;
                    Amount80 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'vyrov_odp':
                begin
                    if Evaluate(TempValue, Amount81) then;
                    Amount81 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_vrac':
                begin
                    if Evaluate(TempValue, Amount82) then;
                    Amount82 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dan_zocelk':
                begin
                    if Evaluate(TempValue, Amount84) then;
                    Amount84 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_zocelk':
                begin
                    if Evaluate(TempValue, Amount85) then;
                    Amount85 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dano_da':
                begin
                    if Evaluate(TempValue, Amount86) then;
                    Amount86 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dano_no':
                begin
                    if Evaluate(TempValue, Amount87) then;
                    Amount87 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dano':
                begin
                    if Evaluate(TempValue, Amount88) then;
                    Amount88 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'tri_pozb':
                begin
                    if Evaluate(TempValue, Amount89) then;
                    Amount89 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'tri_dozb':
                begin
                    if Evaluate(TempValue, Amount90) then;
                    Amount90 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'koef_p20_nov':
                begin
                    if (AttributeValue < 0) or (AttributeValue > 1) then
                        Error(WrongCoefValueErr);
                    Coef1 := Format(AttributeValue, 0, 9);
                end;
            'koef_p20_vypor':
                begin
                    if (AttributeValue < 0) or (AttributeValue > 1) then
                        Error(WrongCoefValueErr);
                    Coef2 := Format(AttributeValue, 0, 9);
                end;
            'dan_zlato':
                begin
                    if Evaluate(TempValue, Amount91) then;
                    Amount91 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'zlato':
                begin
                    if Evaluate(TempValue, Amount92) then;
                    Amount92 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'pln_sluzby':
                begin
                    if Evaluate(TempValue, Amount93) then;
                    Amount93 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'pln_zaslani':
                begin
                    if Evaluate(TempValue, Amount94) then;
                    Amount94 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dov_cu23':
                begin
                    if Evaluate(TempValue, Amount95) then;
                    Amount95 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'dov_cu5':
                begin
                    if Evaluate(TempValue, Amount96) then;
                    Amount96 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'nar_maj':
                begin
                    if Evaluate(TempValue, Amount97) then;
                    Amount97 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'nar_zdp23':
                begin
                    if Evaluate(TempValue, Amount98) then;
                    Amount98 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'nar_zdp5':
                begin
                    if Evaluate(TempValue, Amount99) then;
                    Amount99 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'od_maj':
                begin
                    if Evaluate(TempValue, Amount100) then;
                    Amount100 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'od_zdp23':
                begin
                    if Evaluate(TempValue, Amount101) then;
                    Amount101 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odkr_maj':
                begin
                    if Evaluate(TempValue, Amount102) then;
                    Amount102 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'od_zdp5':
                begin
                    if Evaluate(TempValue, Amount103) then;
                    Amount103 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odkr_zdp5':
                begin
                    if Evaluate(TempValue, Amount104) then;
                    Amount104 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_cu23':
                begin
                    if Evaluate(TempValue, Amount105) then;
                    Amount105 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_cu23_nar':
                begin
                    if Evaluate(TempValue, Amount106) then;
                    Amount106 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_cu5':
                begin
                    if Evaluate(TempValue, Amount107) then;
                    Amount107 := Format(TempValue + AttributeValue, 0, 1);
                end;
            'odp_cu5_nar':
                begin
                    if Evaluate(TempValue, Amount108) then;
                    Amount108 := Format(TempValue + AttributeValue, 0, 1);
                end;
        end;
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
            Error(MustBeGreaterErr, FieldCapt, MaxLen);
    end;

    local procedure SkipEmptyValue(Value: Text[1024])
    begin
        if Value = '' then
            currXMLport.Skip();
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
#endif