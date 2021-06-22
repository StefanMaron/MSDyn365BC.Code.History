report 5611 "FA Posting Group - Net Change"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FAPostingGroupNetChange.rdlc';
    AdditionalSearchTerms = 'fixed asset posting group net change';
    ApplicationArea = FixedAssets;
    Caption = 'FA Posting Group - Net Change';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("FA Depreciation Book"; "FA Depreciation Book")
        {
            DataItemTableView = SORTING("FA No.", "Depreciation Book Code");
            RequestFilterFields = "FA No.", "Depreciation Book Code", "FA Posting Group";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(FADeprBookBookFilter; TableCaption + ': ' + FADeprBookFilter)
            {
            }
            column(FAPostingGroupNetChangeCaption; FAPostingGroupNetChangeCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not FAPostingGr.Get("FA Posting Group") then
                    CurrReport.Skip();
                FANo := "FA No.";
                DeprBookCode := "Depreciation Book Code";
                if "Disposal Date" > 0D then begin
                    Counter := Type::BalC2;
                    CalcFields("Gain/Loss");
                    SoldWithGain := ("Gain/Loss" <= 0);
                    NetDisposalMethod := CalcNetDisposalMethod;
                end else
                    Counter := Type::Maint;
                I := 0;
                while I <= Counter do begin
                    Type := I;
                    CalculateAccount("FA Posting Group", FieldCaptionText, AccNo, PostAmount);
                    InsertAmount("FA Posting Group", FieldCaptionText, AccNo, PostAmount);
                    I := I + 1;
                end;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(OnlyTotals; OnlyTotals)
            {
            }
            column(FAPostGrp_FAPostGrBuffer1; FAPostGroupBuffer[1]."FA Posting Group")
            {
            }
            column(FAFieldCapt_FAPostGrpBuff; FAPostGroupBuffer[1]."FA FieldCaption")
            {
            }
            column(AccNo_FAPostGrpBuffer1; FAPostGroupBuffer[1]."Account No.")
            {
            }
            column(Amt_FAPostGroupBuffer1; FAPostGroupBuffer[1].Amount)
            {
            }
            column(AccName_FAPostGrpBuff1; FAPostGroupBuffer[1]."Account Name")
            {
            }
            column(IntBody2Cond; not OnlyTotals and (FAPostGroupBuffer[1].Amount <> 0))
            {
            }
            column(AccountNoCaption; AccountNoCaptionLbl)
            {
            }
            column(FieldNameCaption; FieldNameCaptionLbl)
            {
            }
            column(FAPostingGroupCaption; FAPostingGroupCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not FAPostGroupBuffer[1].Find('-') then
                        CurrReport.Break();
                end else
                    if FAPostGroupBuffer[1].Next = 0 then
                        CurrReport.Break();
            end;
        }
        dataitem(Headline; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));

            trigger OnAfterGetRecord()
            begin
                FAPostGroupBuffer[1].SetCurrentKey("Account No.");
                FAPostGroupBuffer2.SetCurrentKey("Account No.");
                OldAccNo := '';
                while FAPostGroupBuffer[1].Find('-') do begin
                    FAPostGroupBuffer2 := FAPostGroupBuffer[1];
                    if OldAccNo <> FAPostGroupBuffer2."Account No." then begin
                        FAPostGroupBuffer[1].SetRange("Account No.", FAPostGroupBuffer2."Account No.");
                        FAPostGroupBuffer[1].CalcSums(Amount);
                        FAPostGroupBuffer2.Amount := FAPostGroupBuffer[1].Amount;
                        FAPostGroupBuffer2.Insert();
                        FAPostGroupBuffer[1].DeleteAll();
                        FAPostGroupBuffer[1].SetRange("Account No.");
                    end;
                    OldAccNo := FAPostGroupBuffer2."Account No.";
                end;
            end;
        }
        dataitem(Total; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(FirstTotalHeader; FirstTotalHeader)
            {
            }
            column(AccNo_FAPostGrpBuffer2; FAPostGroupBuffer2."Account No.")
            {
            }
            column(AccName_FAPostGrpBuff2; FAPostGroupBuffer2."Account Name")
            {
            }
            column(Amt_FAPostGrpBuffer2; FAPostGroupBuffer2.Amount)
            {
            }
            column(GLAccNetChange; GLAcc."Net Change")
            {
            }
            column(GLAccChngFAPostBuffAmt; GLAcc."Net Change" - FAPostGroupBuffer2.Amount)
            {
            }
            column(TotalBody3Cond; (GLAcc."Net Change" <> 0) or (FAPostGroupBuffer2.Amount <> 0))
            {
            }
            column(TotalperGLAccountCaption; TotalperGLAccountCaptionLbl)
            {
            }
            column(NetChangeCaption; NetChangeCaptionLbl)
            {
            }
            column(AccNoCaption; AccNoCaptionLbl)
            {
            }
            column(DifferenceCaption; DifferenceCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not FAPostGroupBuffer2.Find('-') then
                        CurrReport.Break();
                end else
                    if FAPostGroupBuffer2.Next = 0 then
                        CurrReport.Break();
                Clear(GLAcc);
                if GLAcc.Get(FAPostGroupBuffer2."Account No.") then begin
                    GLAcc.SetRange("Date Filter", StartingDate, EndingDate);
                    GLAcc.CalcFields("Net Change");
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
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which you want the report to show the net change posted in the fixed asset ledger entries for the fixed asset posting group.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which you want the report to show the net change posted in the fixed asset ledger entries for the fixed asset posting group.';
                    }
                    field(OnlyTotals; OnlyTotals)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Only Totals per G/L Account';
                        ToolTip = 'Specifies if you want the report to only show the total change in each general ledger account for all fixed asset posting groups.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        FANetChangeCaption = 'FA Net Change';
        AccountNameCaption = 'Account Name';
    }

    trigger OnPreReport()
    begin
        FAPostGroupBuffer[1].DeleteAll();
        FAPostGroupBuffer2.DeleteAll();
        FAGenReport.ValidateDates(StartingDate, EndingDate);
        FADeprBookFilter := "FA Depreciation Book".GetFilters;
        FAGenReport.AppendPostingDateFilter(FADeprBookFilter, StartingDate, EndingDate);
        FirstTotalHeader := true;
    end;

    var
        GLAcc: Record "G/L Account";
        FAPostingGr: Record "FA Posting Group";
        FAPostGroupBuffer: array[2] of Record "FA Posting Group Buffer" temporary;
        FAPostGroupBuffer2: Record "FA Posting Group Buffer" temporary;
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        FAGenReport: Codeunit "FA General Report";
        DeprCalc: Codeunit "Depreciation Calculation";
        Type: Option Acq,Depr,WD,Appr,C1,C2,DeprExp,Maint,Disp,GL,BV,DispAcq,DispDepr,DispWD,DispAppr,DispC1,DispC2,BalWD,BalAppr,BalC1,BalC2;
        FANo: Code[20];
        DeprBookCode: Code[20];
        StartingDate: Date;
        EndingDate: Date;
        FADeprBookFilter: Text;
        OnlyTotals: Boolean;
        FieldCaptionText: Text[80];
        AccNo: Code[20];
        OldAccNo: Code[20];
        PostAmount: Decimal;
        I: Integer;
        Counter: Integer;
        FirstTotalHeader: Boolean;
        SoldWithGain: Boolean;
        NetDisposalMethod: Boolean;
        FAPostingGroupNetChangeCaptionLbl: Label 'FA Posting Group - Net Change';
        CurrReportPageNoCaptionLbl: Label 'Page';
        AccountNoCaptionLbl: Label 'Account No.';
        FieldNameCaptionLbl: Label 'Field Name';
        FAPostingGroupCaptionLbl: Label 'FA Posting Group';
        TotalperGLAccountCaptionLbl: Label 'Total per G/L Account';
        NetChangeCaptionLbl: Label 'Net Change';
        AccNoCaptionLbl: Label 'Account No.';
        DifferenceCaptionLbl: Label 'Difference';

    local procedure InsertAmount(FAPostingGrCode: Code[20]; FieldCaptionText: Text[80]; AccNo: Code[20]; PostAmount: Decimal)
    begin
        if SkipInsertAmount(FAPostingGrCode, AccNo, PostAmount) then
            exit;
        Clear(FAPostGroupBuffer[1]);
        FAPostGroupBuffer[1]."FA Posting Group" := FAPostingGrCode;
        FAPostGroupBuffer[1]."Posting Type" := Type;
        FAPostGroupBuffer[1]."FA FieldCaption" := CopyStr(FieldCaptionText, 1, MaxStrLen(FAPostGroupBuffer[1]."FA FieldCaption"));
        FAPostGroupBuffer[1]."Account No." := AccNo;
        FAPostGroupBuffer[1].Amount := PostAmount;
        if GLAcc.Get(AccNo) then
            FAPostGroupBuffer[1]."Account Name" := GLAcc.Name;
        FAPostGroupBuffer[2] := FAPostGroupBuffer[1];
        if FAPostGroupBuffer[2].Find then begin
            FAPostGroupBuffer[2].Amount := FAPostGroupBuffer[2].Amount + FAPostGroupBuffer[1].Amount;
            FAPostGroupBuffer[2].Modify();
        end else
            FAPostGroupBuffer[1].Insert();
    end;

    local procedure CalculateAccount(FAPostingGrCode: Code[20]; var FieldCaptionText: Text[50]; var AccNo: Code[20]; var PostAmount: Decimal)
    begin
        case Type of
            Type::Acq:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Acquisition Cost Account");
                    AccNo := FAPostingGr."Acquisition Cost Account";
                    PostAmount := GetAmount(0);
                end;
            Type::Depr:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Accum. Depreciation Account");
                    AccNo := FAPostingGr."Accum. Depreciation Account";
                    PostAmount := GetAmount(0);
                end;
            Type::WD:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Write-Down Account");
                    AccNo := FAPostingGr."Write-Down Account";
                    PostAmount := GetAmount(0);
                end;
            Type::Appr:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Appreciation Account");
                    AccNo := FAPostingGr."Appreciation Account";
                    PostAmount := GetAmount(0);
                end;
            Type::C1:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Custom 1 Account");
                    AccNo := FAPostingGr."Custom 1 Account";
                    PostAmount := GetAmount(0);
                end;
            Type::C2:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Custom 2 Account");
                    AccNo := FAPostingGr."Custom 2 Account";
                    PostAmount := GetAmount(0);
                end;
            Type::DeprExp:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Depreciation Expense Acc.");
                    AccNo := FAPostingGr."Depreciation Expense Acc.";
                    PostAmount := -GetAmount(0);
                end;
            Type::Maint:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Maintenance Expense Account");
                    AccNo := FAPostingGr."Maintenance Expense Account";
                    PostAmount := CalculateMaintenance;
                end;
            Type::Disp:
                begin
                    if NetDisposalMethod then
                        PostAmount := 0
                    else
                        PostAmount := GetAmount(0);
                    if SoldWithGain then begin
                        FieldCaptionText := FAPostingGr.FieldCaption("Sales Acc. on Disp. (Gain)");
                        AccNo := FAPostingGr."Sales Acc. on Disp. (Gain)";
                        InsertAmount(
                          FAPostingGrCode,
                          FAPostingGr.FieldCaption("Sales Acc. on Disp. (Loss)"),
                          FAPostingGr."Sales Acc. on Disp. (Loss)",
                          0);
                    end else begin
                        FieldCaptionText := FAPostingGr.FieldCaption("Sales Acc. on Disp. (Loss)");
                        AccNo := FAPostingGr."Sales Acc. on Disp. (Loss)";
                        InsertAmount(
                          FAPostingGrCode,
                          FAPostingGr.FieldCaption("Sales Acc. on Disp. (Gain)"),
                          FAPostingGr."Sales Acc. on Disp. (Gain)",
                          0);
                    end;
                end;
            Type::GL:
                begin
                    if NetDisposalMethod then
                        PostAmount := GetAmount(0)
                    else
                        PostAmount := 0;
                    if SoldWithGain then begin
                        FieldCaptionText := FAPostingGr.FieldCaption("Gains Acc. on Disposal");
                        AccNo := FAPostingGr."Gains Acc. on Disposal";
                        InsertAmount(
                          FAPostingGrCode,
                          FAPostingGr.FieldCaption("Losses Acc. on Disposal"),
                          FAPostingGr."Losses Acc. on Disposal",
                          0);
                    end else begin
                        FieldCaptionText := FAPostingGr.FieldCaption("Losses Acc. on Disposal");
                        AccNo := FAPostingGr."Losses Acc. on Disposal";
                        InsertAmount(
                          FAPostingGrCode,
                          FAPostingGr.FieldCaption("Gains Acc. on Disposal"),
                          FAPostingGr."Gains Acc. on Disposal",
                          0);
                    end;
                end;
            Type::BV:
                begin
                    if SoldWithGain then begin
                        FieldCaptionText := FAPostingGr.FieldCaption("Book Val. Acc. on Disp. (Gain)");
                        AccNo := FAPostingGr."Book Val. Acc. on Disp. (Gain)";
                        InsertAmount(
                          FAPostingGrCode,
                          FAPostingGr.FieldCaption("Book Val. Acc. on Disp. (Loss)"),
                          FAPostingGr."Book Val. Acc. on Disp. (Loss)",
                          0);
                    end else begin
                        FieldCaptionText := FAPostingGr.FieldCaption("Book Val. Acc. on Disp. (Loss)");
                        AccNo := FAPostingGr."Book Val. Acc. on Disp. (Loss)";
                        InsertAmount(
                          FAPostingGrCode,
                          FAPostingGr.FieldCaption("Book Val. Acc. on Disp. (Gain)"),
                          FAPostingGr."Book Val. Acc. on Disp. (Gain)",
                          0);
                    end;
                    PostAmount := GetAmount(1);
                end;
            Type::DispAcq:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Acq. Cost Acc. on Disposal");
                    AccNo := FAPostingGr."Acq. Cost Acc. on Disposal";
                    PostAmount := GetAmount(1);
                end;
            Type::DispDepr:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Accum. Depr. Acc. on Disposal");
                    AccNo := FAPostingGr."Accum. Depr. Acc. on Disposal";
                    PostAmount := GetAmount(1);
                end;
            Type::DispWD:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Write-Down Acc. on Disposal");
                    AccNo := FAPostingGr."Write-Down Acc. on Disposal";
                    PostAmount := GetAmount(1);
                end;
            Type::DispAppr:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Appreciation Acc. on Disposal");
                    AccNo := FAPostingGr."Appreciation Acc. on Disposal";
                    PostAmount := GetAmount(1);
                end;
            Type::DispC1:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Custom 1 Account on Disposal");
                    AccNo := FAPostingGr."Custom 1 Account on Disposal";
                    PostAmount := GetAmount(1);
                end;
            Type::DispC2:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Custom 2 Account on Disposal");
                    AccNo := FAPostingGr."Custom 2 Account on Disposal";
                    PostAmount := GetAmount(1);
                end;
            Type::BalWD:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Write-Down Bal. Acc. on Disp.");
                    AccNo := FAPostingGr."Write-Down Bal. Acc. on Disp.";
                    PostAmount := GetAmount(2);
                end;
            Type::BalAppr:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Apprec. Bal. Acc. on Disp.");
                    AccNo := FAPostingGr."Apprec. Bal. Acc. on Disp.";
                    PostAmount := GetAmount(2);
                end;
            Type::BalC1:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Custom 1 Bal. Acc. on Disposal");
                    AccNo := FAPostingGr."Custom 1 Bal. Acc. on Disposal";
                    PostAmount := GetAmount(2);
                end;
            Type::BalC2:
                begin
                    FieldCaptionText := FAPostingGr.FieldCaption("Custom 2 Bal. Acc. on Disposal");
                    AccNo := FAPostingGr."Custom 2 Bal. Acc. on Disposal";
                    PostAmount := GetAmount(2);
                end;
        end;
    end;

    local procedure GetAmount(Period: Option " ",Disposal,"Bal. Disposal"): Decimal
    begin
        exit(
          FAGenReport.CalcGLPostedAmount(
            FANo, GetFieldNo, Period, StartingDate, EndingDate, DeprBookCode));
    end;

    local procedure GetFieldNo(): Integer
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        with FADeprBook do
            case Type of
                Type::Acq, Type::DispAcq:
                    exit(FieldNo("Acquisition Cost"));
                Type::Depr, Type::DeprExp, Type::DispDepr:
                    exit(FieldNo(Depreciation));
                Type::WD, Type::DispWD, Type::BalWD:
                    exit(FieldNo("Write-Down"));
                Type::Appr, Type::DispAppr, Type::BalAppr:
                    exit(FieldNo(Appreciation));
                Type::C1, Type::DispC1, Type::BalC1:
                    exit(FieldNo("Custom 1"));
                Type::C2, Type::DispC2, Type::BalC2:
                    exit(FieldNo("Custom 2"));
                Type::Disp:
                    exit(FieldNo("Proceeds on Disposal"));
                Type::GL:
                    exit(FieldNo("Gain/Loss"));
                Type::BV:
                    exit(FieldNo("Book Value on Disposal"));
            end;
    end;

    local procedure CalculateMaintenance(): Decimal
    begin
        with MaintenanceLedgEntry do begin
            SetCurrentKey("FA No.", "Depreciation Book Code", "Posting Date");
            SetRange("FA No.", FANo);
            SetRange("Depreciation Book Code", DeprBookCode);
            SetRange("Posting Date", StartingDate, EndingDate);
            CalcSums(Amount);
            exit(Amount);
        end;
    end;

    procedure CalcNetDisposalMethod(): Boolean
    var
        FALedgEntry: Record "FA Ledger Entry";
    begin
        DeprCalc.SetFAFilter(FALedgEntry, FANo, DeprBookCode, true);
        FALedgEntry.SetRange(
          "FA Posting Type", FALedgEntry."FA Posting Type"::"Proceeds on Disposal");
        if not FALedgEntry.FindFirst then
            exit(true);
        exit(FALedgEntry."Disposal Calculation Method" <> FALedgEntry."Disposal Calculation Method"::Gross);
    end;

    procedure SkipInsertAmount(FAPostingGrCode: Code[20]; AccNo: Code[20]; PostAmount: Decimal): Boolean
    begin
        if (FAPostingGrCode = '') or (AccNo = '') then
            exit(true);
        if ((Type = Type::BV) or (Type = Type::Disp)) and (not NetDisposalMethod) then
            exit(false);
        if (Type = Type::GL) and NetDisposalMethod then
            exit(false);
        exit(PostAmount = 0);
    end;
}

