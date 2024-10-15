xmlport 11763 "Reverse Charge Export"
{
    Caption = 'Reverse Charge Export';
    Direction = Export;
    Encoding = UTF8;

    schema
    {
        textelement(Pisemnost)
        {
            textelement(DPHEVD)
            {
                MaxOccurs = Once;
                MinOccurs = Zero;
                tableelement(reversechargehdr; "Reverse Charge Header")
                {
                    MaxOccurs = Once;
                    MinOccurs = Once;
                    RequestFilterFields = "No.";
                    XmlName = 'VetaD';
                    SourceTableView = SORTING("No.");
                    textattribute(k_uladis)
                    {
                    }
                    textattribute(mesic)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(dokument)
                    {
                    }
                    textattribute(ctvrt)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(rok)
                    {
                    }
                    textattribute(d_poddp)
                    {
                    }
                    textattribute(typ_vypisu)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(zdobd_do)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(zdobd_od)
                    {
                        Occurrence = Optional;
                    }

                    trigger OnAfterGetRecord()
                    var
                        CompanyOfficials: Record "Company Officials";
                        Employee: Record Employee;
                    begin
                        k_uladis := 'DPH';
                        dokument := 'EVD';

                        with ReverseChargeHdr do begin
                            case "Statement Type" of
                                "Statement Type"::Vendor:
                                    typ_vypisu := 'D';
                                "Statement Type"::Customer:
                                    typ_vypisu := 'O';
                            end;

                            case "Declaration Period" of
                                "Declaration Period"::Month:
                                    mesic := Format("Period No.");
                                "Declaration Period"::Quarter:
                                    ctvrt := Format("Period No.");
                            end;

                            rok := Format(Year);
                            c_ufo := "Tax Office No.";
                            c_pracufo := "Tax Office Region No.";
                            dic := GetVATRegNo;

                            if CompanyOfficials.Get("Authorized Employee No.") then begin
                                opr_prijmeni := CompanyOfficials."Last Name";
                                opr_jmeno := CompanyOfficials."First Name";
                                opr_postaveni := CompanyOfficials."Job Title";
                            end;

                            if CompanyOfficials.Get("Filled by Employee No.") then begin
                                sest_prijmeni := CompanyOfficials."Last Name";
                                sest_jmeno := CompanyOfficials."First Name";
                                sest_telef := CompanyOfficials."Phone No.";
                            end;

                            if Employee.Get("Natural Employee No.") then begin
                                prijmeni := Employee."Last Name";
                                jmeno := Employee."First Name";
                                titul := Employee.Title;
                            end;

                            zkrobchjm := Name;
                            naz_obce := City;
                            ulice := Street;
                            c_pop := "House No.";
                            c_orient := "Municipality No.";
                            psc := DelChr("Post Code");
                            d_poddp := Format(Today, 0, '<Day,2>.<Month,2>.<Year4>');
                            stat := "Country/Region Name";
                            zdobd_od := Format("Part Period From", 0, '<Day,2>.<Month,2>.<Year4>');
                            zdobd_do := Format("Part Period To", 0, '<Day,2>.<Month,2>.<Year4>');
                        end;

                        c_telef := CoInfo."Phone No.";
                        email := CoInfo."E-Mail";

                        case StatReportingSetup."Taxpayer Type" of
                            StatReportingSetup."Taxpayer Type"::Corporation:
                                typ_ds := 'P';
                            StatReportingSetup."Taxpayer Type"::Individual:
                                typ_ds := 'F';
                        end;

                        zast_kod := StatReportingSetup."Official Code";
                        zast_typ := FormatCompanyType(StatReportingSetup."Official Type");
                        zast_nazev := StatReportingSetup."Official Name";
                        zast_jmeno := StatReportingSetup."Official First Name";
                        zast_prijmeni := StatReportingSetup."Official Surname";
                        zast_dat_nar := FormatDate(StatReportingSetup."Official Birth Date");
                        zast_ev_cislo := StatReportingSetup."Official Reg.No.of Tax Adviser";
                        zast_ic := StatReportingSetup."Official Registration No.";
                    end;
                }
                textelement(VetaP)
                {
                    textattribute(c_ufo)
                    {
                    }
                    textattribute(c_pracufo)
                    {
                    }
                    textattribute(dic)
                    {
                    }
                    textattribute(typ_ds)
                    {
                    }
                    textattribute(prijmeni)
                    {
                    }
                    textattribute(jmeno)
                    {
                    }
                    textattribute(titul)
                    {
                    }
                    textattribute(zkrobchjm)
                    {
                    }
                    textattribute(naz_obce)
                    {
                    }
                    textattribute(ulice)
                    {
                    }
                    textattribute(c_pop)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(c_orient)
                    {
                    }
                    textattribute(psc)
                    {
                    }
                    textattribute(opr_prijmeni)
                    {
                    }
                    textattribute(opr_jmeno)
                    {
                    }
                    textattribute(opr_postaveni)
                    {
                    }
                    textattribute(sest_prijmeni)
                    {
                    }
                    textattribute(sest_jmeno)
                    {
                    }
                    textattribute(sest_telef)
                    {
                    }
                    textattribute(zast_dat_nar)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(zast_ev_cislo)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(zast_ic)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(zast_jmeno)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(zast_kod)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(zast_nazev)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(zast_prijmeni)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(zast_typ)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(stat)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(c_telef)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(email)
                    {
                        Occurrence = Optional;
                    }
                }
                tableelement(reversechargeln; "Reverse Charge Line")
                {
                    LinkFields = "Reverse Charge No." = FIELD("No.");
                    LinkTable = ReverseChargeHdr;
                    XmlName = 'VetaE';
                    SourceTableView = SORTING("Reverse Charge No.", "Line No.");
                    textattribute(c_radku)
                    {
                    }
                    textattribute(d_uskut_pl)
                    {
                    }
                    textattribute(dic_dod)
                    {
                    }
                    textattribute(kod_pred_pl)
                    {
                    }
                    textattribute(roz_pl)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(roz_pl_j)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(zakl_dane)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        TariffNumber: Record "Tariff Number";
                        UnitOfMeasure: Record "Unit of Measure";
                    begin
                        with ReverseChargeLn do begin
                            LineNo := LineNo + 1;
                            c_radku := Format(LineNo);
                            d_uskut_pl := Format("VAT Date", 0, '<Day,2>.<Month,2>.<Year4>');

                            if Quantity <> 0 then
                                roz_pl := Format(Round(Quantity, 1), 0, '<Sign><Integer>')
                            else
                                roz_pl := '';

                            if ReverseChargeLn."Document Tariff No." <> '' then
                                TariffNumber.Get("Document Tariff No.")
                            else
                                TariffNumber.Init;

                            if TariffNumber."Allow Empty Unit of Meas.Code" then begin
                                UnitOfMeasure.Init;
                                roz_pl := '';
                            end else begin
                                TestField("Unit of Measure Code");
                                UnitOfMeasure.Get("Unit of Measure Code");
                            end;

                            roz_pl_j := UnitOfMeasure.Description;
                            dic_dod := GetVATRegNo;
                            zakl_dane := ConvertStr(Format(RoundAmt("VAT Base Amount (LCY)", 1, '='), 0, '<Sign><Integer><Decimals>'), ',', '.');
                            kod_pred_pl := "Commodity Code";
                        end;
                    end;
                }
                tableelement(attachments; Integer)
                {
                    MinOccurs = Zero;
                    XmlName = 'VetaR';
                    SourceTableView = SORTING(Number);
                    textattribute(kod_sekce)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(poradi)
                    {
                        Occurrence = Optional;
                    }
                    textattribute(t_prilohy)
                    {
                        Occurrence = Optional;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        case AttachType of
                            AttachType::Default:
                                kod_sekce := 'O';
                            AttachType::Supplementary:
                                kod_sekce := 'D';
                        end;

                        poradi := Format(Attachments.Number);
                        t_prilohy := TextAttachArray[Attachments.Number];
                    end;

                    trigger OnPreXmlItem()
                    begin
                        if AttachType = AttachType::" " then
                            currXMLport.Break;

                        Attachments.SetRange(Number, 1, AttachLineCount);
                    end;
                }
            }
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Attachments)
                {
                    Caption = 'Attachments';
                    field(AttachType; AttachType)
                    {
                        Caption = 'Type';
                        OptionCaption = ' ,Default,Supplementary';
                    }
                    field(TextAttach; TextAttach)
                    {
                        Caption = 'Text';
                        Editable = EditableTextAttachments;
                        MultiLine = true;
                    }
                }
            }
        }

        actions
        {
        }
    }

    trigger OnPreXmlPort()
    begin
        StatReportingSetup.Get;
        CoInfo.Get;
    end;

    var
        StatReportingSetup: Record "Stat. Reporting Setup";
        CoInfo: Record "Company Information";
        TextAttach: Text;
        TextAttachArray: array[100] of Text[72];
        AttachType: Option " ",Default,Supplementary;
        AttachLineCount: Integer;
        LineNo: Integer;
        [InDataSet]
        EditableTextAttachments: Boolean;

    local procedure RoundAmt(Amt: Decimal; Precision: Decimal; Type: Code[10]): Decimal
    begin
        exit(Round(Amt, Precision, Type));
    end;

    local procedure ValidateTextAttachments()
    var
        TempTextAttach: Text;
    begin
        Clear(TextAttachArray);
        AttachLineCount := 0;
        TempTextAttach := TextAttach;
        while StrLen(TempTextAttach) > 0 do begin
            AttachLineCount += 1;
            TextAttachArray[AttachLineCount] := CopyStr(TempTextAttach, 1, MaxStrLen(TextAttachArray[AttachLineCount]));
            if StrLen(TempTextAttach) > MaxStrLen(TextAttachArray[AttachLineCount]) then
                TempTextAttach := CopyStr(TempTextAttach, MaxStrLen(TextAttachArray[AttachLineCount]) + 1)
            else
                TempTextAttach := '';
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

    local procedure FormatDate(Date: Date): Text
    begin
        exit(Format(Date, 0, '<Day,2>.<Month,2>.<Year4>'));
    end;
}

