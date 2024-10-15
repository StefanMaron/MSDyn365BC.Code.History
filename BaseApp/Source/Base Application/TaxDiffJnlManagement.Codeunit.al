codeunit 17300 TaxDiffJnlManagement
{
    Permissions = TableData "Tax Diff. Journal Template" = imd,
                  TableData "Tax Diff. Journal Batch" = imd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
        Text004: Label 'Do you want to post the journal lines?';
        Text005: Label 'There is nothing to post.';
        Text006: Label 'The journal lines were successfully posted.';
        Text1000: Label '%1 journal';
        Text1001: Label 'DEFAULT';
        Text1002: Label 'Default Journal';
        LastTaxDiffJnlLine: Record "Tax Diff. Journal Line";
        OpenFromBatch: Boolean;

    [Scope('OnPrem')]
    procedure TemplateSelection(PageID: Integer; PageTemplate: Option General; var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; var JnlSelected: Boolean)
    var
        TaxDiffJnlTemplate: Record "Tax Diff. Journal Template";
    begin
        JnlSelected := true;

        TaxDiffJnlTemplate.Reset();
        if not OpenFromBatch then
            TaxDiffJnlTemplate.SetRange("Page ID", PageID);
        TaxDiffJnlTemplate.SetRange(Type, PageTemplate);

        case TaxDiffJnlTemplate.Count of
            0:
                begin
                    TaxDiffJnlTemplate.Init();
                    TaxDiffJnlTemplate.Type := PageTemplate;
                    TaxDiffJnlTemplate.Name := Format(TaxDiffJnlTemplate.Type, MaxStrLen(TaxDiffJnlTemplate.Name));
                    TaxDiffJnlTemplate.Description := StrSubstNo(Text1000, TaxDiffJnlTemplate.Type);
                    TaxDiffJnlTemplate.Validate(Type);
                    TaxDiffJnlTemplate.Insert();
                    Commit();
                end;
            1:
                TaxDiffJnlTemplate.FindFirst;
            else
                JnlSelected := PAGE.RunModal(0, TaxDiffJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            TaxDiffJnlLine.FilterGroup := 2;
            TaxDiffJnlLine.SetRange("Journal Template Name", TaxDiffJnlTemplate.Name);
            TaxDiffJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                TaxDiffJnlLine."Journal Template Name" := '';
                PAGE.Run(TaxDiffJnlTemplate."Page ID", TaxDiffJnlLine);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure TemplateSelectionFromBatch(var TaxDiffJnlBatch: Record "Tax Diff. Journal Batch")
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        JnlSelected: Boolean;
    begin
        OpenFromBatch := true;
        TaxDiffJnlLine."Journal Batch Name" := TaxDiffJnlBatch.Name;
        TemplateSelection(0, 0, TaxDiffJnlLine, JnlSelected);
    end;

    [Scope('OnPrem')]
    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var TaxDiffJnlLine: Record "Tax Diff. Journal Line")
    begin
        CheckTemplateName(TaxDiffJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        TaxDiffJnlLine.FilterGroup := 2;
        TaxDiffJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        TaxDiffJnlLine.FilterGroup := 0;
    end;

    local procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
    begin
        TaxDiffJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        if not TaxDiffJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not TaxDiffJnlBatch.FindFirst then begin
                TaxDiffJnlBatch.Init();
                TaxDiffJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
                TaxDiffJnlBatch.SetupNewBatch;
                TaxDiffJnlBatch.Name := Text1001;
                TaxDiffJnlBatch.Description := Text1002;
                TaxDiffJnlBatch.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := TaxDiffJnlBatch.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckName(CurrentJnlBatchName: Code[10]; var TaxDiffJnlLine: Record "Tax Diff. Journal Line")
    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
    begin
        TaxDiffJnlBatch.Get(TaxDiffJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    [Scope('OnPrem')]
    procedure SetName(CurrentJnlBatchName: Code[10]; var TaxDiffJnlLine: Record "Tax Diff. Journal Line")
    begin
        TaxDiffJnlLine.FilterGroup := 2;
        TaxDiffJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        TaxDiffJnlLine.FilterGroup := 0;
        if TaxDiffJnlLine.Find('-') then;
    end;

    [Scope('OnPrem')]
    procedure LookupName(var CurrentJnlBatchName: Code[10]; var TaxDiffJnlLine: Record "Tax Diff. Journal Line")
    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
    begin
        Commit();
        TaxDiffJnlBatch."Journal Template Name" := TaxDiffJnlLine.GetRangeMax("Journal Template Name");
        TaxDiffJnlBatch.Name := TaxDiffJnlLine.GetRangeMax("Journal Batch Name");
        TaxDiffJnlBatch.FilterGroup := 2;
        TaxDiffJnlBatch.SetRange("Journal Template Name", TaxDiffJnlBatch."Journal Template Name");
        TaxDiffJnlBatch.FilterGroup := 0;
        if PAGE.RunModal(0, TaxDiffJnlBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := TaxDiffJnlBatch.Name;
            SetName(CurrentJnlBatchName, TaxDiffJnlLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetAccounts(var TaxDiffJnlLine: Record "Tax Diff. Journal Line"; var TaxDiffName: Text[50]; var SourceName: Text[100])
    var
        TaxDiff: Record "Tax Difference";
        FE: Record "Fixed Asset";
    begin
        if TaxDiffJnlLine."Tax Diff. Code" <> LastTaxDiffJnlLine."Tax Diff. Code" then begin
            TaxDiffName := '';
            if TaxDiffJnlLine."Tax Diff. Code" <> '' then
                if TaxDiff.Get(TaxDiffJnlLine."Tax Diff. Code") then
                    TaxDiffName := CopyStr(TaxDiff.Description, 1, MaxStrLen(TaxDiffName));
        end;

        if (TaxDiffJnlLine."Source Type" <> LastTaxDiffJnlLine."Source Type") or
           (TaxDiffJnlLine."Source No." <> LastTaxDiffJnlLine."Source No.")
        then begin
            SourceName := '';
            if TaxDiffJnlLine."Source No." <> '' then
                case TaxDiffJnlLine."Source Type" of
                    TaxDiffJnlLine."Source Type"::"Future Expense":
                        if FE.Get(TaxDiffJnlLine."Source No.") then
                            SourceName := FE.Description;
                end;
        end;

        LastTaxDiffJnlLine := TaxDiffJnlLine;
    end;

    [Scope('OnPrem')]
    procedure JnlBatchPost(var Rec: Record "Tax Diff. Journal Batch")
    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostJnlBatch: Codeunit "Tax Diff.-Post Jnl. Batch";
        JnlWithErrors: Boolean;
    begin
        TaxDiffJnlBatch.Copy(Rec);
        with TaxDiffJnlBatch do begin
            if not Confirm(Text000, false) then
                exit;

            Find('-');
            repeat
                TaxDiffJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                TaxDiffJnlLine.SetRange("Journal Batch Name", Name);
                Clear(TaxDiffPostJnlBatch);
                if TaxDiffPostJnlBatch.Run(TaxDiffJnlLine) then
                    Mark(false)
                else begin
                    Mark(true);
                    JnlWithErrors := true;
                end;
            until Next() = 0;

            if not JnlWithErrors then
                Message(Text001)
            else
                Message(
                  Text002 +
                  Text003);

            if not Find('=><') then begin
                Reset;
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                FilterGroup(0);
                Name := '';
            end;
        end;

        Rec.Copy(TaxDiffJnlBatch);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure JnlPost(var Rec: Record "Tax Diff. Journal Line")
    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostJnlBatch: Codeunit "Tax Diff.-Post Jnl. Batch";
    begin
        TaxDiffJnlLine.Copy(Rec);
        with TaxDiffJnlLine do begin
            if not Confirm(Text004, false) then
                exit;

            TaxDiffPostJnlBatch.Run(TaxDiffJnlLine);

            if "Line No." = 0 then
                Message(Text005)
            else
                Message(Text006);

            if not Find('=><') then begin
                Reset;
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                FilterGroup(0);
                "Line No." := 10000;
            end;
        end;
        Rec.Copy(TaxDiffJnlLine);
        Commit();
    end;

    [Scope('OnPrem')]
    procedure JnlShowEntries(TaxDiffJnlLine: Record "Tax Diff. Journal Line")
    var
        TaxDiffEntry: Record "Tax Diff. Ledger Entry";
    begin
        with TaxDiffJnlLine do
            case "Source Type" of
                "Source Type"::"Future Expense":
                    begin
                        TaxDiffEntry.Reset();
                        TaxDiffEntry.SetRange("Tax Diff. Code", "Tax Diff. Code");
                        TaxDiffEntry.SetRange("Source Type", "Source Type");
                        TaxDiffEntry.SetRange("Source No.", "Source No.");
                        PAGE.Run(0, TaxDiffEntry);
                    end;
                else begin
                        TaxDiffEntry.Reset();
                        TaxDiffEntry.SetRange("Tax Diff. Code", "Tax Diff. Code");
                        PAGE.Run(0, TaxDiffEntry);
                    end;
            end;
    end;
}

