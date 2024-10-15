codeunit 18870 "TCS Adjustment"
{
    var
        LastTCSJnlLine: Record "TCS Journal Line";
        OpenFromBatch: Boolean;
        JournalLbl: Label '%1 journal', Comment = '%1=Journal';
        DefaultLbl: Label 'DEFAULT';
        DefaultJnlLbl: Label 'Default Journal';
        TCSTemplateNameLbl: Label 'TCS Adjustment';

    procedure TCSTemplateSelection(FormID: Integer; var TCSJnlLine: Record "TCS Journal Line"; var JnlSelected: Boolean)
    var
        TCSJnlTemplate: Record "TCS Journal Template";
    begin
        JnlSelected := True;
        TCSJnlTemplate.DeleteAll();
        TCSJnlTemplate.Reset();
        if not OpenFromBatch then
            TCSJnlTemplate.SetRange("Form ID", FormID);

        Case TCSJnlTemplate.Count() of
            0:
                begin
                    TCSJnlTemplate.Init();
                    TCSJnlTemplate.Name := CopyStr(TCSTemplateNameLbl, 1, MaxStrLen(TCSJnlTemplate.Name));
                    TCSJnlTemplate.Description := STRSUBSTNO(JournalLbl, TCSTemplateNameLbl);
                    TCSJnlTemplate."Form ID" := Page::"TCS Adjustment Journal";
                    TCSJnlTemplate.Insert();
                    Commit();
                end;
            1:
                TCSJnlTemplate.FindFirst();
            else
                JnlSelected := Page.RunModal(0, TCSJnlTemplate) = Action::LookupOK;
        end;
        if JnlSelected then begin
            TCSJnlLine.FilterGroup := 2;
            TCSJnlLine.SetRange("Journal Template Name", TCSJnlTemplate.Name);
            TCSJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                TCSJnlLine."Journal Template Name" := '';
                Page.Run(TCSJnlTemplate."Form ID", TCSJnlLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromTCSBatch(var TCSJnlBatch: Record "TCS Journal Batch")
    var
        TCSJnlLine: Record "TCS Journal Line";
        JnlSelected: Boolean;
    begin
        OpenFromBatch := True;
        TCSJnlLine."Journal Batch Name" := TCSJnlBatch.Name;
        TCSTemplateSelection(0, TCSJnlLine, JnlSelected);
    end;

    procedure OpenTCSJnl(var CurrentTCSJnlBatchName: Code[10]; var TCSJnlLine: Record "TCS Journal Line")
    begin
        CheckTCSTemplateName(TCSJnlLine.GetRANGEMAX("Journal Template Name"), CurrentTCSJnlBatchName);
        TCSJnlLine.FilterGroup := 2;
        TCSJnlLine.SetRange("Journal Batch Name", CurrentTCSJnlBatchName);
        TCSJnlLine.FilterGroup := 0;
    end;

    procedure OpenTCSJnlBatch(var TCSJnlBatch: Record "TCS Journal Batch")
    var
        CopyOfTCSJnlBatch: Record "TCS Journal Batch";
        TCSJnlTemplate: Record "TCS Journal Template";
        TCSJnlLine: Record "TCS Journal Line";
        JnlSelected: Boolean;
    begin
        CopyOfTCSJnlBatch := TCSJnlBatch;
        if not TCSJnlBatch.FindFirst() then begin
            if not TCSJnlTemplate.FindFirst() then
                TCSTemplateSelection(0, TCSJnlLine, JnlSelected);
            if not TCSJnlTemplate.IsEmpty then
                CheckTCSTemplateName(TCSJnlTemplate.Name, TCSJnlBatch.Name);

            if TCSJnlBatch.FindFirst() then;
            CopyOfTCSJnlBatch := TCSJnlBatch;
        end;
        if TCSJnlBatch.GetFilter("Journal Template Name") = '' then begin
            TCSJnlBatch.FilterGroup(2);
            TCSJnlBatch.SetRange("Journal Template Name", TCSJnlBatch."Journal Template Name");
            TCSJnlBatch.FilterGroup(0);
        end;
        TCSJnlBatch := CopyOfTCSJnlBatch;
    end;

    procedure CheckTCSTemplateName(CurrentTCSTemplateName: Code[10]; var CurrentTCSBatchName: Code[10])
    var
        TCSJnlBatch: Record "TCS Journal Batch";
    begin
        TCSJnlBatch.SetRange("Journal Template Name", CurrentTCSTemplateName);
        if not TCSJnlBatch.Get(CurrentTCSTemplateName, CurrentTCSBatchName) then begin
            if not TCSJnlBatch.FindFirst() then begin
                TCSJnlBatch.Init();
                TCSJnlBatch."Journal Template Name" := CurrentTCSTemplateName;
                TCSJnlBatch.SetupNewBatch();
                TCSJnlBatch.Name := DefaultLbl;
                TCSJnlBatch.Description := DefaultJnlLbl;
                TCSJnlBatch.Insert(True);
                Commit();
            end;
            CurrentTCSBatchName := TCSJnlBatch.Name
        end;
    end;

    procedure SetNameTCS(CurrentTCSJnlBatchName: Code[10]; var TCSJnlLine: Record "TCS Journal Line")
    begin
        TCSJnlLine.FilterGroup := 2;
        TCSJnlLine.SetRange("Journal Batch Name", CurrentTCSJnlBatchName);
        TCSJnlLine.FilterGroup := 0;
        if TCSJnlLine.FindFirst() then;
    end;

    procedure CheckNameTCS(CurrentTCSJnlBatchName: Code[10]; var TCSJnlLine: Record "TCS Journal Line")
    var
        TCSJnlBatch: Record "TCS Journal Batch";
    begin
        TCSJnlBatch.Get(TCSJnlLine.GetRANGEMAX("Journal Template Name"), CurrentTCSJnlBatchName);
    end;

    procedure LookupNameTCS(var CurrentTCSJnlBatchName: Code[10]; var TCSJnlLine: Record "TCS Journal Line")
    var
        TCSJnlBatch: Record "TCS Journal Batch";
    begin
        Commit();
        TCSJnlBatch."Journal Template Name" := TCSJnlLine.GetRANGEMAX("Journal Template Name");
        TCSJnlBatch.Name := TCSJnlLine.GetRANGEMAX("Journal Batch Name");
        TCSJnlBatch.FilterGroup := 2;
        TCSJnlBatch.SetRange("Journal Template Name", TCSJnlBatch."Journal Template Name");
        TCSJnlBatch.FilterGroup := 0;
        if Page.RunModal(0, TCSJnlBatch) = Action::LookupOK then begin
            CurrentTCSJnlBatchName := TCSJnlBatch.Name;
            SetNameTCS(CurrentTCSJnlBatchName, TCSJnlLine);
        end;
    end;

    procedure GetAccountsTCS(var TCSJnlLine: Record "TCS Journal Line"; var AccName: Text[100]; var BalAccName: Text[100])
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
    begin
        if (TCSJnlLine."Account Type" <> LastTCSJnlLine."Account Type") OR
           (TCSJnlLine."Account No." <> LastTCSJnlLine."Account No.")
        then begin
            AccName := '';
            if TCSJnlLine."Account No." <> '' then
                Case TCSJnlLine."Account Type" of
                    TCSJnlLine."Account Type"::"G/L Account":
                        if GLAcc.Get(TCSJnlLine."Account No.") then
                            AccName := GLAcc.Name;
                    TCSJnlLine."Account Type"::Customer:
                        if Cust.Get(TCSJnlLine."Account No.") then
                            AccName := Cust.Name;
                end;
        end;
        if (TCSJnlLine."Bal. Account Type" <> LastTCSJnlLine."Bal. Account Type") OR
           (TCSJnlLine."Bal. Account No." <> LastTCSJnlLine."Bal. Account No.") then begin
            BalAccName := '';
            if TCSJnlLine."Bal. Account No." <> '' then
                Case TCSJnlLine."Bal. Account Type" of
                    TCSJnlLine."Bal. Account Type"::"G/L Account":
                        if GLAcc.Get(TCSJnlLine."Bal. Account No.") then
                            BalAccName := GLAcc.Name;
                    TCSJnlLine."Bal. Account Type"::Customer:
                        if Cust.Get(TCSJnlLine."Bal. Account No.") then
                            BalAccName := Cust.Name;
                    TCSJnlLine."Bal. Account Type"::Vendor:
                        if Vend.Get(TCSJnlLine."Bal. Account No.") then
                            BalAccName := Vend.Name;
                    TCSJnlLine."Bal. Account Type"::"Bank Account":
                        if BankAcc.Get(TCSJnlLine."Bal. Account No.") then
                            BalAccName := BankAcc.Name;
                end;
        end;
        LastTCSJnlLine := TCSJnlLine;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure UpdateTCSEntryOnAdjustment(var GenJournalLine: Record "Gen. Journal Line")
    var
        TCSEntry: Record "TCS Entry";
        TCSJnlLine: Record "TCS Journal Line";
    begin
        TCSJnlLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        TCSJnlLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        TCSJnlLine.SetRange("Line No.", GenJournalLine."Line No.");
        TCSJnlLine.SetRange("Document No.", GenJournalLine."Document No.");
        if TCSJnlLine.FindFirst() then
            if TCSJnlLine.Adjustment then begin
                TCSEntry.SETRANGE("Entry No.", TCSJnlLine."TCS Transaction No.");
                TCSEntry.SETRANGE("Document No.", TCSJnlLine."TCS Invoice No.");
                if TCSEntry.FindFirst() then begin
                    TCSEntry.TestField("TCS Paid", FALSE);
                    TCSEntry."Challan Date" := TCSJnlLine."Challan Date";
                    TCSEntry."Challan No." := TCSJnlLine."Challan No.";
                    TCSEntry.Adjusted := TCSJnlLine.Adjustment;
                    TCSEntry."Bal. TCS Including SHE CESS" := TCSJnlLine."Bal. TCS Including SHECESS";
                    TCSEntry."Total TCS Including SHE CESS" := TCSJnlLine."Total TCS Incl. SHE CESS";
                    if (TCSJnlLine."TCS % Applied" <> 0) or TCSJnlLine."TCS Adjusted" then
                        TCSEntry."Adjusted TCS %" := TCSJnlLine."TCS % Applied"
                    else
                        TCSEntry."Adjusted TCS %" := TCSJnlLine."TCS %";

                    if (TCSJnlLine."Surcharge % Applied" <> 0) or TCSJnlLine."Surcharge Adjusted" then
                        TCSEntry."Adjusted Surcharge %" := TCSJnlLine."Surcharge % Applied"
                    else
                        TCSEntry."Adjusted Surcharge %" := TCSJnlLine."Surcharge %";

                    if (TCSJnlLine."eCESS % Applied" <> 0) or TCSJnlLine."eCess Adjusted" then
                        TCSEntry."Adjusted eCESS %" := TCSJnlLine."eCESS % Applied"
                    else
                        TCSEntry."Adjusted eCESS %" := TCSJnlLine."eCESS %";

                    if (TCSJnlLine."SHE Cess % Applied" <> 0) or TCSJnlLine."SHE Cess Adjusted" then
                        TCSEntry."Adjusted SHE CESS %" := TCSJnlLine."SHE Cess % Applied"
                    else
                        TCSEntry."Adjusted SHE CESS %" := TCSJnlLine."SHE Cess % on TCS";

                    if (TCSJnlLine."Balance TCS Amount" <> 0) or TCSJnlLine."TCS Adjusted" then
                        TCSEntry."TCS Amount" := TCSJnlLine."Balance TCS Amount";
                    TCSEntry."Remaining TCS Amount" := TCSEntry."TCS Amount";
                    if (TCSJnlLine."Balance Surcharge Amount" <> 0) or TCSJnlLine."Surcharge Adjusted" then
                        TCSEntry."Surcharge Amount" := TCSJnlLine."Balance Surcharge Amount";
                    if (TCSJnlLine."Balance eCESS on TCS Amt" <> 0) or TCSJnlLine."eCess Adjusted" then
                        TCSEntry."eCESS Amount" := TCSJnlLine."Balance eCESS on TCS Amt";
                    if (TCSJnlLine."Bal. SHE Cess on TCS Amt" <> 0) or TCSJnlLine."SHE Cess Adjusted" then
                        TCSEntry."SHE Cess Amount" := TCSJnlLine."Bal. SHE Cess on TCS Amt";
                    TCSEntry."Remaining Surcharge Amount" := TCSEntry."Surcharge Amount";
                    TCSEntry."TCS Amount Including Surcharge" := TCSEntry."TCS Amount" + TCSEntry."Surcharge Amount";
                    TCSEntry."Total TCS Including SHE CESS" := TCSJnlLine."Bal. TCS Including SHECESS";
                    TCSEntry."Rem. Total TCS Incl. SHE CESS" := TCSJnlLine."Bal. TCS Including SHECESS";
                    if TCSJnlLine."TCS Base Amount Adjusted" then begin
                        TCSEntry."Original TCS Base Amount" := TCSEntry."TCS Base Amount";
                        TCSEntry."TCS Base Amount" := TCSJnlLine."TCS Base Amount Applied";
                        TCSEntry."TCS Base Amount Adjusted" := TCSJnlLine."TCS Base Amount Adjusted";
                        TCSEntry."Surcharge Base Amount" := TCSJnlLine."Surcharge Base Amount";
                    end;
                    if TCSJnlLine."TCS Adjusted" then
                        TCSEntry."Surcharge Base Amount" := TCSJnlLine."Surcharge Base Amount";
                    TCSEntry.Modify();
                end;
            end;
    end;

    procedure UpdateAmount(var TCSJournalLine: Record "TCS Journal Line")
    var
        TCSManagement: Codeunit "TCS Management";
    begin
        if TCSJournalLine."Debit Amount" < TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount"
            + TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt")
                then begin
            TCSJournalLine.Amount := (TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount"
            + TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt") - TCSJournalLine."Debit Amount");

            TCSJournalLine."Bal. TCS Including SHECESS" :=
              ABS(TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount"
              + TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt"));
        end else begin
            TCSJournalLine.Amount :=
              -(TCSJournalLine."Debit Amount" - TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount"
              + TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt"));

            TCSJournalLine."Bal. TCS Including SHECESS" :=
              ABS(TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount"
              + TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt"));
        end;
        TCSJournalLine.Modify();
    end;

    procedure UpdateBalSurchargeAmount(var TCSJournalLine: Record "TCS Journal Line")
    var
        TCSManagement: Codeunit "TCS Management";
    begin
        if (TCSJournalLine."Surcharge % Applied" = 0) and (not TCSJournalLine."Surcharge Adjusted") then begin
            TCSJournalLine."Surcharge % Applied" := TCSJournalLine."Surcharge %";
            TCSJournalLine."Balance Surcharge Amount" := TCSJournalLine."Surcharge %" * TCSJournalLine."Balance TCS Amount" / 100;
        end else
            TCSJournalLine."Balance Surcharge Amount" := TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" * TCSJournalLine."Surcharge % Applied" / 100);
        TCSJournalLine.Modify();
    end;

    procedure UpdateBalECessAmount(var TCSJournalLine: Record "TCS Journal Line")
    var
        TCSManagement: Codeunit "TCS Management";
    begin
        if (TCSJournalLine."eCESS % Applied" = 0) and (not TCSJournalLine."eCess Adjusted") then begin
            TCSJournalLine."eCESS % Applied" := TCSJournalLine."eCESS %";
            TCSJournalLine."Balance eCESS on TCS Amt" := TCSJournalLine."eCESS %" * (TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount") / 100;
        end else
            TCSJournalLine."Balance eCESS on TCS Amt" := TCSManagement.RoundTCSAmount((TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount")
                * TCSJournalLine."eCESS % Applied" / 100);
        TCSJournalLine.Modify();
    end;

    procedure UpdateBalSHECessAmount(var TCSJournalLine: Record "TCS Journal Line")
    var
        TCSManagement: Codeunit "TCS Management";
    begin
        if (TCSJournalLine."SHE Cess % Applied" = 0) and (not TCSJournalLine."SHE Cess Adjusted") then begin
            TCSJournalLine."SHE Cess % Applied" := TCSJournalLine."SHE Cess % on TCS";
            TCSJournalLine."Bal. SHE Cess on TCS Amt" := TCSJournalLine."SHE Cess % on TCS" * (TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount") / 100;
        end else
            TCSJournalLine."Bal. SHE Cess on TCS Amt" := TCSManagement.RoundTCSAmount((TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount")
               * TCSJournalLine."SHE Cess % Applied" / 100);
        TCSJournalLine.Modify();
    end;

    procedure RoundTCSAmounts(var TCSJournalLine: Record "TCS Journal Line"; TCSAmount: Decimal)
    var
        TCSManagement: Codeunit "TCS Management";
    begin
        TCSJournalLine."Balance TCS Amount" := TCSManagement.RoundTCSAmount(TCSAmount);
        TCSJournalLine."Balance Surcharge Amount" := TCSManagement.RoundTCSAmount(TCSJournalLine."Balance Surcharge Amount");
        TCSJournalLine."Balance eCESS on TCS Amt" := TCSManagement.RoundTCSAmount(TCSJournalLine."Balance eCESS on TCS Amt");
        TCSJournalLine."Bal. SHE Cess on TCS Amt" := TCSManagement.RoundTCSAmount(TCSJournalLine."Bal. SHE Cess on TCS Amt");
        TCSJournalLine.Modify();
    end;

    procedure UpdateAmountForTCS(var TCSJournalLine: Record "TCS Journal Line")
    var
        TCSManagement: Codeunit "TCS Management";
    begin
        if TCSJournalLine."Debit Amount" < TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount" +
            TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt")
        then begin
            TCSJournalLine.Amount := (TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount" +
                TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt") - TCSJournalLine."Debit Amount");

            TCSJournalLine."Total TCS Incl. SHE CESS" :=
                ABS(TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount" +
                TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt"));

            TCSJournalLine."Bal. TCS Including SHECESS" :=
                ABS(TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount" +
                TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt"));
        end else begin
            TCSJournalLine.Amount := -(TCSJournalLine."Debit Amount" - TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount" +
                TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt"));

            TCSJournalLine."Total TCS Incl. SHE CESS" :=
                ABS(TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount" +
                TCSJournalLine."Balance eCESS on TCS Amt" + TCSJournalLine."Bal. SHE Cess on TCS Amt"));

            TCSJournalLine."Bal. TCS Including SHECESS" :=
                ABS(TCSManagement.RoundTCSAmount(TCSJournalLine."Balance TCS Amount" + TCSJournalLine."Balance Surcharge Amount" + TCSJournalLine."Balance eCESS on TCS Amt" +
                TCSJournalLine."Bal. SHE Cess on TCS Amt"));
        end;
        TCSJournalLine.Modify();
    end;
}