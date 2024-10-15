codeunit 18747 "TDS Jnl Management"
{
    var
        LastTaxJnlLine: Record "TDS Journal Line";
        TDSJnlTemplate: Record "TDS Journal Template";
        TemplateTypeLbl: Label '%1 journal', Comment = '%1 = Template Type';
        JnlBatchNameLbl: Label 'DEFAULT';
        BatchDescriptionLbl: Label 'Default Journal';
        OpenFromBatch: Boolean;

    procedure TaxTemplateSelection(FormID: Integer; FormTemplate: Enum "TDS Template Type"; var TaxJnlLine: Record "TDS Journal Line"; var JnlSelected: Boolean)
    begin
        JnlSelected := true;
        TDSJnlTemplate.DeleteAll();
        TDSJnlTemplate.Reset();
        if not OpenFromBatch then
            TDSJnlTemplate.SetRange("Form ID", FormID);
        TDSJnlTemplate.SetRange(Type, FormTemplate);

        case TDSJnlTemplate.Count() of
            0:
                begin
                    TDSJnlTemplate.Init();
                    TDSJnlTemplate.Type := FormTemplate;
                    TDSJnlTemplate.Name := Format(TDSJnlTemplate.Type, MaxStrLen(TDSJnlTemplate.Name));
                    TDSJnlTemplate.Description := StrSubstNo(TemplateTypeLbl, TDSJnlTemplate.Type);
                    TDSJnlTemplate.Validate(Type);
                    TDSJnlTemplate.Insert();
                    Commit();
                end;
            1:
                TDSJnlTemplate.FindFirst();
            else
                JnlSelected := Page.RunModal(0, TDSJnlTemplate) = action::LookupOK;
        end;
        if JnlSelected then begin
            TaxJnlLine.FilterGroup := 2;
            TaxJnlLine.SetRange("Journal Template Name", TDSJnlTemplate.Name);
            TaxJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                TaxJnlLine."Journal Template Name" := '';
                Page.Run(TDSJnlTemplate."Form ID", TaxJnlLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromTaxBatch(var TaxJnlBatch: Record "TDS Journal Batch")
    var
        TaxJnlLine: Record "TDS Journal Line";
        JnlSelected: Boolean;
    begin
        OpenFromBatch := true;
        TaxJnlBatch.CalcFields("Template Type");
        TaxJnlLine."Journal Batch Name" := TaxJnlBatch.Name;
        TaxTemplateSelection(0, TaxJnlBatch."Template Type", TaxJnlLine, JnlSelected);
    end;

    procedure OpenTaxJnl(var CurrentTaxJnlBatchName: Code[10]; var TaxJnlLine: Record "TDS Journal Line")
    begin
        CheckTaxTemplateName(TaxJnlLine.GetRangeMax("Journal Template Name"), CurrentTaxJnlBatchName);
        TaxJnlLine.FilterGroup := 2;
        TaxJnlLine.SetRange("Journal Batch Name", CurrentTaxJnlBatchName);
        TaxJnlLine.FilterGroup := 0;
    end;

    procedure OpenTaxJnlBatch(var TaxJnlBatch: Record "TDS Journal Batch")
    var
        CopyOfTaxJnlBatch: Record "TDS Journal Batch";
        TaxJnlLine: Record "TDS Journal Line";
        JnlSelected: Boolean;
    begin
        CopyOfTaxJnlBatch := TaxJnlBatch;
        if not TaxJnlBatch.FindFirst() then begin
            for TDSJnlTemplate.Type := TDSJnlTemplate.Type::Excise TO TDSJnlTemplate.Type::"TCS Adjustments" do begin
                TDSJnlTemplate.SetRange(Type, TDSJnlTemplate.Type);
                IF not TDSJnlTemplate.FindFirst() then
                    TaxTemplateSelection(0, TDSJnlTemplate.Type, TaxJnlLine, JnlSelected);
                IF TDSJnlTemplate.FindFirst() then
                    CheckTaxTemplateName(TDSJnlTemplate.Name, TaxJnlBatch.Name);
            end;
            IF TaxJnlBatch.FindFirst() then;
            CopyOfTaxJnlBatch := TaxJnlBatch;
        end;
        IF TaxJnlBatch.GetFilter("Journal Template Name") = '' then begin
            TaxJnlBatch.FilterGroup(2);
            TaxJnlBatch.SetRange("Journal Template Name", TaxJnlBatch."Journal Template Name");
            TaxJnlBatch.FilterGroup(0);
        end;
        TaxJnlBatch := CopyOfTaxJnlBatch;
    end;

    procedure CheckTaxTemplateName(CurrentTaxTemplateName: Code[10]; var CurrentTaxBatchName: Code[10])
    var
        TaxJnlBatch: Record "TDS Journal Batch";
    begin
        TaxJnlBatch.SetRange("Journal Template Name", CurrentTaxTemplateName);
        if not TaxJnlBatch.get(CurrentTaxTemplateName, CurrentTaxBatchName) then begin
            if not TaxJnlBatch.FindFirst() then begin
                TaxJnlBatch.Init();
                TaxJnlBatch."Journal Template Name" := CurrentTaxTemplateName;
                TaxJnlBatch.SetupNewBatch();
                TaxJnlBatch.Name := JnlBatchNameLbl;
                TaxJnlBatch.Description := BatchDescriptionLbl;
                TaxJnlBatch.Insert(true);
                Commit();
            end;
            CurrentTaxBatchName := TaxJnlBatch.Name
        end;
    end;

    procedure SetNameTax(CurrentTaxJnlBatchName: Code[10]; var TaxJnlLine: Record "TDS Journal Line")
    begin
        TaxJnlLine.FilterGroup := 2;
        TaxJnlLine.SetRange("Journal Batch Name", CurrentTaxJnlBatchName);
        TaxJnlLine.FilterGroup := 0;
        if TaxJnlLine.FindFirst() then;
    end;

    procedure CheckNameTax(CurrentTaxJnlBatchName: Code[10]; var TaxJnlLine: Record "TDS Journal Line")
    var
        TaxJnlBatch: Record "TDS Journal Batch";
    begin
        TaxJnlBatch.get(TaxJnlLine.GetRangeMax("Journal Template Name"), CurrentTaxJnlBatchName);
    end;

    procedure LookupNameTax(var CurrentTaxJnlBatchName: Code[10]; var TaxJnlLine: Record "TDS Journal Line")
    var
        TaxJnlBatch: Record "TDS Journal Batch";
    begin
        Commit();
        TaxJnlBatch."Journal Template Name" := TaxJnlLine.GetRangeMax("Journal Template Name");
        TaxJnlBatch.Name := TaxJnlLine.GetRangeMax("Journal Batch Name");
        TaxJnlBatch.FilterGroup := 2;
        TaxJnlBatch.SetRange("Journal Template Name", TaxJnlBatch."Journal Template Name");
        TaxJnlBatch.FilterGroup := 0;
        if Page.RunModal(0, TaxJnlBatch) = Action::LookupOK then begin
            CurrentTaxJnlBatchName := TaxJnlBatch.Name;
            SetNameTax(CurrentTaxJnlBatchName, TaxJnlLine);
        end;
    end;

    procedure GetAccountsTax(var TaxJnlLine: Record "TDS Journal Line"; var AccName: Text[100]; var BalAccName: Text[100])
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
    begin
        if (TaxJnlLine."Account Type" <> LastTaxJnlLine."Account Type") OR
           (TaxJnlLine."Account No." <> LastTaxJnlLine."Account No.")
        then begin
            AccName := '';
            if TaxJnlLine."Account No." <> '' then
                case TaxJnlLine."Account Type" of
                    TaxJnlLine."Account Type"::"G/L Account":
                        if GLAcc.get(TaxJnlLine."Account No.") then
                            AccName := GLAcc.Name;
                    TaxJnlLine."Account Type"::Customer:
                        if Cust.get(TaxJnlLine."Account No.") then
                            AccName := Cust.Name;
                    TaxJnlLine."Account Type"::Vendor:
                        if Vend.get(TaxJnlLine."Account No.") then
                            AccName := Vend.Name;
                    TaxJnlLine."Account Type"::"Bank Account":
                        if BankAcc.get(TaxJnlLine."Account No.") then
                            AccName := BankAcc.Name;
                end;
        end;

        if (TaxJnlLine."Bal. Account Type" <> LastTaxJnlLine."Bal. Account Type") OR
           (TaxJnlLine."Bal. Account No." <> LastTaxJnlLine."Bal. Account No.") then begin
            BalAccName := '';
            if TaxJnlLine."Bal. Account No." <> '' then
                case TaxJnlLine."Bal. Account Type" of
                    TaxJnlLine."Bal. Account Type"::"G/L Account":
                        if GLAcc.Get(TaxJnlLine."Bal. Account No.") then
                            BalAccName := GLAcc.Name;
                    TaxJnlLine."Bal. Account Type"::Customer:
                        if Cust.get(TaxJnlLine."Bal. Account No.") then
                            BalAccName := Cust.Name;
                    TaxJnlLine."Bal. Account Type"::Vendor:
                        if Vend.get(TaxJnlLine."Bal. Account No.") then
                            BalAccName := Vend.Name;
                    TaxJnlLine."Bal. Account Type"::"Bank Account":
                        if BankAcc.get(TaxJnlLine."Bal. Account No.") then
                            BalAccName := BankAcc.Name;
                end;
        end;
        LastTaxJnlLine := TaxJnlLine;
    end;
}