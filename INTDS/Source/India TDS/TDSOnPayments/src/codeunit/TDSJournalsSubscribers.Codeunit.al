codeunit 18767 "TDS Journals Subscribers"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Account No.', false, false)]
    local procedure AssignTDSSectionCodeGenJournalLine(var Rec: Record "Gen. Journal Line")
    var
        AllowedSections: Record "Allowed Sections";
    begin
        if (Rec."Document Type" IN [Rec."Document Type"::Invoice, Rec."Document Type"::Payment]) and
            (Rec."Account Type" = Rec."Account Type"::Vendor)
        then begin
            AllowedSections.Reset();
            AllowedSections.SetRange("Vendor No", Rec."Account No.");
            AllowedSections.SetRange("Default Section", true);
            if AllowedSections.FindFirst() then begin
                Rec.Validate("TDS Section Code", AllowedSections."TDS Section");
                Rec."Nature of Remittance" := AllowedSections."Nature of Remittance";
                Rec."Act Applicable" := AllowedSections."Act Applicable";
            end else begin
                Rec."TDS Section Code" := '';
                Rec."Nature of Remittance" := '';
                Rec."Act Applicable" := '';
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'TDS Section Code', false, false)]
    local procedure OnAfterValidateTDSSectionCodeGenJournalLine(var Rec: Record "Gen. Journal Line");
    var
        TDSSection: Record "TDS Section";
    begin
        if Rec."TDS Section Code" <> '' then
            if not TDSSection.Get(Rec."TDS Section Code") then
                Error(TDSSectionErr, Rec."TDS Section Code", TDSSection.TableCaption());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Work Tax Nature Of Deduction', false, false)]
    local procedure OnAfterValidateWorkTaxNatureofDeductionGenJournalLine(var Rec: Record "Gen. Journal Line")
    var
        TDSSection: Record "TDS Section";
    begin
        if Rec."Work Tax Nature Of Deduction" <> '' then
            if not TDSSection.Get(Rec."Work Tax Nature Of Deduction") then
                Error(WorkTaxNatureofDeductionErr, Rec."Work Tax Nature Of Deduction", TDSSection.TableCaption());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Tax Base Subscribers", 'OnBeforeCallingTaxEngineFromGenJnlLine', '', false, false)]
    local procedure OnBeforeCallingTaxEngineFromGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        ValidateGenJnlLine(GenJnlLine);
    end;

    local procedure ValidateGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if GenJnlLine."TDS Section Code" = '' then
            exit;
        if GenJnlLine."Applies-to ID" <> '' then begin
            VendLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            VendLedgerEntry.SetFilter("TDS Section Code", '<>%1', GenJnlLine."TDS Section Code");
            if VendLedgerEntry.FindFirst() then
                Error(SectionErr, VendLedgerEntry."Document No.", GenJnlLine."TDS Section Code");
        end;
    end;

    var
        SectionErr: Label 'Section Code on Document No. %1 should be %2', Comment = '%1 = Document No.,%2 = Section Code';
        TDSSectionErr: Label '%1 does not exist in table %2.', Comment = '%1= TDS Section Code,%2= TDS Section Table Name';
        WorkTaxNatureofDeductionErr: Label '%1 does not exist in table %2.', Comment = '%1= Work Tax Nature of Deduction,%2= TDS Section Table Name';
}