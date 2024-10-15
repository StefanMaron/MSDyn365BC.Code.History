codeunit 12174 "Incl. in VAT Report Validation"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'You must specify a value for the %1 field when the %2 field is selected and the %3 field is set to %4.';
        IncludeinVATReportErrorLog: Record "Incl. in VAT Report Error Log" temporary;
        Text001: Label 'You must specify a value for the %1 field when the %2 field is not selected.';
        Text003: Label 'You must specify a value for the %1 field when the %2 field is set to %3.';
        Text005: Label 'You must specify a value for the %1 field in the document header when the %2 field is selected and the %3 field is set to %4.';
        Text006: Label 'You must specify a value for the %1 field in the document header when the %2 field is not selected.';
        Text007: Label 'You must specify a value for the %1 field in the document header when the %2 field is set to %3.';
        Text009: Label 'The %1 field can only be selected if the line is for purchase or sale, the account type is %2, and the %3 field is selected for the combination of VAT posting groups.';
        Text011: Label 'You cannot select the %1 field when the %2 field is set to %3 and the %4 field is set to %5.';
        Text013: Label 'The %1 or %2 field must be Customer or Vendor when the %3 field is set to %4 and the %5 field is set to %6.';

    [Scope('OnPrem')]
    procedure ValidateGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line"; var IncludeVATReportErrorLogParam: Record "Incl. in VAT Report Error Log" temporary)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
    begin
        if GenJournalLine."Include in VAT Transac. Rep." then begin
            // Clear Log
            IncludeinVATReportErrorLog.DeleteAll();
            // Exit if No VAT will be posted
            if not GenJournalLine.CheckincludeInVATSetup then begin
                // Temp records needed for correct formatting of "Account Type"
                TempGenJournalLine."Account Type" := TempGenJournalLine."Account Type"::"G/L Account";
                InsertError(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Include in VAT Transac. Rep."),
                  StrSubstNo(Text009, GenJournalLine.FieldCaption("Include in VAT Transac. Rep."),
                    TempGenJournalLine."Account Type", VATPostingSetup.FieldCaption("Include in VAT Transac. Rep.")), 0);
            end else begin
                CheckNRBillToPayToNoInGenJnl(GenJournalLine);
                CheckFiscalCodeInGenJnl(GenJournalLine);
                CheckNRFirstNameInGenlJnl(GenJournalLine);
                CheckNRLastNameInGenJnl(GenJournalLine);
                CheckNRDOBInGenJnl(GenJournalLine);
                CheckNRPlaceofBirthInGenJnl(GenJournalLine);
                CheckNRCountryCodeInGenJnl(GenJournalLine);
                CheckVATRegistrationNoInGenJnl(GenJournalLine);
            end;
            if IncludeinVATReportErrorLog.FindSet then
                repeat
                    IncludeVATReportErrorLogParam := IncludeinVATReportErrorLog;
                    IncludeVATReportErrorLogParam.Insert();
                until IncludeinVATReportErrorLog.Next() = 0;
        end;
    end;

    local procedure CheckFiscalCodeInGenJnl(GenJournalLine: Record "Gen. Journal Line")
    begin
        // CheckFiscalCodeInGeneralJournalLine
        if (GenJournalLine."Account Type" in [GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Account Type"::Customer,
                                              GenJournalLine."Account Type"::Vendor]) and
           GenJournalLine."Individual Person" and
           (GenJournalLine.Resident = GenJournalLine.Resident::Resident)
        then
            if GenJournalLine."Fiscal Code" = '' then
                InsertError(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Fiscal Code"),
                  StrSubstNo(Text000, GenJournalLine.FieldCaption("Fiscal Code"), GenJournalLine.FieldCaption("Individual Person"),
                    GenJournalLine.FieldCaption(Resident), GenJournalLine.Resident), 0);
    end;

    local procedure CheckNRFirstNameInGenlJnl(GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident") then
            if GenJournalLine."First Name" = '' then
                InsertError(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("First Name"),
                  StrSubstNo(Text000, GenJournalLine.FieldCaption("First Name"), GenJournalLine.FieldCaption("Individual Person"),
                    GenJournalLine.FieldCaption(Resident), GenJournalLine.Resident), 0);
    end;

    local procedure CheckNRLastNameInGenJnl(GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident") then
            if GenJournalLine."Last Name" = '' then
                InsertError(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Last Name"),
                  StrSubstNo(Text000, GenJournalLine.FieldCaption("Last Name"), GenJournalLine.FieldCaption("Individual Person"),
                    GenJournalLine.FieldCaption(Resident), GenJournalLine.Resident), 0);
    end;

    local procedure CheckNRDOBInGenJnl(GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident") then
            if GenJournalLine."Date of Birth" = 0D then
                InsertError(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Date of Birth"),
                  StrSubstNo(Text000, GenJournalLine.FieldCaption("Date of Birth"), GenJournalLine.FieldCaption("Individual Person"),
                    GenJournalLine.FieldCaption(Resident), GenJournalLine.Resident), 0);
    end;

    local procedure CheckNRPlaceofBirthInGenJnl(GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident") then
            if GenJournalLine."Place of Birth" = '' then
                InsertError(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Place of Birth"),
                  StrSubstNo(Text000, GenJournalLine.FieldCaption("Place of Birth"), GenJournalLine.FieldCaption("Individual Person"),
                    GenJournalLine.FieldCaption(Resident), GenJournalLine.Resident), 0);
    end;

    local procedure CheckNRCountryCodeInGenJnl(GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident" then
            if GenJournalLine."Country/Region Code" = '' then
                InsertError(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Country/Region Code"),
                  StrSubstNo(
                    Text003, GenJournalLine.FieldCaption("Country/Region Code"), GenJournalLine.FieldCaption(Resident), GenJournalLine.Resident),
                  0);
    end;

    local procedure CheckVATRegistrationNoInGenJnl(GenJournalLine: Record "Gen. Journal Line")
    begin
        if IsVATRegNoNeeded(
             GenJournalLine."Country/Region Code", GenJournalLine."Individual Person", GenJournalLine."Tax Representative No.") and
           (GenJournalLine."VAT Registration No." = '')
        then
            InsertError(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("VAT Registration No."),
              StrSubstNo(Text001, GenJournalLine.FieldCaption("VAT Registration No."), GenJournalLine.FieldCaption("Individual Person")), 0);
    end;

    local procedure CheckNRBillToPayToNoInGenJnl(GenJournalLine: Record "Gen. Journal Line")
    begin
        if (GenJournalLine."Bill-to/Pay-to No." = '') and
           (GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident") and not GenJournalLine."Individual Person"
        then
            InsertError(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Account Type"),
              StrSubstNo(Text013, GenJournalLine.FieldCaption("Account Type"), GenJournalLine.FieldCaption("Bal. Account Type"),
                GenJournalLine.FieldCaption(Resident), GenJournalLine.Resident, GenJournalLine.FieldCaption("Individual Person"),
                GenJournalLine."Individual Person"), 0);
    end;

    [Scope('OnPrem')]
    procedure ValidateSalesHeader(SalesHeader: Record "Sales Header"; var IncludeVATReportErrorLogParam: Record "Incl. in VAT Report Error Log" temporary)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Quantity, '<>0');
        SalesLine.SetRange("Include in VAT Transac. Rep.", true);
        if SalesLine.IsEmpty() then
            exit;

        // Clear Log
        IncludeinVATReportErrorLog.DeleteAll();
        CheckFiscalCodeInSalesHeader(SalesHeader);
        CheckNRFirstNameInSalesHeader(SalesHeader);
        CheckNRLastNameInSalesHeader(SalesHeader);
        CheckNRDOBInSalesHeader(SalesHeader);
        CheckNRPlaceofBirthInSalesHeader(SalesHeader);
        CheckNRCountryCodeInSalesHeader(SalesHeader);
        CheckVATRegistrationNoInSalesHeader(SalesHeader);

        SalesLine.FindSet();
        repeat
            CheckIncludeInVATReportInSalesLine(SalesLine);
        until SalesLine.Next() = 0;

        if IncludeinVATReportErrorLog.FindSet then
            repeat
                IncludeVATReportErrorLogParam := IncludeinVATReportErrorLog;
                IncludeVATReportErrorLogParam.Insert();
            until IncludeinVATReportErrorLog.Next() = 0;
    end;

    local procedure CheckIncludeInVATReportInSalesLine(SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.IncludeInVATTransReport(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
            InsertError(DATABASE::"Sales Line", SalesLine.FieldNo("Include in VAT Transac. Rep."),
              StrSubstNo(Text011, SalesLine.FieldCaption("Include in VAT Transac. Rep."), SalesLine.FieldCaption("VAT Bus. Posting Group"),
                SalesLine."VAT Bus. Posting Group", SalesLine.FieldCaption("VAT Prod. Posting Group"), SalesLine."VAT Prod. Posting Group"),
              SalesLine."Line No.");
    end;

    local procedure CheckFiscalCodeInSalesHeader(SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Individual Person" and (SalesHeader.Resident = SalesHeader.Resident::Resident) then
            if SalesHeader."Fiscal Code" = '' then
                InsertError(DATABASE::"Sales Header", SalesHeader.FieldNo("Fiscal Code"),
                  StrSubstNo(Text005, SalesHeader.FieldCaption("Fiscal Code"), SalesHeader.FieldCaption("Individual Person"),
                    SalesHeader.FieldCaption(Resident), SalesHeader.Resident), 0);
    end;

    local procedure CheckNRFirstNameInSalesHeader(SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Individual Person" and (SalesHeader.Resident = SalesHeader.Resident::"Non-Resident") then
            if SalesHeader."First Name" = '' then
                InsertError(DATABASE::"Sales Header", SalesHeader.FieldNo("First Name"),
                  StrSubstNo(
                    Text005, SalesHeader.FieldCaption("First Name"), SalesHeader.FieldCaption("Individual Person"),
                    SalesHeader.FieldCaption(Resident), SalesHeader.Resident), 0);
    end;

    local procedure CheckNRLastNameInSalesHeader(SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Individual Person" and (SalesHeader.Resident = SalesHeader.Resident::"Non-Resident") then
            if SalesHeader."Last Name" = '' then
                InsertError(DATABASE::"Sales Header", SalesHeader.FieldNo("Last Name"),
                  StrSubstNo(Text005, SalesHeader.FieldCaption("Last Name"), SalesHeader.FieldCaption("Individual Person"),
                    SalesHeader.FieldCaption(Resident), SalesHeader.Resident), 0);
    end;

    local procedure CheckNRDOBInSalesHeader(SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Individual Person" and (SalesHeader.Resident = SalesHeader.Resident::"Non-Resident") then
            if SalesHeader."Date of Birth" = 0D then
                InsertError(DATABASE::"Sales Header", SalesHeader.FieldNo("Date of Birth"),
                  StrSubstNo(Text005, SalesHeader.FieldCaption("Date of Birth"), SalesHeader.FieldCaption("Individual Person"),
                    SalesHeader.FieldCaption(Resident), SalesHeader.Resident), 0);
    end;

    local procedure CheckNRPlaceofBirthInSalesHeader(SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Individual Person" and (SalesHeader.Resident = SalesHeader.Resident::"Non-Resident") then
            if SalesHeader."Place of Birth" = '' then
                InsertError(DATABASE::"Sales Header", SalesHeader.FieldNo("Place of Birth"),
                  StrSubstNo(Text005, SalesHeader.FieldCaption("Place of Birth"), SalesHeader.FieldCaption("Individual Person"),
                    SalesHeader.FieldCaption(Resident), SalesHeader.Resident), 0);
    end;

    local procedure CheckNRCountryCodeInSalesHeader(SalesHeader: Record "Sales Header")
    begin
        if SalesHeader.Resident = SalesHeader.Resident::"Non-Resident" then
            if SalesHeader."Sell-to Country/Region Code" = '' then
                InsertError(DATABASE::"Sales Header", SalesHeader.FieldNo("Sell-to Country/Region Code"),
                  StrSubstNo(
                    Text007, SalesHeader.FieldCaption("Sell-to Country/Region Code"), SalesHeader.FieldCaption(Resident), SalesHeader.Resident),
                  0);
    end;

    local procedure CheckVATRegistrationNoInSalesHeader(SalesHeader: Record "Sales Header")
    begin
        if IsVATRegNoNeeded(
             SalesHeader."Sell-to Country/Region Code", SalesHeader."Individual Person", SalesHeader."Tax Representative No.") and
           (SalesHeader."VAT Registration No." = '')
        then
            InsertError(DATABASE::"Sales Header", SalesHeader.FieldNo("VAT Registration No."),
              StrSubstNo(Text006, SalesHeader.FieldCaption("VAT Registration No."), SalesHeader.FieldCaption("Individual Person")), 0);
    end;

    [Scope('OnPrem')]
    procedure ValidatePurchaseHeader(PurchaseHeader: Record "Purchase Header"; var IncludeVATReportErrorLogParam: Record "Incl. in VAT Report Error Log" temporary)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter(Quantity, '<>0');
        PurchaseLine.SetRange("Include in VAT Transac. Rep.", true);
        if PurchaseLine.IsEmpty() then
            exit;

        // Clear Log
        IncludeinVATReportErrorLog.DeleteAll();
        CheckFiscalCodeInPurchaseHeader(PurchaseHeader);
        CheckNRFirstNameInPurchaseHeader(PurchaseHeader);
        CheckNRLastNameInPurchaseHeader(PurchaseHeader);
        CheckNRDOBInPurchaseHeader(PurchaseHeader);
        CheckNRPlaceofBirthInPurchaseHeader(PurchaseHeader);
        CheckNRCountryCodeInPurchaseHeader(PurchaseHeader);
        CheckVATRegistrationNoInPurchaseHeader(PurchaseHeader);

        PurchaseLine.FindSet();
        repeat
            CheckIncludeInVATReportInPurchaseLine(PurchaseLine);
        until PurchaseLine.Next() = 0;

        if IncludeinVATReportErrorLog.FindSet then
            repeat
                IncludeVATReportErrorLogParam := IncludeinVATReportErrorLog;
                IncludeVATReportErrorLogParam.Insert();
            until IncludeinVATReportErrorLog.Next() = 0;
    end;

    local procedure CheckIncludeInVATReportInPurchaseLine(PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.IncludeInVATTransReport(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group") then
            InsertError(DATABASE::"Purchase Line", PurchaseLine.FieldNo("Include in VAT Transac. Rep."),
              StrSubstNo(
                Text011, PurchaseLine.FieldCaption("Include in VAT Transac. Rep."), PurchaseLine.FieldCaption("VAT Bus. Posting Group"),
                PurchaseLine."VAT Bus. Posting Group", PurchaseLine.FieldCaption("VAT Prod. Posting Group"),
                PurchaseLine."VAT Prod. Posting Group"), PurchaseLine."Line No.");
    end;

    local procedure CheckFiscalCodeInPurchaseHeader(PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."Individual Person" and (PurchaseHeader.Resident = PurchaseHeader.Resident::Resident) then
            if PurchaseHeader."Fiscal Code" = '' then
                InsertError(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Fiscal Code"),
                  StrSubstNo(Text005, PurchaseHeader.FieldCaption("Fiscal Code"), PurchaseHeader.FieldCaption("Individual Person"),
                    PurchaseHeader.FieldCaption(Resident), PurchaseHeader.Resident), 0);
    end;

    local procedure CheckNRFirstNameInPurchaseHeader(PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."Individual Person" and (PurchaseHeader.Resident = PurchaseHeader.Resident::"Non-Resident") then
            if PurchaseHeader."First Name" = '' then
                InsertError(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("First Name"),
                  StrSubstNo(
                    Text005, PurchaseHeader.FieldCaption("First Name"), PurchaseHeader.FieldCaption("Individual Person"),
                    PurchaseHeader.FieldCaption(Resident), PurchaseHeader.Resident), 0);
    end;

    local procedure CheckNRLastNameInPurchaseHeader(PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."Individual Person" and (PurchaseHeader.Resident = PurchaseHeader.Resident::"Non-Resident") then
            if PurchaseHeader."Last Name" = '' then
                InsertError(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Last Name"),
                  StrSubstNo(Text005, PurchaseHeader.FieldCaption("Last Name"), PurchaseHeader.FieldCaption("Individual Person"),
                    PurchaseHeader.FieldCaption(Resident), PurchaseHeader.Resident), 0);
    end;

    local procedure CheckNRDOBInPurchaseHeader(PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."Individual Person" and (PurchaseHeader.Resident = PurchaseHeader.Resident::"Non-Resident") then
            if PurchaseHeader."Date of Birth" = 0D then
                InsertError(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Date of Birth"),
                  StrSubstNo(Text005, PurchaseHeader.FieldCaption("Date of Birth"), PurchaseHeader.FieldCaption("Individual Person"),
                    PurchaseHeader.FieldCaption(Resident), PurchaseHeader.Resident), 0);
    end;

    local procedure CheckNRPlaceofBirthInPurchaseHeader(PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."Individual Person" and (PurchaseHeader.Resident = PurchaseHeader.Resident::"Non-Resident") then
            if PurchaseHeader."Birth City" = '' then
                InsertError(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Birth City"),
                  StrSubstNo(Text005, PurchaseHeader.FieldCaption("Birth City"), PurchaseHeader.FieldCaption("Individual Person"),
                    PurchaseHeader.FieldCaption(Resident), PurchaseHeader.Resident), 0);
    end;

    local procedure CheckNRCountryCodeInPurchaseHeader(PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader.Resident = PurchaseHeader.Resident::"Non-Resident" then
            if PurchaseHeader."Buy-from Country/Region Code" = '' then
                InsertError(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Country/Region Code"),
                  StrSubstNo(
                    Text007, PurchaseHeader.FieldCaption("Buy-from Country/Region Code"), PurchaseHeader.FieldCaption(Resident),
                    PurchaseHeader.Resident), 0);
    end;

    local procedure CheckVATRegistrationNoInPurchaseHeader(PurchaseHeader: Record "Purchase Header")
    begin
        if IsVATRegNoNeeded(
             PurchaseHeader."Buy-from Country/Region Code", PurchaseHeader."Individual Person", PurchaseHeader."Tax Representative No.") and
           (PurchaseHeader."VAT Registration No." = '')
        then
            InsertError(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("VAT Registration No."),
              StrSubstNo(Text006, PurchaseHeader.FieldCaption("VAT Registration No."), PurchaseHeader.FieldCaption("Individual Person")), 0);
    end;

    [Scope('OnPrem')]
    procedure ValidateServiceHeader(ServiceHeader: Record "Service Header"; var IncludeVATReportErrorLogParam: Record "Incl. in VAT Report Error Log" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Reset();
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetFilter(Quantity, '<>0');
        ServiceLine.SetRange("Include in VAT Transac. Rep.", true);
        if ServiceLine.IsEmpty() then
            exit;

        // Clear Log
        IncludeinVATReportErrorLog.DeleteAll();
        CheckFiscalCodeInServiceHeader(ServiceHeader);
        CheckNRFirstNameInServiceHeader(ServiceHeader);
        CheckNRLastNameInServiceHeader(ServiceHeader);
        CheckNRDOBInServiceHeader(ServiceHeader);
        CheckNRPlaceofBirthInServiceHeader(ServiceHeader);
        CheckNRCountryCodeInServiceHeader(ServiceHeader);
        CheckVATRegistrationNoInServiceHeader(ServiceHeader);

        ServiceLine.FindSet();
        repeat
            CheckIncludeInVATReportInServiceLine(ServiceLine);
        until ServiceLine.Next() = 0;

        if IncludeinVATReportErrorLog.FindSet then
            repeat
                IncludeVATReportErrorLogParam := IncludeinVATReportErrorLog;
                IncludeVATReportErrorLogParam.Insert();
            until IncludeinVATReportErrorLog.Next() = 0;
    end;

    local procedure CheckIncludeInVATReportInServiceLine(ServiceLine: Record "Service Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.IncludeInVATTransReport(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group") then
            InsertError(DATABASE::"Service Line", ServiceLine.FieldNo("Include in VAT Transac. Rep."),
              StrSubstNo(
                Text011, ServiceLine.FieldCaption("Include in VAT Transac. Rep."), ServiceLine.FieldCaption("VAT Bus. Posting Group"),
                ServiceLine."VAT Bus. Posting Group", ServiceLine.FieldCaption("VAT Prod. Posting Group"),
                ServiceLine."VAT Prod. Posting Group"), ServiceLine."Line No.");
    end;

    local procedure CheckFiscalCodeInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Individual Person" and (ServiceHeader.Resident = ServiceHeader.Resident::Resident) then
            if ServiceHeader."Fiscal Code" = '' then
                InsertError(DATABASE::"Service Header", ServiceHeader.FieldNo("Fiscal Code"),
                  StrSubstNo(Text005, ServiceHeader.FieldCaption("Fiscal Code"), ServiceHeader.FieldCaption("Individual Person"),
                    ServiceHeader.FieldCaption(Resident), ServiceHeader.Resident), 0);
    end;

    local procedure CheckNRFirstNameInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Individual Person" and (ServiceHeader.Resident = ServiceHeader.Resident::"Non-Resident") then
            if ServiceHeader."First Name" = '' then
                InsertError(DATABASE::"Service Header", ServiceHeader.FieldNo("First Name"),
                  StrSubstNo(
                    Text005, ServiceHeader.FieldCaption("First Name"), ServiceHeader.FieldCaption("Individual Person"),
                    ServiceHeader.FieldCaption(Resident), ServiceHeader.Resident), 0);
    end;

    local procedure CheckNRLastNameInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Individual Person" and (ServiceHeader.Resident = ServiceHeader.Resident::"Non-Resident") then
            if ServiceHeader."Last Name" = '' then
                InsertError(DATABASE::"Service Header", ServiceHeader.FieldNo("Last Name"),
                  StrSubstNo(Text005, ServiceHeader.FieldCaption("Last Name"), ServiceHeader.FieldCaption("Individual Person"),
                    ServiceHeader.FieldCaption(Resident), ServiceHeader.Resident), 0);
    end;

    local procedure CheckNRDOBInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Individual Person" and (ServiceHeader.Resident = ServiceHeader.Resident::"Non-Resident") then
            if ServiceHeader."Date of Birth" = 0D then
                InsertError(DATABASE::"Service Header", ServiceHeader.FieldNo("Date of Birth"),
                  StrSubstNo(Text005, ServiceHeader.FieldCaption("Date of Birth"), ServiceHeader.FieldCaption("Individual Person"),
                    ServiceHeader.FieldCaption(Resident), ServiceHeader.Resident), 0);
    end;

    local procedure CheckNRPlaceofBirthInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Individual Person" and (ServiceHeader.Resident = ServiceHeader.Resident::"Non-Resident") then
            if ServiceHeader."Place of Birth" = '' then
                InsertError(DATABASE::"Service Header", ServiceHeader.FieldNo("Place of Birth"),
                  StrSubstNo(Text005, ServiceHeader.FieldCaption("Place of Birth"), ServiceHeader.FieldCaption("Individual Person"),
                    ServiceHeader.FieldCaption(Resident), ServiceHeader.Resident), 0);
    end;

    local procedure CheckNRCountryCodeInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader.Resident = ServiceHeader.Resident::"Non-Resident" then
            if ServiceHeader."Country/Region Code" = '' then
                InsertError(DATABASE::"Service Header", ServiceHeader.FieldNo("Country/Region Code"),
                  StrSubstNo(
                    Text007, ServiceHeader.FieldCaption("Country/Region Code"), ServiceHeader.FieldCaption(Resident),
                    ServiceHeader.Resident), 0);
    end;

    local procedure CheckVATRegistrationNoInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if IsVATRegNoNeeded(ServiceHeader."Country/Region Code", ServiceHeader."Individual Person", ServiceHeader."Tax Representative No.") and
           (ServiceHeader."VAT Registration No." = '')
        then
            InsertError(DATABASE::"Service Header", ServiceHeader.FieldNo("VAT Registration No."),
              StrSubstNo(Text006, ServiceHeader.FieldCaption("VAT Registration No."), ServiceHeader.FieldCaption("Individual Person")), 0);
    end;

    local procedure InsertError(RecordNo: Integer; FieldNo: Integer; ErrorText: Text[250]; LineNo: Integer)
    begin
        if not IncludeinVATReportErrorLog.FindLast then;
        IncludeinVATReportErrorLog."Entry No." += 1;
        IncludeinVATReportErrorLog."Record No." := RecordNo;
        IncludeinVATReportErrorLog."Field No." := FieldNo;
        IncludeinVATReportErrorLog."Error Message" := ErrorText;
        IncludeinVATReportErrorLog."Line No." := LineNo;
        IncludeinVATReportErrorLog.Insert();
    end;

    [Scope('OnPrem')]
    procedure IsVATRegNoNeeded(CountryCode: Code[10]; IndividualPerson: Boolean; TaxRepresentativeNo: Code[20]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryCode) and IndividualPerson then
            exit(false);
        if CountryRegion.CheckNotEUCountry(CountryCode) then
            if (not IndividualPerson) and (TaxRepresentativeNo = '') then
                exit(true);
        exit(false);
    end;
}

