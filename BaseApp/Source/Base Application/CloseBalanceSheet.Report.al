#if not CLEAN17
report 11784 "Close Balance Sheet"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Close Balance Sheet (Obsolete)';
    Permissions = TableData "G/L Entry" = m;
    ProcessingOnly = true;
    UsageCategory = Tasks;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = SORTING("No.") WHERE("Account Type" = CONST(Posting), "Income/Balance" = CONST("Balance Sheet"));
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = FIELD("No.");
                DataItemTableView = SORTING("G/L Account No.", "Posting Date");

                trigger OnAfterGetRecord()
                var
                    TempDimBuf: Record "Dimension Buffer" temporary;
                    TempDimBuf2: Record "Dimension Buffer" temporary;
                    EntryNo: Integer;
                begin
                    if FieldActive("Business Unit Code") and
                       (ClosePerBusUnit or ClosePerGlobalDim1 or ClosePerGlobalDim2 or not ClosePerGlobalDimOnly)
                    then begin
                        SetRange("Business Unit Code", "Business Unit Code");
                        GenJnlLine."Business Unit Code" := "Business Unit Code";
                    end;
                    if FieldActive("Global Dimension 1 Code") and
                       (ClosePerGlobalDim1 or ClosePerGlobalDim2 or not ClosePerGlobalDimOnly)
                    then
                        SetRange("Global Dimension 1 Code", "Global Dimension 1 Code");
                    if FieldActive("Global Dimension 2 Code") and
                       (ClosePerGlobalDim2 or not ClosePerGlobalDimOnly)
                    then
                        SetRange("Global Dimension 2 Code", "Global Dimension 2 Code");
                    if not ClosePerGlobalDimOnly then
                        SetRange("Close Income Statement Dim. ID", "Close Income Statement Dim. ID");

                    CalcSumsInFilter;
                    if (Amount <> 0) or ("Additional-Currency Amount" <> 0) then begin
                        if ClosePerGlobalDimOnly then begin
                            EntryNo := "Entry No.";
                            GetGLEntryDimensions(EntryNo, TempDimBuf);
                        end else begin
                            EntryNo := "Close Income Statement Dim. ID";
                            DimBufMgt.GetDimensions(EntryNo, TempDimBuf);
                        end;
                        if not TempDimBuf2.IsEmpty() then
                            TempDimBuf2.DeleteAll();
                        if TempSelectedDim.FindSet then
                            repeat
                                if TempDimBuf.Get(DATABASE::"G/L Entry", EntryNo, TempSelectedDim."Dimension Code")
                                then begin
                                    TempDimBuf2."Table ID" := TempDimBuf."Table ID";
                                    TempDimBuf2."Dimension Code" := TempDimBuf."Dimension Code";
                                    TempDimBuf2."Dimension Value Code" := TempDimBuf."Dimension Value Code";
                                    TempDimBuf2.Insert();
                                end;
                            until TempSelectedDim.Next() = 0;

                        EntryNo := DimBufMgt2.FindDimensions(TempDimBuf2);
                        if EntryNo = 0 then
                            EntryNo := DimBufMgt2.InsertDimensions(TempDimBuf2);

                        EntryNoAmountBuf.Reset();
                        if ClosePerBusUnit and FieldActive("Business Unit Code") then
                            EntryNoAmountBuf."Business Unit Code" := "Business Unit Code"
                        else
                            EntryNoAmountBuf."Business Unit Code" := '';
                        EntryNoAmountBuf."Entry No." := EntryNo;
                        if EntryNoAmountBuf.Find then begin
                            EntryNoAmountBuf.Amount := EntryNoAmountBuf.Amount + Amount;
                            EntryNoAmountBuf.Amount2 := EntryNoAmountBuf.Amount2 + "Additional-Currency Amount";
                            EntryNoAmountBuf.Modify();
                        end else begin
                            EntryNoAmountBuf.Amount := Amount;
                            EntryNoAmountBuf.Amount2 := "Additional-Currency Amount";
                            EntryNoAmountBuf.Insert();
                        end;
                    end;
                    Find('+');
                    if FieldActive("Business Unit Code") then
                        SetRange("Business Unit Code");
                    if FieldActive("Global Dimension 1 Code") then
                        SetRange("Global Dimension 1 Code");
                    if FieldActive("Global Dimension 2 Code") then
                        SetRange("Global Dimension 2 Code");
                    SetRange("Close Income Statement Dim. ID");
                end;

                trigger OnPostDataItem()
                var
                    TempDimBuf2: Record "Dimension Buffer" temporary;
                    GlobalDimVal1: Code[20];
                    GlobalDimVal2: Code[20];
                    NewDimensionID: Integer;
                begin
                    EntryNoAmountBuf.Reset();
                    if EntryNoAmountBuf.FindSet then
                        repeat
                            if (EntryNoAmountBuf.Amount <> 0) or (EntryNoAmountBuf.Amount2 <> 0) then begin
                                GenJnlLine."Line No." := GenJnlLine."Line No." + 10000;
                                GenJnlLine."Account No." := "G/L Account No.";
                                GenJnlLine."Source Code" := SourceCodeSetup."Close Balance Sheet";
                                GenJnlLine."Reason Code" := GenJnlBatch."Reason Code";
                                GenJnlLine.Correction := false;
                                GenJnlLine.Validate(Amount, -EntryNoAmountBuf.Amount);
                                GenJnlLine."Source Currency Amount" := -EntryNoAmountBuf.Amount2;
                                GenJnlLine."Business Unit Code" := EntryNoAmountBuf."Business Unit Code";

                                TempDimBuf2.DeleteAll();
                                DimBufMgt2.GetDimensions(EntryNoAmountBuf."Entry No.", TempDimBuf2);
                                NewDimensionID := DimMgt.CreateDimSetIDFromDimBuf(TempDimBuf2);
                                GenJnlLine."Dimension Set ID" := NewDimensionID;
                                DimMgt.UpdateGlobalDimFromDimSetID(NewDimensionID, GlobalDimVal1, GlobalDimVal2);
                                GenJnlLine."Shortcut Dimension 1 Code" := '';
                                if ClosePerGlobalDim1 then
                                    GenJnlLine."Shortcut Dimension 1 Code" := GlobalDimVal1;
                                GenJnlLine."Shortcut Dimension 2 Code" := '';
                                if ClosePerGlobalDim2 then
                                    GenJnlLine."Shortcut Dimension 2 Code" := GlobalDimVal2;

                                if PostToClosingBalanceSheetAcc = PostToClosingBalanceSheetAcc::Details then begin
                                    GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                                    GenJnlLine."Bal. Account No." := ClosingBalanceSheetGLAcc."No.";
                                end;

                                GenJnlLine.AdjustDebitCredit(true);
                                HandleGenJnlLine;
                            end;
                        until EntryNoAmountBuf.Next() = 0;

                    if not EntryNoAmountBuf.IsEmpty() then
                        EntryNoAmountBuf.DeleteAll();
                end;

                trigger OnPreDataItem()
                begin
                    if ClosePerBusUnit or ClosePerGlobalDim1 or ClosePerGlobalDim2 or not ClosePerGlobalDimOnly then
                        SetCurrentKey(
                          "G/L Account No.", "Business Unit Code",
                          "Global Dimension 1 Code", "Global Dimension 2 Code", "Close Income Statement Dim. ID",
                          "Posting Date")
                    else
                        SetCurrentKey("G/L Account No.", "Posting Date");
                    SetRange("Posting Date", 0D, FiscYearClosingDate);

                    if not EntryNoAmountBuf.IsEmpty() then
                        EntryNoAmountBuf.DeleteAll();

                    Clear(DimBufMgt2);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                UpdateCloseIncomeStmtDimID("No.");
            end;

            trigger OnPostDataItem()
            begin
                if ((TotalAmount <> 0) or ((TotalAmountAddCurr <> 0) and (GLSetup."Additional Reporting Currency" <> ''))) and
                   (PostToClosingBalanceSheetAcc = PostToClosingBalanceSheetAcc::Balance)
                then begin
                    GenJnlLine."Business Unit Code" := '';
                    GenJnlLine."Shortcut Dimension 1 Code" := '';
                    GenJnlLine."Shortcut Dimension 2 Code" := '';
                    GenJnlLine."Line No." := GenJnlLine."Line No." + 10000;
                    GenJnlLine."Account No." := ClosingBalanceSheetGLAcc."No.";
                    GenJnlLine."Source Code" := SourceCodeSetup."Close Balance Sheet";
                    GenJnlLine."Reason Code" := GenJnlBatch."Reason Code";
                    GenJnlLine."Currency Code" := '';
                    GenJnlLine."Additional-Currency Posting" :=
                      GenJnlLine."Additional-Currency Posting"::None;
                    GenJnlLine.Correction := false;
                    GenJnlLine.Validate(Amount, TotalAmount);
                    GenJnlLine."Source Currency Amount" := TotalAmountAddCurr;
                    HandleGenJnlLine;
                    Window.Update(1, GenJnlLine."Account No.");
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(EndDateReq; EndDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Year Ending Date';
                        ToolTip = 'Specifies the end date fiscal year to close the balance sheet.';

                        trigger OnValidate()
                        begin
                            ValidateEndDate(true);
                        end;
                    }
                    field("GenJnlLine.""Journal Template Name"""; GenJnlLine."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Journal Template';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the journal template. This template will be used as the format for report results.';

                        trigger OnValidate()
                        begin
                            GenJnlLine."Journal Batch Name" := '';
                            DocNo := '';
                        end;
                    }
                    field("GenJnlLine.""Journal Batch Name"""; GenJnlLine."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Journal Batch';
                        Lookup = true;
                        ToolTip = 'Specifies the relevant general journal batch name.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                            GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlBatch."Journal Template Name" := GenJnlLine."Journal Template Name";
                            GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then begin
                                GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
                                ValidateJnl;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLine."Journal Batch Name" <> '' then begin
                                GenJnlLine.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                            end;
                            ValidateJnl;
                        end;
                    }
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies a document number for the journal line.';
                    }
                    field("ClosingBalanceSheetGLAcc.""No."""; ClosingBalanceSheetGLAcc."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closing Balance Sheet Account';
                        TableRelation = "G/L Account";
                        ToolTip = 'Specifies a closing balance sheet account.';

                        trigger OnValidate()
                        begin
                            if ClosingBalanceSheetGLAcc."No." <> '' then begin
                                ClosingBalanceSheetGLAcc.Find;
                                ClosingBalanceSheetGLAcc.CheckGLAcc;
                            end;
                        end;
                    }
                    field(PostToClosingBalanceSheetAcc; PostToClosingBalanceSheetAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post to Closing Balance Sheet Acc.';
                        OptionCaption = 'Balance,Details';
                        ToolTip = 'Specifies if the resulting entries are posted with the Closing Balance Sheet account as a balancing account on each line (Details) or if balance sheets are posted as an extra line with a summarized amount (Balance).';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies a posting description.';
                    }
                    group("Close by")
                    {
                        Caption = 'Close by';
                        field(ClosePerBusUnit; ClosePerBusUnit)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Business Unit Code';
                            ToolTip = 'Specifies to display the business unit code that the budget entry is linked to.';
                        }
                        field(ColumnDim; ColumnDim)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Dimensions';
                            Editable = false;
                            ToolTip = 'Specifies the relevant dimension code. Dimension codes are used to group entries with similar characteristics.';

                            trigger OnAssistEdit()
                            begin
                                DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"Close Balance Sheet", ColumnDim);
                            end;
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PostingDescription = '' then
                PostingDescription :=
                  CopyStr(ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, REPORT::"Close Balance Sheet"), 1, 30);
            EndDateReq := 0D;
            AccountingPeriod.SetRange("New Fiscal Year", true);
            AccountingPeriod.SetRange("Date Locked", true);
            if AccountingPeriod.Find('+') then begin
                EndDateReq := AccountingPeriod."Starting Date" - 1;
                if not ValidateEndDate(false) then
                    EndDateReq := 0D;
            end;
            ValidateJnl;
            ColumnDim := DimSelectionBuf.GetDimSelectionText(3, REPORT::"Close Balance Sheet", '');
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        PostingDescription := '';
    end;

    trigger OnPostReport()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        UpdateAnalysisView.UpdateAll(0, true);
    end;

    trigger OnPreReport()
    var
        s: Text[1024];
    begin
        if EndDateReq = 0D then
            Error(Text000);
        ValidateEndDate(true);
        if DocNo = '' then
            Error(Text001);

        GLSetup.Get();
        SelectedDim.GetSelectedDim(UserId, 3, REPORT::"Close Balance Sheet", '', TempSelectedDim);
        s := CheckDimPostingRules(TempSelectedDim);
        if (s <> '') and GLSetup."Dont Check Dimension" then
            if not Confirm(s + Text022, false) then
                Error('');

        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        SourceCodeSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then begin
            if ClosingBalanceSheetGLAcc."No." = '' then
                Error(Text002);
            if not Confirm(
                 Text003 +
                 Text005 +
                 Text007, false)
            then
                CurrReport.Quit;
        end;

        ClosePerGlobalDim1 := false;
        ClosePerGlobalDim2 := false;
        ClosePerGlobalDimOnly := true;

        if TempSelectedDim.FindSet then
            repeat
                if TempSelectedDim."Dimension Code" = GLSetup."Global Dimension 1 Code" then
                    ClosePerGlobalDim1 := true;
                if TempSelectedDim."Dimension Code" = GLSetup."Global Dimension 2 Code" then
                    ClosePerGlobalDim2 := true;
                if (TempSelectedDim."Dimension Code" <> GLSetup."Global Dimension 1 Code") and
                   (TempSelectedDim."Dimension Code" <> GLSetup."Global Dimension 2 Code")
                then
                    ClosePerGlobalDimOnly := false;
            until TempSelectedDim.Next() = 0;

        CollectCloseIncomeStmtDimID;

        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if not GenJnlLine.FindLast then;
        GenJnlLine.Init();
        GenJnlLine."Posting Date" := FiscYearClosingDate;
        GenJnlLine."Document No." := DocNo;
        GenJnlLine.Description := PostingDescription;
        GenJnlLine."Posting No. Series" := GenJnlBatch."Posting No. Series";
        Window.Open(
          Text008 +
          Text009);
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        ClosingBalanceSheetGLAcc: Record "G/L Account";
        GLSetup: Record "General Ledger Setup";
        DimSelectionBuf: Record "Dimension Selection Buffer";
        SelectedDim: Record "Selected Dimension";
        TempSelectedDim: Record "Selected Dimension" temporary;
        EntryNoAmountBuf: Record "Entry No. Amount Buffer" temporary;
        ObjTransl: Record "Object Translation";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimBufMgt2: Codeunit "Dimension Buffer Management";
        Window: Dialog;
        FiscalYearStartDate: Date;
        FiscYearClosingDate: Date;
        EndDateReq: Date;
        DocNo: Code[20];
        PostingDescription: Text[50];
        ClosePerBusUnit: Boolean;
        ClosePerGlobalDim1: Boolean;
        ClosePerGlobalDim2: Boolean;
        ClosePerGlobalDimOnly: Boolean;
        TotalAmount: Decimal;
        TotalAmountAddCurr: Decimal;
        ColumnDim: Text[250];
        Text000: Label 'Please enter the ending date for the fiscal year.';
        Text001: Label 'Please enter a Document No.';
        Text002: Label 'Please enter Closing Balance Sheet Account No.';
        Text003: Label 'With the use of an additional reporting currency, this batch job will post closing entries directly to the general ledger.';
        Text005: Label 'These closing entries will not be transferred to a general journal before the program posts them to the general ledger.\\';
        Text007: Label 'Do you wish to continue?';
        Text008: Label 'Creating general journal lines...\\';
        Text009: Label 'Account No. #1##########\';
        Text014: Label 'The fiscal year must be closed before the balance sheet can be closed.';
        Text015: Label 'The fiscal year does not exist.';
        Text020: Label 'The following G/L Accounts have mandatory dimension codes:';
        Text021: Label '\\In order to post to this journal you may also select these dimensions:';
        Text022: Label '\\Continue and create journal?';
        NextDimID: Integer;
        PostToClosingBalanceSheetAcc: Option Balance,Details;

    local procedure ValidateEndDate(RealMode: Boolean): Boolean
    var
        OK: Boolean;
    begin
        if EndDateReq = 0D then
            exit;

        OK := AccountingPeriod.Get(EndDateReq + 1);
        if OK then
            OK := AccountingPeriod."New Fiscal Year";
        if OK then begin
            if not AccountingPeriod."Date Locked" then begin
                if not RealMode then
                    exit;
                Error(Text014);
            end;
            FiscYearClosingDate := ClosingDate(EndDateReq);
            AccountingPeriod.SetRange("New Fiscal Year", true);
            OK := AccountingPeriod.Find('<');
            FiscalYearStartDate := AccountingPeriod."Starting Date";
        end;
        if not OK then begin
            if not RealMode then
                exit;
            Error(Text015);
        end;
        exit(true);
    end;

    local procedure ValidateJnl()
    begin
        DocNo := '';
        if GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name") then
            if GenJnlBatch."No. Series" <> '' then
                DocNo := NoSeriesMgt.TryGetNextNo(GenJnlBatch."No. Series", EndDateReq);
    end;

    local procedure HandleGenJnlLine()
    begin
        GenJnlLine."Additional-Currency Posting" :=
          GenJnlLine."Additional-Currency Posting"::None;
        if GLSetup."Additional Reporting Currency" <> '' then begin
            GenJnlLine."Source Currency Code" := GLSetup."Additional Reporting Currency";
            if (GenJnlLine.Amount = 0) and
               (GenJnlLine."Source Currency Amount" <> 0)
            then begin
                GenJnlLine."Additional-Currency Posting" :=
                  GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only";
                GenJnlLine.Validate(Amount, GenJnlLine."Source Currency Amount");
                GenJnlLine."Source Currency Amount" := 0;
            end;
            if GenJnlLine.Amount <> 0 then
                GenJnlPostLine.RunWithCheck(GenJnlLine);
        end else
            GenJnlLine.Insert();
    end;

    local procedure CollectCloseIncomeStmtDimID()
    var
        GLEntry: Record "G/L Entry";
        DimSetEntry: Record "Dimension Set Entry";
        TempDimBuf: Record "Dimension Buffer";
    begin
        if ClosePerGlobalDimOnly then
            exit;

        GLEntry.SetCurrentKey("Close Income Statement Dim. ID");
        GLEntry.SetFilter("Close Income Statement Dim. ID", '>1');
        if GLEntry.FindSet then begin
            repeat
                DimSetEntry.SetRange("Dimension Set ID", GLEntry."Dimension Set ID");
                if DimSetEntry.FindSet then begin
                    if not TempDimBuf.IsEmpty() then
                        TempDimBuf.DeleteAll();

                    repeat
                        TempDimBuf."Table ID" := DATABASE::"G/L Entry";
                        TempDimBuf."Entry No." := GLEntry."Entry No.";
                        TempDimBuf."Dimension Code" := DimSetEntry."Dimension Code";
                        TempDimBuf."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                        TempDimBuf.Insert();
                    until DimSetEntry.Next() = 0;

                    DimBufMgt.InsertDimensionsUsingEntryNo(
                      TempDimBuf, GLEntry."Close Income Statement Dim. ID");
                end;
                GLEntry.SetFilter(
                  "Close Income Statement Dim. ID", '>%1', GLEntry."Close Income Statement Dim. ID");
            until GLEntry.Next() = 0;
            NextDimID := GLEntry."Close Income Statement Dim. ID" + 1;
        end else
            NextDimID := 2; // 1 is used when there are no dimensions on the entry
    end;

    local procedure UpdateCloseIncomeStmtDimID(AccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        TempDimBuf: Record "Dimension Buffer";
        DimID: Integer;
    begin
        if ClosePerGlobalDimOnly then
            exit;

        GLEntry.SetCurrentKey(
          "G/L Account No.", "Business Unit Code",
          "Global Dimension 1 Code", "Global Dimension 2 Code", "Close Income Statement Dim. ID",
          "Posting Date");
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.SetRange("Close Income Statement Dim. ID", 0);
        GLEntry.SetRange("Posting Date", FiscalYearStartDate, FiscYearClosingDate);

        while GLEntry.FindFirst do begin
            GetGLEntryDimensions(GLEntry."Entry No.", TempDimBuf);
            if TempDimBuf.FindFirst then begin
                DimID := DimBufMgt.FindDimensions(TempDimBuf);
                if DimID = 0 then begin
                    DimBufMgt.InsertDimensionsUsingEntryNo(TempDimBuf, NextDimID);
                    DimID := NextDimID;
                    NextDimID := NextDimID + 1;
                end;
            end else
                DimID := 1;
            GLEntry."Close Income Statement Dim. ID" := DimID;
            GLEntry.Modify();
        end;
    end;

    local procedure CalcSumsInFilter()
    begin
        "G/L Entry".CalcSums(Amount);
        TotalAmount := TotalAmount + "G/L Entry".Amount;
        if GLSetup."Additional Reporting Currency" <> '' then begin
            "G/L Entry".CalcSums("Additional-Currency Amount");
            TotalAmountAddCurr := TotalAmountAddCurr + "G/L Entry"."Additional-Currency Amount";
        end;
    end;

    local procedure GetGLEntryDimensions(EntryNo: Integer; var DimBuf: Record "Dimension Buffer")
    var
        GLEntry: Record "G/L Entry";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        DimBuf.DeleteAll();
        GLEntry.Get(EntryNo);
        DimSetEntry.SetRange("Dimension Set ID", GLEntry."Dimension Set ID");
        if DimSetEntry.FindSet then
            repeat
                DimBuf."Table ID" := DATABASE::"G/L Entry";
                DimBuf."Entry No." := EntryNo;
                DimBuf."Dimension Code" := DimSetEntry."Dimension Code";
                DimBuf."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                DimBuf.Insert();
            until DimSetEntry.Next() = 0;
    end;

    local procedure CheckDimPostingRules(var SelectedDim: Record "Selected Dimension"): Text[1024]
    var
        DefaultDim: Record "Default Dimension";
        GLAcc: Record "G/L Account";
        s: Text[1024];
        d: Text[1024];
        PrevAcc: Code[20];
    begin
        DefaultDim.SetRange("Table ID", DATABASE::"G/L Account");
        DefaultDim.SetFilter(
          "Value Posting", '%1|%2',
          DefaultDim."Value Posting"::"Same Code", DefaultDim."Value Posting"::"Code Mandatory");

        if DefaultDim.FindSet then
            repeat
                if DefaultDim."No." <> GLAcc."No." then
                    if not GLAcc.Get(DefaultDim."No.") then
                        GLAcc."Income/Balance" := GLAcc."Income/Balance"::"Income Statement";

                SelectedDim.SetRange("Dimension Code", DefaultDim."Dimension Code");
                if (not SelectedDim.Find('-')) and (GLAcc."Income/Balance" = GLAcc."Income/Balance"::"Balance Sheet") then begin
                    if StrPos(d, DefaultDim."Dimension Code") < 1 then
                        d := d + ' ' + Format(DefaultDim."Dimension Code");
                    if PrevAcc <> DefaultDim."No." then begin
                        PrevAcc := DefaultDim."No.";
                        if s = '' then
                            s := Text020;
                        s := s + ' ' + Format(DefaultDim."No.");
                    end;
                end;
                SelectedDim.SetRange("Dimension Code");
            until (DefaultDim.Next() = 0) or (StrLen(s) > MaxStrLen(s) - MaxStrLen(DefaultDim."No.") - StrLen(Text021) - 1);

        if s <> '' then
            s := CopyStr(s + Text021 + d, 1, MaxStrLen(s));
        exit(s);
    end;
}
#endif