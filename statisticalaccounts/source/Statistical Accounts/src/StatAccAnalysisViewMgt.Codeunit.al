codeunit 2621 "Stat. Acc. Analysis View Mgt."
{
    [EventSubscriber(ObjectType::Table, Database::"Analysis View", 'OnValidateAccountFilter', '', false, false)]
    local procedure HandleOnBeforeLookupTotaling(var AnalysisView: Record "Analysis View"; var xRecAnalysisView: Record "Analysis View")
    var
        AnalysisViewEntry: Record "Analysis View Entry";
        StatisticalAccount: Record "Statistical Account";
        DeleteConfirmed: Boolean;
    begin
        if not VerifyCanHandle(AnalysisView) then
            exit;

        if (AnalysisView."Last Entry No." <> 0) and (xRecAnalysisView."Account Filter" = '') and (AnalysisView."Account Filter" <> '') then begin
            DeleteConfirmed := ConfirmDeleteChanges();
            if not DeleteConfirmed then
                Error('');

            StatisticalAccount.SetFilter("No.", AnalysisView."Account Filter");
            if StatisticalAccount.Find('-') then
                repeat
                    StatisticalAccount.Mark := true;
                until StatisticalAccount.Next() = 0;
            StatisticalAccount.SetRange("No.");
            if StatisticalAccount.Find('-') then
                repeat
                    if not StatisticalAccount.Mark() then begin
                        AnalysisViewEntry.SetRange("Analysis View Code", AnalysisView.Code);
                        AnalysisViewEntry.SetRange("Account No.", StatisticalAccount."No.");
                        AnalysisViewEntry.DeleteAll();
                    end;
                until StatisticalAccount.Next() = 0;
        end;
        if (AnalysisView."Last Entry No." <> 0) and (AnalysisView."Account Filter" <> xRecAnalysisView."Account Filter") and (xRecAnalysisView."Account Filter" <> '')
        then begin
            if not DeleteConfirmed then
                DeleteConfirmed := ConfirmDeleteChanges();
            if not DeleteConfirmed then
                Error('');

            AnalysisView.AnalysisViewReset();
        end
    end;

    [EventSubscriber(ObjectType::Table, Database::"Analysis View", 'OnLookupAccountFilter', '', false, false)]
    local procedure HandleOnLookupAccountFilter(var Handled: Boolean; var AccountFilter: Text; var AnalysisView: Record "Analysis View")
    var
        StatisticalAccountList: Page "Statistical Account List";
    begin
        if Handled then
            exit;

        if not VerifyCanHandle(AnalysisView) then
            exit;

        StatisticalAccountList.LookupMode(true);
        if StatisticalAccountList.RunModal() = ACTION::LookupOK then
            AccountFilter := StatisticalAccountList.GetSelectionFilter();

        Handled := true;
    end;


    [EventSubscriber(ObjectType::Table, Database::"Analysis View Entry", 'OnLookupAccountNo', '', false, false)]
    local procedure HandleOnLookupAccountNo(var AnalysisViewEntry: Record "Analysis View Entry"; var IsHandled: Boolean)
    var
        StatisticalAccount: Record "Statistical Account";
        StatisticalAccountList: Page "Statistical Account List";
    begin
        if IsHandled then
            exit;

        if not (AnalysisViewEntry."Account Source" <> AnalysisViewEntry."Account Source"::"Statistical Account") then
            exit;

        StatisticalAccountList.LookupMode(true);
        if StatisticalAccountList.RunModal() = ACTION::LookupOK then begin
            StatisticalAccountList.GetRecord(StatisticalAccount);
            AnalysisViewEntry."Account No." := StatisticalAccount."No.";
        end;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Analysis by Dimensions", 'OnGetCaptions', '', false, false)]
    local procedure HandleOnGetAnalysisByDimensionsCaptions(var AnalysisView: Record "Analysis View"; var LineDimCode: Text[30]; var AccountCaption: Text[30]; var UnitCaption: Text[30])
    var
        DummyStatisticalAccount: Record "Statistical Account";
    begin
        if not VerifyCanHandle(AnalysisView) then
            exit;

        LineDimCode := CopyStr(DummyStatisticalAccount.TableCaption(), 1, MaxStrLen(LineDimCode));
        AccountCaption := CopyStr(DummyStatisticalAccount.TableCaption(), 1, MaxStrLen(AccountCaption));
        UnitCaption := CopyStr(DummyStatisticalAccount.TableCaption(), 1, MaxStrLen(UnitCaption));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Analysis by Dimensions", 'OnGetAnalysisViewDimensionOption', '', false, false)]
    local procedure HandleOnGetAnalysisViewDimensionOption(var AnalysisView: Record "Analysis View"; var Result: enum "Analysis Dimension Option"; DimCode: Text[30])
    begin
        if not VerifyCanHandle(AnalysisView) then
            exit;

        Result := Result::"Statistical Account";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Update Analysis View", 'OnBeforeUpdateOneUpdateEntries', '', false, false)]
    local procedure HandleOnUpdateOneOnBeforeUpdateEntries(var NewAnalysisView: Record "Analysis View"; Which: Option "Ledger Entries","Budget Entries",Both; var LastReportedEntryNo: Integer; var TableID: Integer; var Supproted: Boolean)
    begin
        if not VerifyCanHandle(NewAnalysisView) then
            exit;

        Supproted := true;
        TableID := Database::"Statistical Account";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Analysis by Dimensions Matrix", 'OnFindRecOnCaseElse', '', false, false)]
    local procedure HandleOnFindRecOnCaseElse(DimOption: Enum "Analysis Dimension Option"; Which: Text[250]; var TheDimCodeBuf: Record "Dimension Code Buffer"; var Result: Boolean)
    begin
        if DimOption <> DimOption::"Statistical Account" then
            exit;

        Result := TheDimCodeBuf.Find(Which);
    end;


    [EventSubscriber(ObjectType::Page, Page::"Analysis by Dimensions Matrix", 'OnInitRecordOnCaseElse', '', false, false)]
    local procedure HandleOnInitRecordOnCaseElse(DimOption: Enum "Analysis Dimension Option"; var TheDimCodeBuf: Record "Dimension Code Buffer"; var AnalysisView: Record "Analysis View"; var AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    var
        StatisticalAccount: Record "Statistical Account";
    begin
        if not VerifyCanHandle(AnalysisView) then
            exit;

        if AnalysisByDimParameters."Account Filter" <> '' then
            StatisticalAccount.SetFilter("No.", AnalysisByDimParameters."Account Filter");

        if DimOption <> DimOption::"Statistical Account" then
            exit;

        if StatisticalAccount.FindSet() then
            repeat
                Clear(TheDimCodeBuf);
                TheDimCodeBuf.Code := StatisticalAccount."No.";
                TheDimCodeBuf.Name := StatisticalAccount.Name;
                TheDimCodeBuf.Insert();
            until StatisticalAccount.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Update Analysis View", 'OnGetEntriesForUpdate', '', false, false)]
    local procedure HandleOnGetEntriesForUpdate(var AnalysisView: Record "Analysis View"; var UpdAnalysisViewEntryBuffer: Record "Upd Analysis View Entry Buffer")
    begin
        if not VerifyCanHandle(AnalysisView) then
            exit;

        GetEntriesForUpdate(AnalysisView, UpdAnalysisViewEntryBuffer);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Analysis View", 'OnGetAnalysisViewSupported', '', false, false)]
    local procedure HandleOnGetAnalysisViewSupported(var AnalysisView: Record "Analysis View"; var IsSupported: Boolean)
    begin
        if not VerifyCanHandle(AnalysisView) then
            exit;

        IsSupported := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Analysis by Dimensions", 'OnAfterFindRecord', '', false, false)]
    local procedure HandleOnAfterFindRecord(sender: Page "Analysis by Dimensions";

    var
        DimOption: Enum "Analysis Dimension Option"; var DimCodeBuf: Record "Dimension Code Buffer"; var AnalysisView: Record "Analysis View"; Which: Text[250]; var Found: Boolean; var AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    var
        StatisticalAccount: Record "Statistical Account";
    begin
        if not VerifyCanHandle(AnalysisView) then
            exit;

        if not (DimOption = DimOption::"Statistical Account") then
            exit;

        StatisticalAccount."No." := DimCodeBuf.Code;
        if AnalysisByDimParameters."Account Filter" <> '' then
            StatisticalAccount.SetFilter("No.", AnalysisByDimParameters."Account Filter");

#pragma warning disable AA0181
        Found := StatisticalAccount.Find(Which);
#pragma warning restore AA0181

        if not Found then
            exit;

        DimCodeBuf.Init();
        DimCodeBuf.Code := StatisticalAccount."No.";
        DimCodeBuf.Name := StatisticalAccount.Name;
    end;

    local procedure GetEntriesForUpdate(var AnalysisView: Record "Analysis View"; var UpdAnalysisViewEntryBuffer: Record "Upd Analysis View Entry Buffer")
    var
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewFilter: Record "Analysis View Filter";
        GeneralLedgerSetup: Record "General Ledger Setup";
        StatisticalLedgerEntry: Record "Statistical Ledger Entry";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        NextKey: Integer;
    begin
        AnalysisViewEntry.SetRange("Analysis View Code", AnalysisView.Code);
        AnalysisViewEntry.DeleteAll();
        AnalysisViewEntry.Reset();
        StatisticalLedgerEntry.FilterGroup(2);
        StatisticalLedgerEntry.SetFilter("Statistical Account No.", '<>%1', '');
        StatisticalLedgerEntry.FilterGroup(0);
        if AnalysisView."Account Filter" <> '' then
            StatisticalLedgerEntry.SetFilter("Statistical Account No.", AnalysisView."Account Filter");

        if GeneralLedgerSetup."Global Dimension 1 Code" <> '' then
            if AnalysisViewFilter.Get(AnalysisView.Code, GeneralLedgerSetup."Global Dimension 1 Code") then
                if AnalysisViewFilter."Dimension Value Filter" <> '' then
                    StatisticalLedgerEntry.SetFilter("Global Dimension 1 Code", AnalysisViewFilter."Dimension Value Filter");
        if GeneralLedgerSetup."Global Dimension 2 Code" <> '' then
            if AnalysisViewFilter.Get(AnalysisView.Code, GeneralLedgerSetup."Global Dimension 2 Code") then
                if AnalysisViewFilter."Dimension Value Filter" <> '' then
                    StatisticalLedgerEntry.SetFilter("Global Dimension 2 Code", AnalysisViewFilter."Dimension Value Filter");

        if not StatisticalLedgerEntry.FindSet() then
            exit;

        NextKey := 1;
        UpdAnalysisViewEntryBuffer.Reset();
        if UpdAnalysisViewEntryBuffer.FindLast() then
            NextKey := UpdAnalysisViewEntryBuffer."Primary Key" + 1;

        repeat
            if UpdateAnalysisView.DimSetIDInFilter(StatisticalLedgerEntry."Dimension Set ID", AnalysisView) then begin
                UpdAnalysisViewEntryBuffer."Primary Key" := NextKey;
                NextKey += 1;
                UpdAnalysisViewEntryBuffer.AccNo := StatisticalLedgerEntry."Statistical Account No.";
                UpdAnalysisViewEntryBuffer.Amount := StatisticalLedgerEntry.Amount;
                UpdAnalysisViewEntryBuffer.EntryNo := StatisticalLedgerEntry."Entry No.";
                UpdAnalysisViewEntryBuffer.PostingDate := StatisticalLedgerEntry."Posting Date";
                UpdateAnalysisView.GetDimVal(AnalysisView."Dimension 1 Code", StatisticalLedgerEntry."Dimension Set ID");
                UpdateAnalysisView.GetDimVal(AnalysisView."Dimension 2 Code", StatisticalLedgerEntry."Dimension Set ID");
                UpdateAnalysisView.GetDimVal(AnalysisView."Dimension 3 Code", StatisticalLedgerEntry."Dimension Set ID");
                UpdateAnalysisView.GetDimVal(AnalysisView."Dimension 4 Code", StatisticalLedgerEntry."Dimension Set ID");
                UpdAnalysisViewEntryBuffer.Insert();
            end;
        until StatisticalLedgerEntry.Next() = 0;
    end;

    local procedure ConfirmDeleteChanges(): Boolean
    begin
        if not GuiAllowed() then
            exit(true);

        if not Confirm(UpdateOfAnalysisViewNeededQst, true) then
            exit(false);
    end;

    local procedure VerifyCanHandle(var AnalysisView: Record "Analysis View"): Boolean
    begin
        exit(AnalysisView."Account Source" = AnalysisView."Account Source"::"Statistical Account");
    end;

    var
        UpdateOfAnalysisViewNeededQst: Label 'Changing the setup values will delete the existing entries.\\You will have to update again.\\Do you want to continue?';
}