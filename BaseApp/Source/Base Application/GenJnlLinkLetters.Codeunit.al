codeunit 31033 "Gen. Jnl.-Link Letters"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        GenJnlLine.Copy(Rec);
        GenJnlLine.TestField(Prepayment, true);
        GenJnlLine.TestField(Amount);

        with GenJnlLine do begin
            if "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor] then begin
                TestField("Document Type", "Document Type"::Payment);
                TestField(Prepayment);
                TestField("Prepayment Type", "Prepayment Type"::Advance);
                case "Account Type" of
                    "Account Type"::Customer:
                        if Amount > 0 then
                            FieldError(Amount, Text008Err);
                    "Account Type"::Vendor:
                        if Amount < 0 then
                            FieldError(Amount, Text007Err);
                end;
                if "Advance Letter Link Code" = '' then
                    "Advance Letter Link Code" := "Document No." + ' ' + Format("Line No.");
                SetAdvanceLink.SetGenJnlLine(GenJnlLine);
                SetAdvanceLink.LookupMode(true);
                OK := SetAdvanceLink.RunModal = ACTION::LookupOK;
                OK := SetAdvanceLink.GetOK;
                if OK then
                    SetAdvanceLink.SetPostingGroupToGenJnlLine(GenJnlLine);
                Clear(SetAdvanceLink);
                if not OK then
                    exit;
            end else
                Error(
                  Text005Err,
                  FieldCaption("Account Type"), FieldCaption("Bal. Account Type"));
        end;

        Rec := GenJnlLine;
        if "Journal Template Name" <> '' then
            Modify;
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        SetAdvanceLink: Page "Set Advance Link";
        OK: Boolean;
        Text005Err: Label 'The %1 or %2 must be Customer or Vendor.', Comment = '%1=account type caption;%2=balance account type caption';
        Text007Err: Label 'must be positive';
        Text008Err: Label 'must be negative';
}

