report 11768 "No. Series Mask Generator"
{
    // Mask       XXrrrrcc
    // XX         NoSeriesCode (UpperCase, any length)
    // rrrr or rr Year (LowerCase)
    // cc         No (LowerCase, any length)

    ApplicationArea = Basic, Suite;
    Caption = 'No. Series Mask Generator';
    ProcessingOnly = true;
    UsageCategory = Tasks;
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality of No. Series Enhancements will be removed and this report should not be used. (Obsolete::Removed in release 01.2021)';
    ObsoleteTag = '15.3';

    dataset
    {
        dataitem("No. Series"; "No. Series")
        {
            DataItemTableView = WHERE(Mask = FILTER(<> ''));
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            var
                NoSeriesLine: Record "No. Series Line";
                LineNo: Integer;
            begin
                NoSeriesLine.SetRange("Series Code", Code);
                LineNo := 10000;
                if NoSeriesLine.FindLast then
                    LineNo += NoSeriesLine."Line No.";

                NoSeriesLine.SetRange("Starting Date", AccountingDate);
                if NoSeriesLine.IsEmpty then begin
                    NoSeriesLine.Init;
                    NoSeriesLine."Series Code" := Code;
                    NoSeriesLine.Open := true;
                    NoSeriesLine."Line No." := LineNo;
                    NoSeriesLine."Starting Date" := AccountingDate;
                    NoSeriesLine.Validate("Starting No.", GetStartingNoFromMask(Mask, AccountingDate));
                    NoSeriesLine.Validate("Ending No.", GetEndingNoFromMask(Mask, AccountingDate));
                    NoSeriesLine."Increment-by No." := IncrementByNo;
                    if WarningNo < 0 then
                        NoSeriesLine."Warning No." := GetWarningNoFromMask(Mask, AccountingDate, WarningNo);
                    NoSeriesLine.Insert;
                    InsertCount += 1;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AccountingDate; AccountingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting date';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"Accounting Periods", AccountingPeriod) = ACTION::LookupOK then
                                AccountingDate := AccountingPeriod."Starting Date";
                        end;
                    }
                    field(IncrementByNo; IncrementByNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Increment-by No.';
                        ToolTip = 'Specifies the increment-by number for new number series.';
                    }
                    field(WarningNo; WarningNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Warning No.';
                        MaxValue = 0;
                        ToolTip = 'Specifies warning No.';
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
    }

    trigger OnInitReport()
    begin
        IncrementByNo := 1;
        WarningNo := -10;

        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindLast then
            AccountingDate := AccountingPeriod."Starting Date";
    end;

    trigger OnPostReport()
    begin
        Message(InfoMsg, AccountingDate, InsertCount);
    end;

    var
        InfoMsg: Label '%2 No. Series Lines was created fot Accounting Period %1.', Comment = '%1 = Accounting Period, %2 = Lines Count';
        AccountingPeriod: Record "Accounting Period";
        IncrementByNo: Integer;
        AccountingDate: Date;
        InsertCount: Integer;
        WarningNo: Integer;

    local procedure GetStartingNoFromMask(lteMask: Text[20]; ldaDate: Date) lcoReturn: Code[20]
    var
        linPosYear: Integer;
        i: Integer;
    begin
        linPosYear := StrPos(lteMask, 'r');
        if linPosYear > 0 then
            while CopyStr(lteMask, linPosYear + i, 1) = 'r' do
                i += 1;

        lteMask := IncStr(ConvertStr(lteMask, 'c', '0'));
        CalcNewNoFromDate(lteMask, ldaDate, i, linPosYear);

        lcoReturn := lteMask;
    end;

    local procedure GetEndingNoFromMask(lteMask: Text[20]; ldaDate: Date) lcoReturn: Code[20]
    var
        linPosYear: Integer;
        i: Integer;
    begin
        linPosYear := StrPos(lteMask, 'r');
        if linPosYear > 0 then
            while CopyStr(lteMask, linPosYear + i, 1) = 'r' do
                i += 1;

        lteMask := ConvertStr(lteMask, 'c', '9');
        CalcNewNoFromDate(lteMask, ldaDate, i, linPosYear);

        lcoReturn := lteMask;
    end;

    local procedure GetWarningNoFromMask(lteMask: Text[20]; ldaDate: Date; linSubNo: Integer) lcoReturn: Code[20]
    var
        linPosYear: Integer;
        linPosNo: Integer;
        i: Integer;
        linNo: Integer;
    begin
        linPosYear := StrPos(lteMask, 'r');
        linPosNo := StrPos(lteMask, 'c');
        if linPosYear > 0 then
            while CopyStr(lteMask, linPosYear + i, 1) = 'r' do
                i += 1;

        lteMask := ConvertStr(lteMask, 'c', '9');
        CalcNewNoFromDate(lteMask, ldaDate, i, linPosYear);

        if linPosNo > 0 then
            Evaluate(linNo, CopyStr(lteMask, linPosNo));
        linNo += linSubNo;

        if (linNo < 0) or (linPosNo < 1) then
            lcoReturn := lteMask
        else
            lcoReturn := CopyStr(lteMask, 1, linPosNo - 1) + Format(linNo);
    end;

    local procedure CalcNewNoFromDate(var lteMask: Text[20]; InDate: Date; i: Integer; linPosYear: Integer)
    begin
        if InDate = 0D then
            exit;

        if linPosYear = 0 then
            exit;

        if i = 2 then
            lteMask := InsStr(DelStr(lteMask, linPosYear, 2), CopyStr(Format(Date2DMY(InDate, 3)), 3), linPosYear)
        else
            if i = 4 then
                lteMask := InsStr(DelStr(lteMask, linPosYear, 4), Format(Date2DMY(InDate, 3)), linPosYear);
    end;
}

