codeunit 12132 "Withholding Tax Export"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        SigningCompanyOfficials: Record "Company Officials";
        TempErrorMessage: Record "Error Message" temporary;
        FlatFileManagement: Codeunit "Flat File Management";
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN,VP;
        ConstRecordType: Option A,B,C,D,E,G,H,Z;
        FileNameLbl: Label 'Withholding Taxes %1.dcm', Comment = '%1 = Year';
        NothingToReportMsg: Label 'There were no Withholding Tax entries for the year %1.', Comment = '%1 = Year';
        NoSigningCompanyOfficialErr: Label 'You need to specify a Signing Company Official.';
        VendorMustHaveFiscalCodeOrVatRegNoErr: Label 'Vendor with No. = %1 must have a value in either %2 or %3.', Comment = '%1 = Vendor No., %2 = Fiscal Code, %3 = VAT Reg. No.';
        CompanyMustHaveFiscalCodeOrVatRegNoErr: Label 'Company Information must have a value in either %1 or %2.', Comment = '%1 = Fiscal Code, %2 = VAT Reg. No.';
        ReportPreparedBy: Option Company,"Tax Representative";
        CommunicationNumber: Integer;
        ReplaceFieldValueToMaxAllowedQst: Label 'The witholding tax amount (field AU001019): %1, is greater than the maximum allowed value taxable base (field AU001018): %2. \\Do you want to replace the witholding tax amount with the maximum allowed?', Comment = '%1=witholding tax amount, a decimal value, %2=taxable base, a decimal value.';
        BaseExcludedAmountTotalErr: Label 'Base - Excluded Amount total on lines for Withholding Tax Entry No. = %1 must be equal to Base - Excluded Amount on the Withholding Tax card for that entry (%2).', Comment = '%1=Entry number,%2=Amount.';

    [Scope('OnPrem')]
    procedure Export(Year: Integer; SigningCompanyOfficialNo: Code[20]; PreparedBy: Option Company,"Tax Representative"; NrOfCommunication: Integer)
    var
        TempWithholdingTax: Record "Withholding Tax" temporary;
        TempWithholdingTaxPrevYears: Record "Withholding Tax" temporary;
        TempContributions: Record Contributions temporary;
    begin
        CompanyInformation.Get();
        ReportPreparedBy := PreparedBy;
        CommunicationNumber := NrOfCommunication;

        if not SigningCompanyOfficials.Get(SigningCompanyOfficialNo) then
            Error(NoSigningCompanyOfficialErr);

        CalculateWithholdingTaxPerVendor(TempWithholdingTax, TempContributions, Year, Year);

        if TempWithholdingTax.IsEmpty then begin
            Message(NothingToReportMsg, Year);
            exit;
        end;

        CalculateWithholdingTaxPerVendor(TempWithholdingTaxPrevYears, TempContributions, 0, Year - 1);

        FlatFileManagement.Initialize;
        FlatFileManagement.SetEstimatedNumberOfRecords(TempWithholdingTax.Count);

        StartNewFileWithHeader; // Creates record A and B
        CreateFileBody(TempWithholdingTax, TempWithholdingTaxPrevYears, TempContributions, Year); // Creates record D and H

        EndFile;

        if not TempErrorMessage.HasErrors(true) then
            FlatFileManagement.DownloadFile(StrSubstNo(FileNameLbl, Year));
        TempErrorMessage.ShowErrorMessages(false);
    end;

    [Scope('OnPrem')]
    procedure SetServerFileName(FileName: Text)
    begin
        FlatFileManagement.SetServerFileName(FileName);
    end;

    local procedure CalculateWithholdingTaxPerVendor(var TempWithholdingTax: Record "Withholding Tax" temporary; var TempContributions: Record Contributions temporary; ReportingYearStart: Integer; ReportingYearEnd: Integer)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        with WithholdingTax do begin
            SetCurrentKey("Vendor No.", Reason);
            SetRange(Year, ReportingYearStart, ReportingYearEnd);
            if FindSet() then begin
                repeat
                    if not LinesExistForEntryNo("Entry No.") then begin
                        if ReportingYearStart <> 0 then
                            TempErrorMessage.LogIfEmpty(WithholdingTax, FieldNo(Reason), TempErrorMessage."Message Type"::Error);
                        if ("Vendor No." <> TempWithholdingTax."Vendor No.") or
                           (Reason <> TempWithholdingTax.Reason) or
                           ("Non-Taxable Income Type" <> TempWithholdingTax."Non-Taxable Income Type")
                        then begin
                            if TempWithholdingTax."Entry No." <> 0 then
                                TempWithholdingTax.Insert();
                            InitTempWithholdingTax(TempWithholdingTax, WithholdingTax);
                        end;
                        if "Related Date" <> 0D then
                            TempWithholdingTax."Related Date" := "Related Date";
                        TempWithholdingTax."Total Amount" += "Total Amount";
                        TempWithholdingTax."Non Taxable Amount By Treaty" += "Non Taxable Amount By Treaty";
                        TempWithholdingTax."Base - Excluded Amount" += "Base - Excluded Amount";
                        TempWithholdingTax."Non Taxable Amount" += "Non Taxable Amount";
                        TempWithholdingTax."Taxable Base" += "Taxable Base";
                        TempWithholdingTax."Withholding Tax Amount" += "Withholding Tax Amount";
                        CalculateContributions(WithholdingTax, TempWithholdingTax."Entry No.", TempContributions);
                    end;
                until Next = 0;
                if TempWithholdingTax."Entry No." <> 0 then
                    TempWithholdingTax.Insert();
            end;
        end;

        AddWithholdingTaxWithSeparateLines(TempWithholdingTax, TempContributions, ReportingYearStart, ReportingYearEnd);
    end;

    local procedure AddWithholdingTaxWithSeparateLines(var TempWithholdingTax: Record "Withholding Tax" temporary; var TempContributions: Record Contributions temporary; ReportingYearStart: Integer; ReportingYearEnd: Integer)
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxLine: Record "Withholding Tax Line";
        IsFirstLine: Boolean;
    begin
        with WithholdingTax do begin
            SetCurrentKey("Vendor No.", Reason);
            SetRange(Year, ReportingYearStart, ReportingYearEnd);
            SetRange("Non-Taxable Income Type", "Non-Taxable Income Type"::" ");
            if FindSet() then
                repeat
                    if LinesExistForEntryNo("Entry No.") then begin
                        if WithholdingTaxLine.GetAmountForEntryNo("Entry No.") <> "Base - Excluded Amount" then
                            TempErrorMessage.LogMessage(WithholdingTax, FieldNo("Base - Excluded Amount"),
                              TempErrorMessage."Message Type"::Error, StrSubstNo(BaseExcludedAmountTotalErr, "Entry No.", "Base - Excluded Amount"));
                        WithholdingTaxLine.SetRange("Withholding Tax Entry No.", "Entry No.");
                        WithholdingTaxLine.FindSet();
                        IsFirstLine := true;
                        repeat
                            CopyTaxToTempRespectingLine(TempWithholdingTax, IsFirstLine, WithholdingTax, WithholdingTaxLine);
                            CalculateContributions(WithholdingTax, TempWithholdingTax."Entry No.", TempContributions);
                        until WithholdingTaxLine.Next() = 0;
                    end;
                until Next() = 0;
        end;
    end;

    local procedure CalculateContributions(var WithholdingTax: Record "Withholding Tax"; EntryNo: Integer; var TempContributions: Record Contributions temporary)
    var
        Contributions: Record Contributions;
    begin
        with Contributions do begin
            SetRange("External Document No.", WithholdingTax."External Document No.");
            if not TempContributions.Get(EntryNo) then begin
                TempContributions.Init();
                TempContributions."Entry No." := EntryNo;
                TempContributions.Insert();
            end;

            if FindSet then
                repeat
                    TempContributions."Company Amount" += "Company Amount";
                    TempContributions."Free-Lance Amount" += "Free-Lance Amount";
                until Next = 0;
            TempContributions.Modify();
        end;
    end;

    local procedure CreateFileBody(var TempWithholdingTax: Record "Withholding Tax" temporary; var TempWithholdingTaxPrevYears: Record "Withholding Tax" temporary; var TempContributions: Record Contributions temporary; Year: Integer)
    var
        EntryNumber: Integer;
    begin
        EntryNumber := 0;
        if TempWithholdingTax.FindSet then
            repeat
                TempContributions.Get(TempWithholdingTax."Entry No.");
                FindWithholdingTaxEntry(TempWithholdingTaxPrevYears, TempWithholdingTax."Vendor No.", TempWithholdingTax.Reason);
                EntryNumber += 1;
                CreateRecordD(TempWithholdingTax, EntryNumber);
                CreateRecordH(TempWithholdingTax, TempWithholdingTaxPrevYears, TempContributions, Year);
            until TempWithholdingTax.Next = 0;
    end;

    local procedure CreateRecordA()
    var
        VendorTaxRepresentative: Record Vendor;
        TaxCode: Code[20];
    begin
        StartNewRecord(ConstRecordType::A);

        FlatFileManagement.WritePositionalValue(16, 5, ConstFormat::NU, 'CUR21', false); // A-3

        if VendorTaxRepresentative.Get(CompanyInformation."Tax Representative No.") then begin
            FlatFileManagement.WritePositionalValue(21, 2, ConstFormat::NU, '10', false); // A-4
            TaxCode := VendorTaxRepresentative.GetTaxCode;
            if TaxCode <> '' then
                FlatFileManagement.WritePositionalValue(23, 16, ConstFormat::AN, TaxCode, false) // A-5
            else
                TempErrorMessage.LogMessage(
                  VendorTaxRepresentative, VendorTaxRepresentative.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(
                    VendorMustHaveFiscalCodeOrVatRegNoErr, VendorTaxRepresentative."No.",
                    VendorTaxRepresentative.FieldCaption("Fiscal Code"),
                    VendorTaxRepresentative.FieldCaption("VAT Registration No.")));
        end else begin
            FlatFileManagement.WritePositionalValue(21, 2, ConstFormat::NU, '01', false); // A-4
            TaxCode := CompanyInformation.GetTaxCode;
            if TaxCode <> '' then
                FlatFileManagement.WritePositionalValue(23, 16, ConstFormat::AN, TaxCode, false) // A-5
            else
                TempErrorMessage.LogMessage(
                  CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                    CompanyInformation.FieldCaption("VAT Registration No.")));
        end;
    end;

    local procedure CreateRecordB()
    var
        VendorTaxRepresentative: Record Vendor;
        VATReportSetup: Record "VAT Report Setup";
        TaxCode: Code[20];
    begin
        StartNewRecord(ConstRecordType::B);

        TaxCode := CompanyInformation.GetTaxCode;
        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(2, 16, ConstFormat::AN, TaxCode, false) // B-2
        else
            TempErrorMessage.LogMessage(
              CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                CompanyInformation.FieldCaption("VAT Registration No.")));

        FlatFileManagement.WritePositionalValue(18, 8, ConstFormat::NU, '1', false); // B-3
        FlatFileManagement.WritePositionalValue(74, 16, ConstFormat::AN, '08106710158', false); // B-8
        FlatFileManagement.WritePositionalValue(91, 1, ConstFormat::CB, '0', false); // B-10
        FlatFileManagement.WritePositionalValue(92, 1, ConstFormat::CB, '0', false); // B-11

        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(Name), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(137, 60, ConstFormat::AN, CompanyInformation.Name, false); // B-14
        FlatFileManagement.WritePositionalValue(197, 100, ConstFormat::AN, CompanyInformation."E-Mail", false); // B-15
        if CompanyInformation."Phone No." = '' then
            FlatFileManagement.WritePositionalValue(297, 12, ConstFormat::AN, '000000000000', true) // B-16
        else
            FlatFileManagement.WritePositionalValue(
              297, 12, ConstFormat::AN, FlatFileManagement.CleanPhoneNumber(CompanyInformation."Phone No."), true); // B-16
        FlatFileManagement.WritePositionalValue(309, 2, ConstFormat::NP, '1', false); // B-17

        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(311, 16, ConstFormat::CF, SigningCompanyOfficials."Fiscal Code", false); // B-18
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Appointment Code"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(327, 2, ConstFormat::NU, SigningCompanyOfficials."Appointment Code", false); // B-19
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("Last Name"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(329, 24, ConstFormat::AN, SigningCompanyOfficials."Last Name", false); // B-20
        TempErrorMessage.LogIfEmpty(
          SigningCompanyOfficials, SigningCompanyOfficials.FieldNo("First Name"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WritePositionalValue(353, 20, ConstFormat::AN, SigningCompanyOfficials."First Name", false); // B-21

        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(373, 11, ConstFormat::CN, TaxCode, false); // B-22

        FlatFileManagement.WritePositionalValue(384, 18, ConstFormat::AN, '000000000000000000', false); // B-23
        FlatFileManagement.WritePositionalValue(402, 8, ConstFormat::NU, Format(CommunicationNumber), false); // B-24
        FlatFileManagement.WritePositionalValue(410, 1, ConstFormat::CB, '0', false); // B-25
        FlatFileManagement.WritePositionalValue(411, 1, ConstFormat::CB, '1', false); // B-26

        if VendorTaxRepresentative.Get(CompanyInformation."Tax Representative No.") then begin
            TaxCode := VendorTaxRepresentative.GetTaxCode;
            if TaxCode <> '' then
                FlatFileManagement.WritePositionalValue(412, 16, ConstFormat::CF, TaxCode, false) // B-27
            else
                TempErrorMessage.LogMessage(
                  VendorTaxRepresentative, VendorTaxRepresentative.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(
                    VendorMustHaveFiscalCodeOrVatRegNoErr, VendorTaxRepresentative."No.",
                    VendorTaxRepresentative.FieldCaption("Fiscal Code"),
                    VendorTaxRepresentative.FieldCaption("VAT Registration No.")));

            if ReportPreparedBy = ReportPreparedBy::Company then
                FlatFileManagement.WritePositionalValue(428, 1, ConstFormat::NU, '1', false) // B-28
            else
                FlatFileManagement.WritePositionalValue(428, 1, ConstFormat::NU, '2', false); // B-28 // Prepared by Tax Representative
            VATReportSetup.Get();
            TempErrorMessage.LogIfEmpty(VATReportSetup, VATReportSetup.FieldNo("Intermediary Date"), TempErrorMessage."Message Type"::Error);
            FlatFileManagement.WritePositionalValue(
              429, 8, ConstFormat::DT, FlatFileManagement.FormatDate(VATReportSetup."Intermediary Date", ConstFormat::DT), false); // B-29
            FlatFileManagement.WritePositionalValue(437, 1, ConstFormat::CB, '1', false); // B-30
        end else begin
            FlatFileManagement.WritePositionalValue(428, 1, ConstFormat::NU, '0', false); // B-28
            FlatFileManagement.WritePositionalValue(429, 8, ConstFormat::NU, '00000000', false); // B-29
            FlatFileManagement.WritePositionalValue(437, 1, ConstFormat::CB, '0', false); // B-30
        end;
    end;

    local procedure CreateRecordD(var TempWithholdingTax: Record "Withholding Tax" temporary; EntryNumber: Integer)
    var
        VendorWithholdingTax: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
        CompanyTaxCode: Code[20];
        VendorTaxCode: Code[20];
    begin
        VendorWithholdingTax.Get(TempWithholdingTax."Vendor No.");

        StartNewRecord(ConstRecordType::D);

        CompanyTaxCode := CompanyInformation.GetTaxCode;
        if CompanyTaxCode <> '' then
            FlatFileManagement.WritePositionalValue(2, 16, ConstFormat::AN, CompanyTaxCode, false) // D-2
        else
            TempErrorMessage.LogMessage(
              CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                CompanyInformation.FieldCaption("VAT Registration No.")));

        WritePositionalValueAmount(18, 8, ConstFormat::NU, FlatFileManagement.GetFileCount, false); // D-3

        VendorTaxCode := VendorWithholdingTax.GetTaxCode;
        if VendorTaxCode <> '' then
            FlatFileManagement.WritePositionalValue(26, 16, ConstFormat::AN, VendorTaxCode, false) // D-4
        else
            TempErrorMessage.LogMessage(
              VendorWithholdingTax, VendorWithholdingTax.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(
                VendorMustHaveFiscalCodeOrVatRegNoErr, VendorWithholdingTax."No.", VendorWithholdingTax.FieldCaption("Fiscal Code"),
                VendorWithholdingTax.FieldCaption("VAT Registration No.")));

        WritePositionalValueAmount(42, 5, ConstFormat::NU, EntryNumber, false); // D-5
        FlatFileManagement.WritePositionalValue(47, 17, ConstFormat::NU, '', false); // D-6
        FlatFileManagement.WritePositionalValue(64, 6, ConstFormat::NU, '', false); // D-7
        FlatFileManagement.WritePositionalValue(84, 1, ConstFormat::AN, '', false); // D-9
        if TempWithholdingTax.Count = 1 then
            FlatFileManagement.WritePositionalValue(89, 1, ConstFormat::CB, '0', false) // D-11
        else
            FlatFileManagement.WritePositionalValue(89, 1, ConstFormat::CB, '1', false); // D-11

        if CompanyTaxCode <> '' then
            FlatFileManagement.WriteBlockValue('DA001001', ConstFormat::CF, CompanyTaxCode)
        else
            TempErrorMessage.LogMessage(
              CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                CompanyInformation.FieldCaption("VAT Registration No.")));

        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(Name), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WriteBlockValue('DA001002', ConstFormat::AN, CompanyInformation.Name);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(City), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WriteBlockValue('DA001004', ConstFormat::AN, CompanyInformation.City);
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(County), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WriteBlockValue('DA001005', ConstFormat::PR, CompanyInformation.County);
        FlatFileManagement.WriteBlockValue('DA001006', ConstFormat::AN, CompanyInformation."Post Code");
        FlatFileManagement.WriteBlockValue('DA001007', ConstFormat::AN, CompanyInformation.Address);
        FlatFileManagement.WriteBlockValue(
          'DA001008', ConstFormat::AN, FlatFileManagement.CleanPhoneNumber(CompanyInformation."Phone No."));
        FlatFileManagement.WriteBlockValue('DA001009', ConstFormat::AN, CompanyInformation."E-Mail");
        GeneralLedgerSetup.GetRecordOnce();
        if GeneralLedgerSetup."Use Activity Code" then begin
            TempErrorMessage.LogIfEmpty(
              CompanyInformation, CompanyInformation.FieldNo("Activity Code"), TempErrorMessage."Message Type"::Error);
            FlatFileManagement.WriteBlockValue('DA001010', ConstFormat::AN, CompanyInformation."Activity Code");
        end;
        TempErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("Office Code"), TempErrorMessage."Message Type"::Error);
        FlatFileManagement.WriteBlockValue('DA001011', ConstFormat::AN, CompanyInformation."Office Code");

        if VendorWithholdingTax."Fiscal Code" <> '' then
            FlatFileManagement.WriteBlockValue('DA002001', ConstFormat::CF, VendorWithholdingTax."Contribution Fiscal Code")
        else
            if VendorWithholdingTax."VAT Registration No." <> '' then
                FlatFileManagement.WriteBlockValue('DA002001', ConstFormat::CF, VendorWithholdingTax."VAT Registration No.")
            else
                TempErrorMessage.LogMessage(
                  VendorWithholdingTax, VendorWithholdingTax.FieldNo("Contribution Fiscal Code"), TempErrorMessage."Message Type"::Error,
                  StrSubstNo(
                    VendorMustHaveFiscalCodeOrVatRegNoErr, VendorWithholdingTax."No.",
                    VendorWithholdingTax.FieldCaption("Contribution Fiscal Code"),
                    VendorWithholdingTax.FieldCaption("VAT Registration No.")));

        if VendorWithholdingTax."Individual Person" then begin
            TempErrorMessage.LogIfEmpty(
              VendorWithholdingTax, VendorWithholdingTax.FieldNo("Last Name"), TempErrorMessage."Message Type"::Warning);
            FlatFileManagement.WriteBlockValue('DA002002', ConstFormat::AN, VendorWithholdingTax."Last Name");
        end else begin
            TempErrorMessage.LogIfEmpty(
              VendorWithholdingTax, VendorWithholdingTax.FieldNo(Name), TempErrorMessage."Message Type"::Warning);
            FlatFileManagement.WriteBlockValue('DA002002', ConstFormat::AN, VendorWithholdingTax.Name);
        end;
        if VendorWithholdingTax."Individual Person" then
            TempErrorMessage.LogIfEmpty(
              VendorWithholdingTax, VendorWithholdingTax.FieldNo("First Name"), TempErrorMessage."Message Type"::Warning);
        FlatFileManagement.WriteBlockValue('DA002003', ConstFormat::AN, VendorWithholdingTax."First Name");
        if VendorWithholdingTax.Gender = VendorWithholdingTax.Gender::Male then
            FlatFileManagement.WriteBlockValue('DA002004', ConstFormat::AN, 'M')
        else
            FlatFileManagement.WriteBlockValue('DA002004', ConstFormat::AN, 'F');
        FlatFileManagement.WriteBlockValue(
          'DA002005', ConstFormat::DT, FlatFileManagement.FormatDate(VendorWithholdingTax."Date of Birth", ConstFormat::DT));
        FlatFileManagement.WriteBlockValue('DA002006', ConstFormat::AN, VendorWithholdingTax."Birth City");
        FlatFileManagement.WriteBlockValue('DA002007', ConstFormat::PN, VendorWithholdingTax."Birth County");
        if VendorWithholdingTax."Special Category" <> VendorWithholdingTax."Special Category"::" " then
            FlatFileManagement.WriteBlockValue('DA002008', ConstFormat::AN, Format(VendorWithholdingTax."Special Category"));
        FlatFileManagement.WriteBlockValue('DA002010', ConstFormat::NU, '0');

        FlatFileManagement.WriteBlockValue('DA002030', ConstFormat::AN, '');

        FlatFileManagement.WriteBlockValue('DA003001', ConstFormat::DT, FlatFileManagement.FormatDate(Today, ConstFormat::DT));
        FlatFileManagement.WriteBlockValue('DA003002', ConstFormat::CB, '1');
    end;

    local procedure CreateRecordH(var TempWithholdingTax: Record "Withholding Tax" temporary; var TempWithholdingTaxPrevYears: Record "Withholding Tax" temporary; var TempContributions: Record Contributions temporary; Year: Integer)
    var
        VendorWithholdingTax: Record Vendor;
        TaxCode: Code[20];
    begin
        VendorWithholdingTax.Get(TempWithholdingTax."Vendor No.");
        StartNewRecord(ConstRecordType::H);

        TaxCode := CompanyInformation.GetTaxCode;
        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(2, 16, ConstFormat::AN, TaxCode, false) // H-2
        else
            TempErrorMessage.LogMessage(
              CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(CompanyMustHaveFiscalCodeOrVatRegNoErr, CompanyInformation.FieldCaption("Fiscal Code"),
                CompanyInformation.FieldCaption("VAT Registration No.")));

        WritePositionalValueAmount(18, 8, ConstFormat::NU, FlatFileManagement.GetFileCount, false); // H-3

        TaxCode := VendorWithholdingTax.GetTaxCode;
        if TaxCode <> '' then
            FlatFileManagement.WritePositionalValue(26, 16, ConstFormat::AN, TaxCode, false) // H-4
        else
            TempErrorMessage.LogMessage(
              VendorWithholdingTax, VendorWithholdingTax.FieldNo("Fiscal Code"), TempErrorMessage."Message Type"::Error,
              StrSubstNo(
                VendorMustHaveFiscalCodeOrVatRegNoErr, VendorWithholdingTax."No.", VendorWithholdingTax.FieldCaption("Fiscal Code"),
                VendorWithholdingTax.FieldCaption("VAT Registration No.")));

        WritePositionalValueAmount(42, 5, ConstFormat::NU, FlatFileManagement.GetRecordCount(ConstRecordType::D), false); // H-5
        FlatFileManagement.WritePositionalValue(47, 17, ConstFormat::NU, '', false); // H-6
        FlatFileManagement.WritePositionalValue(64, 6, ConstFormat::NU, '', false); // H-7
        FlatFileManagement.WritePositionalValue(89, 1, ConstFormat::NU, '', false); // H-11

        FlatFileManagement.WriteBlockValue('AU001001', ConstFormat::AN, Format(TempWithholdingTax.Reason));
        if TempWithholdingTax.Reason in [TempWithholdingTax.Reason::G, TempWithholdingTax.Reason::H, TempWithholdingTax.Reason::I] then
            FlatFileManagement.WriteBlockValue('AU001002', ConstFormat::DA, Format(TempWithholdingTax.Year - 1));
        WriteBlockValueAmount('AU001004', ConstFormat::VP, TempWithholdingTax."Total Amount");
        if VendorWithholdingTax.Resident <> VendorWithholdingTax.Resident::"Non-Resident" then
            WriteBlockValueAmount('AU001005', ConstFormat::VP, TempWithholdingTax."Non Taxable Amount By Treaty");
        if TempWithholdingTax."Non Taxable Amount By Treaty" + TempWithholdingTax."Base - Excluded Amount" <> 0 then
            if TempWithholdingTax."Non-Taxable Income Type" = TempWithholdingTax."Non-Taxable Income Type"::" " then
                TempErrorMessage.LogIfEmpty(
                  TempWithholdingTax, TempWithholdingTax.FieldNo("Non-Taxable Income Type"), TempErrorMessage."Message Type"::Error)
            else
                FlatFileManagement.WriteBlockValue('AU001006', ConstFormat::NP, Format(TempWithholdingTax."Non-Taxable Income Type"));
        WriteBlockValueAmount('AU001007', ConstFormat::VP,
          TempWithholdingTax."Non Taxable Amount" + TempWithholdingTax."Base - Excluded Amount");
        WriteBlockValueAmount('AU001008', ConstFormat::VP, TempWithholdingTax."Taxable Base");
        WriteBlockValueAmount('AU001009', ConstFormat::VP, TempWithholdingTax."Withholding Tax Amount");
        WriteBlockValueAmount('AU001010', ConstFormat::VP, 0);

        WriteBlocksAU001018AndAU001019(TempWithholdingTaxPrevYears, Year);

        WriteBlockValueAmount('AU001020', ConstFormat::VP, TempContributions."Company Amount");
        WriteBlockValueAmount('AU001021', ConstFormat::VP, TempContributions."Free-Lance Amount");
    end;

    local procedure CreateRecordZ()
    var
        Index: Integer;
        Pos: Integer;
        Len: Integer;
    begin
        StartNewRecord(ConstRecordType::Z);
        Pos := 16;
        Len := 9;
        for Index := ConstRecordType::B to ConstRecordType::H do
            if Index in [ConstRecordType::B, ConstRecordType::C, ConstRecordType::D, ConstRecordType::G, ConstRecordType::H] then begin
                FlatFileManagement.WritePositionalValue(Pos, Len, ConstFormat::NU, Format(FlatFileManagement.GetRecordCount(Index), 0, 1), false);
                Pos += Len;
            end;
    end;

    local procedure EndFile()
    begin
        CreateRecordZ;
        FlatFileManagement.EndFile;
    end;

    local procedure FindWithholdingTaxEntry(var TempWithholdingTax: Record "Withholding Tax" temporary; VendorNo: Code[20]; Reason: Option)
    begin
        TempWithholdingTax.SetRange("Vendor No.", VendorNo);
        TempWithholdingTax.SetRange(Reason, Reason);
        if not TempWithholdingTax.FindFirst then
            Clear(TempWithholdingTax);
    end;

    local procedure InitTempWithholdingTax(var TempWithholdingTax: Record "Withholding Tax" temporary; WithholdingTax: Record "Withholding Tax")
    begin
        with WithholdingTax do begin
            TempWithholdingTax.Init();
            TempWithholdingTax."Entry No." := "Entry No.";
            TempWithholdingTax."Vendor No." := "Vendor No.";
            TempWithholdingTax.Reason := Reason;
            TempWithholdingTax.Year := Year;
            TempWithholdingTax."Non-Taxable Income Type" := "Non-Taxable Income Type";
        end;
    end;

    local procedure StartNewRecord(Type: Option A,B,C,D,E,G,H,Z)
    begin
        if FlatFileManagement.RecordsPerFileExceeded(Type) then begin
            EndFile;
            StartNewFileWithHeader;
        end;
        FlatFileManagement.StartNewRecord(Type);
    end;

    local procedure StartNewFileWithHeader()
    begin
        FlatFileManagement.StartNewFile;
        CreateRecordA;
        CreateRecordB;
    end;

    local procedure WriteBlockValueAmount("Code": Code[8]; ValueFormat: Option; DecimalValue: Decimal)
    var
        TextValue: Text;
    begin
        if DecimalValue = 0 then
            exit;

        TextValue := FlatFileManagement.FormatNum(DecimalValue, ValueFormat);
        FlatFileManagement.WriteBlockValue(Code, ValueFormat, TextValue);
    end;

    local procedure WritePositionalValueAmount(Position: Integer; Length: Integer; ValueFormat: Option; DecimalValue: Decimal; Truncate: Boolean)
    var
        TextValue: Text;
    begin
        TextValue := FlatFileManagement.FormatNum(DecimalValue, ValueFormat);
        FlatFileManagement.WritePositionalValue(Position, Length, ValueFormat, TextValue, Truncate);
    end;

    [Scope('OnPrem')]
    procedure WriteBlocksAU001018AndAU001019(TempWithholdingTaxPrevYears: Record "Withholding Tax" temporary; Year: Integer)
    begin
        if TempWithholdingTaxPrevYears."Related Date" = 0D then
            exit;

        if Date2DMY(TempWithholdingTaxPrevYears."Related Date", 3) <> Year then
            exit;

        WriteBlockValueAmount('AU001018', ConstFormat::VP, TempWithholdingTaxPrevYears."Taxable Base");
        // There's a tolerance of max 2 on the max witholding tax amount
        if TempWithholdingTaxPrevYears."Withholding Tax Amount" > TempWithholdingTaxPrevYears."Taxable Base" + 1 then
            if Confirm(ReplaceFieldValueToMaxAllowedQst, true,
                 TempWithholdingTaxPrevYears."Taxable Base",
                 TempWithholdingTaxPrevYears."Withholding Tax Amount")
            then
                WriteBlockValueAmount('AU001019', ConstFormat::VP, TempWithholdingTaxPrevYears."Taxable Base")
            else
                WriteBlockValueAmount('AU001019', ConstFormat::VP, TempWithholdingTaxPrevYears."Withholding Tax Amount");
    end;

    local procedure LinesExistForEntryNo(EntryNo: Integer): Boolean
    var
        WithholdingTaxLine: Record "Withholding Tax Line";
    begin
        WithholdingTaxLine.SetRange("Withholding Tax Entry No.", EntryNo);
        exit(not WithholdingTaxLine.IsEmpty());
    end;

    local procedure CopyTaxToTempRespectingLine(var TempWithholdingTax: Record "Withholding Tax" temporary; var IsFirstLine: Boolean; WithholdingTax: Record "Withholding Tax"; WithholdingTaxLine: Record "Withholding Tax Line")
    var
        EntryNo: Integer;
    begin
        if TempWithholdingTax.FindLast() then;
        EntryNo := TempWithholdingTax."Entry No." + 1;
        with WithholdingTax do begin
            TempWithholdingTax.Init();
            TempWithholdingTax."Entry No." := EntryNo;
            TempWithholdingTax."Vendor No." := "Vendor No.";
            TempWithholdingTax.Reason := Reason;
            TempWithholdingTax.Year := Year;
            TempWithholdingTax."Related Date" := "Related Date";
            if IsFirstLine then begin
                TempWithholdingTax."Total Amount" := "Total Amount";
                TempWithholdingTax."Non Taxable Amount By Treaty" := "Non Taxable Amount By Treaty";
                TempWithholdingTax."Non Taxable Amount" := "Non Taxable Amount";
                TempWithholdingTax."Taxable Base" := "Taxable Base";
                TempWithholdingTax."Withholding Tax Amount" := "Withholding Tax Amount";
                IsFirstLine := false;
            end;
            TempWithholdingTax."Non-Taxable Income Type" := WithholdingTaxLine."Non-Taxable Income Type";
            TempWithholdingTax."Base - Excluded Amount" := WithholdingTaxLine."Base - Excluded Amount";
            TempWithholdingTax.Insert();
        end;
    end;
}

