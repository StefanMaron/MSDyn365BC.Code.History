codeunit 9200 "Matrix Management"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'The previous column set could not be found.';
        Text002: Label 'The period could not be found.';
        Text003: Label 'There are no Calendar entries within the filter.';
        RoundingFormatTxt: Label '<Precision,%1><Standard Format,0>', Locked = true;
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;
        SetOption: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;

    procedure SetPeriodColumnSet(DateFilter: Text; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; Direction: Option Backward,Forward; var FirstColumn: Date; var LastColumn: Date; NoOfColumns: Integer)
    var
        Period: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
        Steps: Integer;
        TmpFirstColumn: Date;
        TmpLastColumn: Date;
    begin
        Period.SetRange("Period Type", PeriodType);
        if DateFilter = '' then begin
            Period."Period Start" := WorkDate;
            if PeriodFormMgt.FindDate('<=', Period, PeriodType) then
                Steps := 1;
            PeriodFormMgt.NextDate(Steps, Period, PeriodType);
            DateFilter := '>=' + Format(Period."Period Start");
        end else begin
            Period.SetFilter("Period Start", DateFilter);
            Period.Find('-');
        end;

        if (Format(FirstColumn) = '') and (Format(LastColumn) = '') then begin
            FirstColumn := Period."Period Start";
            Period.Next(NoOfColumns - 1);
            LastColumn := Period."Period Start";
            exit;
        end;

        if Direction = Direction::Forward then begin
            Period.SetFilter("Period Start", DateFilter);
            if Period.Get(PeriodType, LastColumn) then
                Period.Next;
            TmpFirstColumn := Period."Period Start";
            Period.Next(NoOfColumns - 1);
            TmpLastColumn := Period."Period Start";
            if TmpFirstColumn <> LastColumn then begin
                FirstColumn := TmpFirstColumn;
                LastColumn := TmpLastColumn;
            end;
            exit;
        end;

        if Direction = Direction::Backward then begin
            if Period.Get(PeriodType, FirstColumn) then
                Period.Next(-1);
            TmpLastColumn := Period."Period Start";
            Period.Next(-NoOfColumns + 1);
            TmpFirstColumn := Period."Period Start";
            if TmpLastColumn <> FirstColumn then begin
                FirstColumn := TmpFirstColumn;
                LastColumn := TmpLastColumn;
            end;
        end;
    end;

    procedure SetDimColumnSet(DimensionCode: Code[20]; DimFilter: Text; SetWanted: Option; var RecordPosition: Text; var FirstColumn: Text; var LastColumn: Text; NoOfColumns: Integer)
    var
        DimVal: Record "Dimension Value";
        TmpFirstColumn: Text[1024];
        TmpLastColumn: Text[1024];
        TmpSteps: Integer;
    begin
        DimVal.SetRange("Dimension Code", DimensionCode);
        if DimFilter <> '' then
            DimVal.SetFilter(Code, DimFilter);

        case SetWanted of
            SetOption::Initial:
                if DimVal.Find('-') then begin
                    RecordPosition := DimVal.GetPosition;
                    FirstColumn := DimVal.Code;
                    TmpSteps := DimVal.Next(NoOfColumns - 1);
                    LastColumn := DimVal.Code;
                end;
            SetOption::Same:
                if RecordPosition <> '' then begin
                    DimVal.SetPosition(RecordPosition);
                    DimVal.Find('=');
                    FirstColumn := DimVal.Code;
                    TmpSteps := DimVal.Next(NoOfColumns - 1);
                    LastColumn := DimVal.Code;
                end;
            SetOption::Next:
                if RecordPosition <> '' then begin
                    DimVal.SetPosition(RecordPosition);
                    DimVal.Find('=');
                    if DimVal.Next(NoOfColumns) <> 0 then begin
                        RecordPosition := DimVal.GetPosition;
                        TmpFirstColumn := DimVal.Code;
                        TmpSteps := DimVal.Next(NoOfColumns - 1);
                        TmpLastColumn := DimVal.Code;
                        if TmpFirstColumn <> LastColumn then begin
                            FirstColumn := TmpFirstColumn;
                            LastColumn := TmpLastColumn;
                        end;
                    end else
                        SetDimColumnSet(DimensionCode, DimFilter, SetOption::Same, RecordPosition, FirstColumn, LastColumn, NoOfColumns);
                end;
            SetOption::Previous:
                if RecordPosition <> '' then begin
                    DimVal.SetPosition(RecordPosition);
                    DimVal.Find('=');
                    if DimVal.Next(-1) <> 0 then begin
                        TmpLastColumn := DimVal.Code;
                        TmpSteps := DimVal.Next(-NoOfColumns + 1);
                        RecordPosition := DimVal.GetPosition;
                        TmpFirstColumn := DimVal.Code;
                        if TmpLastColumn <> FirstColumn then begin
                            FirstColumn := TmpFirstColumn;
                            LastColumn := TmpLastColumn;
                        end;
                    end else
                        SetDimColumnSet(DimensionCode, DimFilter, SetOption::Same, RecordPosition, FirstColumn, LastColumn, NoOfColumns);
                end;
            SetOption::NextColumn:
                if RecordPosition <> '' then begin
                    DimVal.SetPosition(RecordPosition);
                    DimVal.Find('=');
                    if DimVal.Next <> 0 then begin
                        RecordPosition := DimVal.GetPosition;
                        TmpFirstColumn := DimVal.Code;
                        TmpSteps := DimVal.Next(NoOfColumns - 1);
                        TmpLastColumn := DimVal.Code;
                        if TmpFirstColumn <> LastColumn then begin
                            FirstColumn := TmpFirstColumn;
                            LastColumn := TmpLastColumn;
                        end;
                    end else
                        SetDimColumnSet(DimensionCode, DimFilter, SetOption::Same, RecordPosition, FirstColumn, LastColumn, NoOfColumns);
                end;
            SetOption::PreviousColumn:
                if RecordPosition <> '' then begin
                    DimVal.SetPosition(RecordPosition);
                    DimVal.Find('=');
                    if DimVal.Next(-1) <> 0 then begin
                        RecordPosition := DimVal.GetPosition;
                        TmpFirstColumn := DimVal.Code;
                        TmpSteps := DimVal.Next(NoOfColumns - 1);
                        TmpLastColumn := DimVal.Code;
                        if TmpLastColumn <> FirstColumn then begin
                            FirstColumn := TmpFirstColumn;
                            LastColumn := TmpLastColumn;
                        end;
                    end else
                        SetDimColumnSet(DimensionCode, DimFilter, SetOption::Same, RecordPosition, FirstColumn, LastColumn, NoOfColumns);
                end;
        end;

        if Abs(TmpSteps) <> NoOfColumns then
            NoOfColumns := Abs(TmpSteps);
    end;

    procedure DimToCaptions(var CaptionSet: array[32] of Text[80]; var MatrixRecords: array[32] of Record "Dimension Code Buffer"; DimensionCode: Code[20]; FirstColumn: Text; LastColumn: Text; var NumberOfColumns: Integer; ShowColumnName: Boolean; var CaptionRange: Text; DimensionValueFilter: Text)
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetRange(Code, FirstColumn, LastColumn);
        DimensionValue.FilterGroup(7);
        if DimensionValueFilter <> '' then
            DimensionValue.SetFilter(Code, DimensionValueFilter);
        DimensionValue.FilterGroup(0);

        i := 0;
        if DimensionValue.FindSet then
            repeat
                i := i + 1;
                MatrixRecords[i].Code := DimensionValue.Code;
                MatrixRecords[i].Name := DimensionValue.Name;
                MatrixRecords[i].Totaling := DimensionValue.Totaling;
                if ShowColumnName then
                    CaptionSet[i] := DimensionValue.Name
                else
                    CaptionSet[i] := DimensionValue.Code
            until (i = ArrayLen(CaptionSet)) or (DimensionValue.Next = 0);

        NumberOfColumns := i;

        if NumberOfColumns > 1 then
            CaptionRange := CopyStr(CaptionSet[1] + '..' + CaptionSet[NumberOfColumns], 1, MaxStrLen(CaptionRange))
        else
            CaptionRange := CaptionSet[1];
    end;

    procedure GenerateMatrixData(var RecRef: RecordRef; SetWanted: Option; MaximumSetLength: Integer; CaptionFieldNo: Integer; var RecordPosition: Text; var CaptionSet: array[32] of Text[80]; var CaptionRange: Text; var CurrSetLength: Integer)
    begin
        GenerateMatrixDataExtended(
          RecRef, SetWanted, MaximumSetLength, CaptionFieldNo, RecordPosition, CaptionSet, CaptionRange, CurrSetLength, 80);
    end;

    procedure GenerateMatrixDataExtended(var RecRef: RecordRef; SetWanted: Option; MaximumSetLength: Integer; CaptionFieldNo: Integer; var RecordPosition: Text; var CaptionSet: array[32] of Text; var CaptionRange: Text; var CurrSetLength: Integer; MaxCaptionLength: Integer)
    var
        Steps: Integer;
        Caption: Text;
    begin
        Clear(CaptionSet);
        CaptionRange := '';
        CurrSetLength := 0;

        if RecRef.IsEmpty then begin
            RecordPosition := '';
            exit;
        end;

        case SetWanted of
            SetOption::Initial:
                RecRef.FindFirst;
            SetOption::Previous:
                begin
                    RecRef.SetPosition(RecordPosition);
                    RecRef.Get(RecRef.RecordId);
                    Steps := RecRef.Next(-MaximumSetLength);
                    if not (Steps in [-MaximumSetLength, 0]) then
                        Error(Text001);
                end;
            SetOption::Same:
                begin
                    RecRef.SetPosition(RecordPosition);
                    RecRef.Get(RecRef.RecordId);
                end;
            SetOption::Next:
                begin
                    RecRef.SetPosition(RecordPosition);
                    RecRef.Get(RecRef.RecordId);
                    if not (RecRef.Next(MaximumSetLength) = MaximumSetLength) then begin
                        RecRef.SetPosition(RecordPosition);
                        RecRef.Get(RecRef.RecordId);
                    end;
                end;
            SetOption::PreviousColumn:
                begin
                    RecRef.SetPosition(RecordPosition);
                    RecRef.Get(RecRef.RecordId);
                    Steps := RecRef.Next(-1);
                    if not (Steps in [-1, 0]) then
                        Error(Text001);
                end;
            SetOption::NextColumn:
                begin
                    RecRef.SetPosition(RecordPosition);
                    RecRef.Get(RecRef.RecordId);
                    if not (RecRef.Next(1) = 1) then begin
                        RecRef.SetPosition(RecordPosition);
                        RecRef.Get(RecRef.RecordId);
                    end;
                end;
        end;

        RecordPosition := RecRef.GetPosition;

        repeat
            CurrSetLength := CurrSetLength + 1;
            Caption := Format(RecRef.Field(CaptionFieldNo).Value);
            if StrLen(Caption) <= MaxCaptionLength then
                CaptionSet[CurrSetLength] := CopyStr(Caption, 1, MaxCaptionLength)
            else
                CaptionSet[CurrSetLength] := CopyStr(Caption, 1, MaxCaptionLength - 3) + '...';
        until (CurrSetLength = MaximumSetLength) or (RecRef.Next <> 1);

        if CurrSetLength = 1 then
            CaptionRange := CaptionSet[1]
        else
            CaptionRange := CaptionSet[1] + '..' + CaptionSet[CurrSetLength];
    end;

    procedure GeneratePeriodMatrixData(SetWanted: Option; MaximumSetLength: Integer; UseNameForCaption: Boolean; PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; DateFilter: Text; var RecordPosition: Text; var CaptionSet: array[32] of Text[80]; var CaptionRange: Text; var CurrSetLength: Integer; var PeriodRecords: array[32] of Record Date temporary)
    var
        Calendar: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
        Steps: Integer;
    begin
        Clear(CaptionSet);
        CaptionRange := '';
        CurrSetLength := 0;
        Clear(PeriodRecords);
        Clear(Calendar);
        Clear(PeriodFormMgt);

        Calendar.SetFilter("Period Start", PeriodFormMgt.GetFullPeriodDateFilter(PeriodType, DateFilter));

        if not FindDate('-', Calendar, PeriodType, false) then begin
            RecordPosition := '';
            Error(Text003);
        end;

        case SetWanted of
            SetOption::Initial:
                begin
                    if (PeriodType = PeriodType::"Accounting Period") or (DateFilter <> '') then begin
                        FindDate('-', Calendar, PeriodType, true);
                    end else
                        Calendar."Period Start" := 0D;
                    FindDate('=><', Calendar, PeriodType, true);
                end;
            SetOption::Previous:
                begin
                    Calendar.SetPosition(RecordPosition);
                    FindDate('=', Calendar, PeriodType, true);
                    Steps := PeriodFormMgt.NextDate(-MaximumSetLength, Calendar, PeriodType);
                    if not (Steps in [-MaximumSetLength, 0]) then
                        Error(Text001);
                end;
            SetOption::PreviousColumn:
                begin
                    Calendar.SetPosition(RecordPosition);
                    FindDate('=', Calendar, PeriodType, true);
                    Steps := PeriodFormMgt.NextDate(-1, Calendar, PeriodType);
                    if not (Steps in [-1, 0]) then
                        Error(Text001);
                end;
            SetOption::NextColumn:
                begin
                    Calendar.SetPosition(RecordPosition);
                    FindDate('=', Calendar, PeriodType, true);
                    if not (PeriodFormMgt.NextDate(1, Calendar, PeriodType) = 1) then begin
                        Calendar.SetPosition(RecordPosition);
                        FindDate('=', Calendar, PeriodType, true);
                    end;
                end;
            SetOption::Same:
                begin
                    Calendar.SetPosition(RecordPosition);
                    FindDate('=', Calendar, PeriodType, true)
                end;
            SetOption::Next:
                begin
                    Calendar.SetPosition(RecordPosition);
                    FindDate('=', Calendar, PeriodType, true);
                    if not (PeriodFormMgt.NextDate(MaximumSetLength, Calendar, PeriodType) = MaximumSetLength) then begin
                        Calendar.SetPosition(RecordPosition);
                        FindDate('=', Calendar, PeriodType, true);
                    end;
                end;
        end;

        RecordPosition := Calendar.GetPosition;

        repeat
            CurrSetLength := CurrSetLength + 1;
            if UseNameForCaption then
                CaptionSet[CurrSetLength] := Format(Calendar."Period Name")
            else
                CaptionSet[CurrSetLength] := PeriodFormMgt.CreatePeriodFormat(PeriodType, Calendar."Period Start");
            PeriodRecords[CurrSetLength].Copy(Calendar);
        until (CurrSetLength = MaximumSetLength) or (PeriodFormMgt.NextDate(1, Calendar, PeriodType) <> 1);

        if CurrSetLength = 1 then
            CaptionRange := CaptionSet[1]
        else
            CaptionRange := CaptionSet[1] + '..' + CaptionSet[CurrSetLength];

        AdjustPeriodWithDateFilter(DateFilter, PeriodRecords[1]."Period Start",
          PeriodRecords[CurrSetLength]."Period End");
    end;

    local procedure FindDate(SearchString: Text[3]; var Calendar: Record Date; PeriodType: Option; ErrorWhenNotFound: Boolean): Boolean
    var
        PeriodFormMgt: Codeunit PeriodFormManagement;
        Found: Boolean;
    begin
        Clear(PeriodFormMgt);
        Found := PeriodFormMgt.FindDate(SearchString, Calendar, PeriodType);
        if ErrorWhenNotFound and not Found then
            Error(Text002);
        exit(Found);
    end;

    procedure SetIndentation(var TextString: Text[1024]; Indentation: Integer)
    var
        Substr: Text[1024];
    begin
        Substr := PadStr(Substr, Indentation * 2, ' ');
        TextString := Substr + TextString;
    end;

    procedure GetPKRange(var RecRef: RecordRef; KeyFieldNo: Integer; RecordPosition: Text; CurrSetLength: Integer) PKRange: Text[100]
    var
        FieldRef: FieldRef;
        CurFilter: Text;
        RecCount: Integer;
    begin
        RecRef.SetPosition(RecordPosition);
        RecRef.Get(RecRef.RecordId);
        PKRange := Format(RecRef.Field(KeyFieldNo).Value);
        if CurrSetLength = 1 then
            exit(PKRange);
        RecRef.Next(CurrSetLength);
        PKRange := PKRange + '..' + Format(RecRef.Field(KeyFieldNo).Value);
        FieldRef := RecRef.Field(KeyFieldNo);
        CurFilter := FieldRef.GetFilter;
        if CurFilter = '' then
            exit(PKRange);
        FieldRef.SetFilter(PKRange);
        RecCount := RecRef.Count();
        FieldRef.SetFilter(CurFilter);
        if CurrSetLength = RecCount then
            exit(PKRange);
        exit('');
    end;

    procedure GenerateDimColumnCaption(DimensionCode: Code[20]; DimFilter: Text; SetWanted: Option; var RecordPosition: Text; FirstColumn: Text; LastColumn: Text; var CaptionSet: array[32] of Text[80]; var DimensionCodeBuffer: array[32] of Record "Dimension Code Buffer"; var NumberOfColumns: Integer; ShowColumnName: Boolean; var CaptionRange: Text)
    begin
        SetDimColumnSet(
          DimensionCode, DimFilter, SetWanted, RecordPosition, FirstColumn, LastColumn, NumberOfColumns);
        DimToCaptions(
          CaptionSet, DimensionCodeBuffer, DimensionCode,
          FirstColumn, LastColumn, NumberOfColumns, ShowColumnName, CaptionRange, DimFilter);
    end;

    local procedure AdjustPeriodWithDateFilter(DateFilter: Text; var PeriodStartDate: Date; var PeriodEndDate: Date)
    var
        Period: Record Date;
    begin
        if DateFilter <> '' then begin
            Period.SetFilter("Period End", DateFilter);
            if Period.GetRangeMax("Period End") < PeriodEndDate then
                PeriodEndDate := Period.GetRangeMax("Period End");
            Period.Reset();
            Period.SetFilter("Period Start", DateFilter);
            if Period.GetRangeMin("Period Start") > PeriodStartDate then
                PeriodStartDate := Period.GetRangeMin("Period Start");
        end;
    end;

    procedure RoundValue(Value: Decimal; RoundingFactor: Option "None","1","1000","1000000"): Decimal
    begin
        if Value <> 0 then
            case RoundingFactor of
                RoundingFactor::"1":
                    exit(Round(Value, 1));
                RoundingFactor::"1000":
                    exit(Round(Value / 1000, 0.1));
                RoundingFactor::"1000000":
                    exit(Round(Value / 1000000, 0.1));
            end;

        exit(Value);
    end;

    procedure FormatValue(Value: Decimal; RoundingFactor: Option "None","1","1000","1000000"; AddCurrency: Boolean): Text[30]
    begin
        Value := RoundValue(Value, RoundingFactor);

        if Value <> 0 then
            exit(Format(Value, 0, GetFormatString(RoundingFactor, AddCurrency)));
    end;

    local procedure ReadNormalDecimalFormat(AddCurrency: Boolean): Text
    var
        Currency: Record Currency;
    begin
        if not GLSetupRead then begin
            GeneralLedgerSetup.Get();
            GLSetupRead := true;
            if AddCurrency then
                GeneralLedgerSetup.TestField("Additional Reporting Currency");
        end;

        if AddCurrency and
           Currency.Get(GeneralLedgerSetup."Additional Reporting Currency")
        then
            exit(Currency."Amount Decimal Places");

        exit(GeneralLedgerSetup."Amount Decimal Places");
    end;

    procedure GetFormatString(RoundingFactor: Option "None","1","1000","1000000"; AddCurrency: Boolean): Text
    var
        AmountDecimal: Text;
    begin
        case RoundingFactor of
            RoundingFactor::None:
                AmountDecimal := ReadNormalDecimalFormat(AddCurrency);
            RoundingFactor::"1":
                AmountDecimal := Format(0);
            RoundingFactor::"1000", RoundingFactor::"1000000":
                AmountDecimal := Format(1);
        end;
        exit(StrSubstNo(RoundingFormatTxt, AmountDecimal));
    end;
}

