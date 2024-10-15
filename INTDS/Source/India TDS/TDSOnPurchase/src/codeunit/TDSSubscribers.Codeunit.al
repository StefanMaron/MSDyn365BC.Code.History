codeunit 18716 "TDS Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'No.', false, false)]
    local procedure AssignTDSSectionCodePurchaseLine(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line")
    var
        AllowedSections: Record "Allowed Sections";
    begin
        if Rec."Document Type" IN [Rec."Document Type"::Order, Rec."Document Type"::Invoice] then begin
            AllowedSections.Reset();
            AllowedSections.SetRange("Vendor No", Rec."Buy-from Vendor No.");
            AllowedSections.SetRange("Default Section", true);
            if not AllowedSections.IsEmpty then begin
                Rec.Validate("TDS Section Code", AllowedSections."TDS Section");
                Rec.Validate("Nature of Remittance", AllowedSections."Nature of Remittance");
                Rec.Validate("Act Applicable", AllowedSections."Act Applicable");
            end else begin
                Rec."TDS Section Code" := '';
                Rec."Nature of Remittance" := '';
                Rec."Act Applicable" := '';
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostVendorEntry', '', false, false)]
    local procedure InsertTDSSectionCodeGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        Location: Record Location;
        CompanyInfo: Record "Company Information";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindFirst() then
            GenJnlLine."TDS Section Code" := PurchLine."TDS Section Code";
        if GenJnlLine."Location Code" <> '' then begin
            Location.GET(GenJnlLine."Location Code");
            IF Location."T.A.N. No." <> '' then
                GenJnlLine."T.A.N. No." := Location."T.A.N. No."
        end else begin
            CompanyInfo.GET();
            GenJnlLine."T.A.N. No." := CompanyInfo."T.A.N. No.";
        end
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure CheckTANNo(var PurchaseHeader: Record "Purchase Header")
    var
        CompanyInfo: Record "Company Information";
        Location: Record Location;
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.SetFilter("TDS Section Code", '<>%1', '');
        if PurchLine.IsEmpty then
            exit;
        CompanyInfo.GET();
        CompanyInfo.TestField("T.A.N. No.");
        if PurchaseHeader."Location Code" <> '' then begin
            Location.Get(PurchaseHeader."Location Code");
            if Location."T.A.N. No." = '' then
                Location.TestField("T.A.N. No.");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", 'OnAfterCopyVendLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure InsertTDSSectionCodeinVendLedgerEntry(GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry."TDS Section Code" := GenJournalLine."TDS Section Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Calc.Discount", 'OnAfterCalcPurchaseDiscount', '', false, false)]
    local procedure OnAfterCalcPurchaseDiscount(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        CalculateTax: Codeunit "Calculate Tax";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                CalculateTax.CallTaxEngineOnPurchaseLine(PurchaseLine, PurchaseLine);
            until PurchaseLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Get Receipt", 'OnAfterInsertLines', '', false, false)]
    local procedure OnAfterInsertReceiptLines(var PurchHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        CalculateTax: Codeunit "Calculate Tax";
    begin
        PurchaseLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                CalculateTax.CallTaxEngineOnPurchaseLine(PurchaseLine, PurchaseLine);
            until PurchaseLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'TDS Section Code', false, false)]
    local procedure CheckPANDetails(var Rec: Record "Purchase Line")
    var
        Vendor: Record Vendor;
        PANNoErr: Label 'Vendor P.A.N. is invalid.';
    begin
        if Rec."TDS Section Code" = '' then
            exit;

        if not Vendor.Get(Rec."Pay-to Vendor No.") then
            exit;
        if (Vendor."P.A.N. Status" = Vendor."P.A.N. Status"::" ") and (Vendor."P.A.N. No." <> '') then
            if StrLen(Vendor."P.A.N. No.") <> 10 then
                Error(PANNoErr);

        if (Vendor."P.A.N. No." = '') and (Vendor."P.A.N. Status" = Vendor."P.A.N. Status"::" ") then
            Error(PANNoErr);

        if (Vendor."P.A.N. Status" <> Vendor."P.A.N. Status"::" ") and (Vendor."P.A.N. Reference No." = '') then
            Error(PANNoErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'TDS Section Code', false, false)]
    local procedure CheckPANDetailsOnGenJnlLine(var Rec: Record "Gen. Journal Line")
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        VedPANNoErr: Label 'Vendor P.A.N. is invalid.';
        CustPANNoErr: Label 'Customer P.A.N. is invalid.';
    begin
        if Rec."TDS Section Code" = '' then
            exit;
        if Rec."Account Type" = Rec."Account Type"::Vendor then begin
            Vendor.Get(Rec."Account No.");
            if (Vendor."P.A.N. Status" = Vendor."P.A.N. Status"::" ") and (Vendor."P.A.N. No." <> '') then
                if StrLen(Vendor."P.A.N. No.") <> 10 then
                    Error(VedPANNoErr);

            if (Vendor."P.A.N. No." = '') and (Vendor."P.A.N. Status" = Vendor."P.A.N. Status"::" ") then
                Error(VedPANNoErr);

            if (Vendor."P.A.N. Status" <> Vendor."P.A.N. Status"::" ") and (Vendor."P.A.N. Reference No." = '') then
                Error(VedPANNoErr);
        end else
            if Rec."Account Type" = Rec."Account Type"::Customer then begin
                Customer.Get(Rec."Account No.");
                if (Customer."P.A.N. Status" = Customer."P.A.N. Status"::" ") and (Customer."P.A.N. No." <> '') then
                    if StrLen(Customer."P.A.N. No.") <> 10 then
                        Error(CustPANNoErr);

                if (Customer."P.A.N. No." = '') and (Customer."P.A.N. Status" = Customer."P.A.N. Status"::" ") then
                    Error(CustPANNoErr);

                if (Customer."P.A.N. Status" <> Customer."P.A.N. Status"::" ") and (Customer."P.A.N. Reference No." = '') then
                    Error(CustPANNoErr);
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Tax Base Subscribers", 'OnBeforeCallingTaxEngineFromPurchLine', '', false, false)]
    local procedure OnBeforeCallingTaxEngineFromPurchLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        ValidatePurchLine(PurchaseHeader, PurchaseLine);
    end;

    local procedure ValidatePurchLine(PurchaseHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line")
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if PurchLine."TDS Section Code" = '' then
            exit;
        if PurchaseHeader."Applies-to Doc. No." <> '' then begin
            VendLedgerEntry.SetRange("Document Type", PurchaseHeader."Applies-to Doc. Type");
            VendLedgerEntry.SetRange("Document No.", PurchaseHeader."Applies-to Doc. No.");
            if VendLedgerEntry.FindFirst() then
                VendLedgerEntry.testfield("TDS Section Code", PurchLine."TDS Section Code");
        end;
    end;

    procedure GetStatiticsAmount(PurchaseHeader: Record "Purchase Header"; var TotalTaxAmount: Decimal; var TDSAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        TDSValidations: Codeunit "TDS Validations";
        RecordIDList: List of [RecordID];
        i: Integer;
    begin
        Clear(TotalTaxAmount);
        Clear(TDSAmount);

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document no.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                RecordIDList.Add(PurchaseLine.RecordId());
                TotalTaxAmount += PurchaseLine.Amount;
            until PurchaseLine.Next() = 0;

        for i := 1 to RecordIDList.Count() do
            TDSAmount += GetTDSAmount(RecordIDList.Get(i));

        TDSAmount := TDSValidations.RoundTDSAmount(TDSAmount);
        TotalTaxAmount := TotalTaxAmount - TDSAmount;
    end;

    procedure GetStatiticsPostedAmount(PurchInvHeader: Record "Purch. Inv. Header"; var TotalTaxAmount: Decimal; var TDSAmount: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        TDSValidations: Codeunit "TDS Validations";
        RecordIDList: List of [RecordID];
        i: Integer;
    begin
        Clear(TotalTaxAmount);
        Clear(TDSAmount);

        PurchInvLine.SetRange("Document no.", PurchInvHeader."No.");
        if PurchInvLine.FindSet() then
            repeat
                RecordIDList.Add(PurchInvLine.RecordId());
                TotalTaxAmount += PurchInvLine.Amount;
            until PurchInvLine.Next() = 0;

        for i := 1 to RecordIDList.Count() do
            TDSAmount += GetTDSAmount(RecordIDList.Get(i));

        TDSAmount := TDSValidations.RoundTDSAmount(TDSAmount);
        TotalTaxAmount := TotalTaxAmount - TDSAmount;
    end;

    local procedure GetTDSAmount(RecID: RecordId): Decimal
    var
        TaxTransactionValue: Record "Tax Transaction Value";
        TDSSetup: Record "TDS Setup";
    begin
        if not TDSSetup.Get() then
            exit;

        TaxTransactionValue.SetRange("Tax Record ID", RecID);
        TaxTransactionValue.SetRange("Value Type", TaxTransactionValue."Value Type"::COMPONENT);
        TaxTransactionValue.SetRange("Tax Type", TDSSetup."Tax Type");
        TaxTransactionValue.SetFilter(Percent, '<>%1', 0);
        if not TaxTransactionValue.IsEmpty() then
            TaxTransactionValue.CalcSums(Amount);
        exit(TaxTransactionValue.Amount);
    end;
}