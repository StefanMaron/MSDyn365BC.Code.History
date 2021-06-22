codeunit 1318 "Trial Balance Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ColumnLayoutArr: array[9, 2] of Record "Column Layout";
        AccScheduleLineArr: array[9] of Record "Acc. Schedule Line";
        AccScheduleLine: Record "Acc. Schedule Line";
        TempColumnLayout: Record "Column Layout" temporary;
        AccSchedManagement: Codeunit AccSchedManagement;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        CurrentColumnLayoutName: Code[10];
        CurrentAccScheduleName: Code[10];
        LessRowsThanExpectedErr: Label 'The Trial Balance chart is not set up correctly. There are fewer rows in the account schedules than expected.';
        MoreRowsThanExpectedErr: Label 'The Trial Balance chart is not set up correctly. There are more rows in the account schedules than expected.';

    procedure LoadData(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; NoOfColumns: Integer)
    begin
        PeriodType := PeriodType::"Accounting Period";
        Initialize;
        AccSchedManagement.FindPeriod(AccScheduleLine, '', PeriodType);
        UpdateArrays(DescriptionsArr, ValuesArr, PeriodCaptionTxt, NoOfColumns);
    end;

    local procedure Initialize()
    var
        TrialBalanceSetup: Record "Trial Balance Setup";
    begin
        TrialBalanceSetup.Get();
        TrialBalanceSetup.TestField("Account Schedule Name");
        TrialBalanceSetup.TestField("Column Layout Name");

        CurrentColumnLayoutName := TrialBalanceSetup."Column Layout Name";
        CurrentAccScheduleName := TrialBalanceSetup."Account Schedule Name";

        AccSchedManagement.CopyColumnsToTemp(CurrentColumnLayoutName, TempColumnLayout);
        AccSchedManagement.OpenSchedule(CurrentAccScheduleName, AccScheduleLine);
        AccSchedManagement.OpenColumns(CurrentColumnLayoutName, TempColumnLayout);
        AccSchedManagement.CheckAnalysisView(CurrentAccScheduleName, CurrentColumnLayoutName, true);
    end;

    local procedure UpdateArrays(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; NoOfColumns: Integer)
    var
        Offset: Integer;
        Counter: Integer;
        FromDate: Date;
        ToDate: Date;
        FiscalStartDate: Date;
        I: Integer;
        TempNoOfColumns: Integer;
    begin
        Clear(PeriodCaptionTxt);
        Counter := 0;

        if AccScheduleLine.FindSet then
            repeat
                Counter := Counter + 1;
                if Counter > ArrayLen(ValuesArr, 1) then
                    Error(MoreRowsThanExpectedErr);

                DescriptionsArr[Counter] := AccScheduleLine.Description;

                if NoOfColumns = 1 then
                    Offset := 1
                else
                    Offset := 2;

                if NoOfColumns > Offset then
                    TempNoOfColumns := Offset
                else
                    TempNoOfColumns := NoOfColumns;

                if AccScheduleLine.Totaling = '' then
                    for I := Offset - NoOfColumns + 1 to Offset do
                        ValuesArr[Counter, I] := 0;

                if TempColumnLayout.FindSet then
                    repeat
                        ValuesArr[Counter, Offset] := AccSchedManagement.CalcCell(AccScheduleLine, TempColumnLayout, false);
                        ColumnLayoutArr[Counter, Offset] := TempColumnLayout;
                        AccScheduleLineArr[Counter] := AccScheduleLine;
                        AccSchedManagement.CalcColumnDates(TempColumnLayout, FromDate, ToDate, FiscalStartDate);
                        PeriodCaptionTxt[Offset] := StrSubstNo('%1..%2', FromDate, ToDate);
                        Offset := Offset - 1;
                        TempNoOfColumns := TempNoOfColumns - 1;
                    until (TempColumnLayout.Next = 0) or (TempNoOfColumns = 0);
            until AccScheduleLine.Next = 0;

        if Counter < ArrayLen(ValuesArr, 1) then
            Error(LessRowsThanExpectedErr);
    end;

    procedure DrillDown(RowNo: Integer; ColumnNo: Integer)
    begin
        TempColumnLayout := ColumnLayoutArr[RowNo, ColumnNo];
        AccScheduleLine := AccScheduleLineArr[RowNo];
        AccSchedManagement.DrillDown(TempColumnLayout, AccScheduleLine, PeriodType::Month);
    end;

    procedure NextPeriod(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; NoOfColumns: Integer)
    begin
        UpdatePeriod(DescriptionsArr, ValuesArr, PeriodCaptionTxt, '>=', NoOfColumns);
    end;

    procedure PreviousPeriod(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; NoOfColumns: Integer)
    begin
        UpdatePeriod(DescriptionsArr, ValuesArr, PeriodCaptionTxt, '<=', NoOfColumns);
    end;

    local procedure UpdatePeriod(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text; SearchText: Text[3]; NoOfColumns: Integer)
    begin
        AccSchedManagement.FindPeriod(AccScheduleLine, SearchText, PeriodType);
        UpdateArrays(DescriptionsArr, ValuesArr, PeriodCaptionTxt, NoOfColumns);
    end;
}

