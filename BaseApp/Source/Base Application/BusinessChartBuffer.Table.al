table 485 "Business Chart Buffer"
{
    Caption = 'Business Chart Buffer';
    ReplicateData = false;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Chart Type"; Option)
        {
            Caption = 'Chart Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Point,,Bubble,Line,,StepLine,,,,,Column,StackedColumn,StackedColumn100,Area,,StackedArea,StackedArea100,Pie,Doughnut,,,Range,,,,Radar,,,,,,,,Funnel';
            OptionMembers = Point,,Bubble,Line,,StepLine,,,,,Column,StackedColumn,StackedColumn100,"Area",,StackedArea,StackedArea100,Pie,Doughnut,,,Range,,,,Radar,,,,,,,,Funnel;
        }
        field(3; "Data Type"; Option)
        {
            Caption = 'Data Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'String,Integer,Decimal,DateTime';
            OptionMembers = String,"Integer",Decimal,DateTime;
        }
        field(4; XML; BLOB)
        {
            Caption = 'XML';
            DataClassification = SystemMetadata;
        }
        field(5; "Drill-Down X Index"; Integer)
        {
            Caption = 'Drill-Down X Index';
            DataClassification = SystemMetadata;
        }
        field(6; "Drill-Down Y Value"; Decimal)
        {
            Caption = 'Drill-Down Y Value';
            DataClassification = SystemMetadata;
        }
        field(7; "Drill-Down Measure Index"; Integer)
        {
            Caption = 'Drill-Down Measure Index';
            DataClassification = SystemMetadata;
        }
        field(8; "Period Length"; Option)
        {
            Caption = 'Period Length';
            DataClassification = SystemMetadata;
            OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period,None';
            OptionMembers = Day,Week,Month,Quarter,Year,"Accounting Period","None";
        }
        field(9; "Period Filter Start Date"; Date)
        {
            Caption = 'Period Filter Start Date';
            DataClassification = SystemMetadata;
        }
        field(10; "Period Filter End Date"; Date)
        {
            Caption = 'Period Filter End Date';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Error(Text002, TableCaption);
    end;

    var
        TempBusChartMapToColumn: Record "Business Chart Map" temporary;
        TempBusChartMapToMeasure: Record "Business Chart Map" temporary;
        dotNetChartData: DotNet BusinessChartData;
        dotNetDataTable: DotNet DataTable;
        IsInitialized: Boolean;
        Text001: Label 'Data Type must be Integer or Decimal for Measure %1.';
        Text002: Label 'You cannot insert into table %1.';
        Text003: Label 'You cannot add more than %1 measures.';

    procedure Initialize()
    var
        dotNetCultureInfo: DotNet CultureInfo;
    begin
        if not IsInitialized then begin
            dotNetDataTable := dotNetDataTable.DataTable('DataTable');
            dotNetCultureInfo := dotNetCultureInfo.CultureInfo(WindowsLanguage);
            dotNetDataTable.Locale := dotNetCultureInfo.InvariantCulture;

            dotNetChartData := dotNetChartData.BusinessChartData;
            IsInitialized := true;
        end;
        dotNetDataTable.Clear;
        dotNetDataTable.Columns.Clear;
        dotNetChartData.ClearMeasures;
        ClearMap(TempBusChartMapToColumn);
        ClearMap(TempBusChartMapToMeasure);
    end;

    local procedure ClearMap(var BusChartMap: Record "Business Chart Map")
    begin
        BusChartMap.Reset();
        BusChartMap.DeleteAll();
    end;

    procedure SetChartCondensed(Condensed: Boolean)
    begin
        dotNetChartData.ShowChartCondensed := Condensed;
    end;

    procedure SetXAxis(Caption: Text; Type: Option)
    begin
        AddDataColumn(Caption, Type);
        dotNetChartData.XDimension := Caption;
    end;

    procedure SetPeriodXAxis()
    var
        DataType: Option;
    begin
        if "Period Length" = "Period Length"::Day then
            DataType := "Data Type"::DateTime
        else
            DataType := "Data Type"::String;
        SetXAxis(Format("Period Length"), DataType);
    end;

    procedure GetXCaption(): Text
    begin
        exit(dotNetChartData.XDimension);
    end;

    procedure AddMeasure(Caption: Text; Value: Variant; ValueType: Option; ChartType: Integer)
    var
        DotNetChartType: DotNet DataMeasureType;
    begin
        "Data Type" := ValueType;
        if not ("Data Type" in ["Data Type"::Integer, "Data Type"::Decimal]) then
            Error(Text001, Caption);
        AddDataColumn(Caption, ValueType);
        DotNetChartType := ChartType;
        dotNetChartData.AddMeasure(Caption, DotNetChartType);
        TempBusChartMapToMeasure.Add(
          CopyStr(Caption, 1, MaxStrLen(TempBusChartMapToMeasure.Name)), Value);
    end;

    procedure GetMaxNumberOfMeasures(): Integer
    var
        MaximumNumberOfColoursInChart: Integer;
    begin
        MaximumNumberOfColoursInChart := 6;
        exit(MaximumNumberOfColoursInChart);
    end;

    procedure RaiseErrorMaxNumberOfMeasuresExceeded()
    begin
        Error(Text003, GetMaxNumberOfMeasures);
    end;

    procedure AddColumn(Value: Variant)
    var
        Caption: Text;
    begin
        ConvertDateToDateTime(Value);
        Caption := Format(Value, 0, 9);
        AddColumnWithCaption(Value, Caption);
    end;

    procedure AddPeriods(FromDate: Date; ToDate: Date)
    var
        ColumnNo: Integer;
        NumberOfPeriods: Integer;
    begin
        NumberOfPeriods := CalcNumberOfPeriods(FromDate, ToDate);
        for ColumnNo := 1 to NumberOfPeriods do begin
            ToDate := CalcToDate(FromDate);
            AddPeriodColumn(ToDate);
            FromDate := CalcDate('<1D>', ToDate);
        end;
    end;

    procedure AddPeriodColumn(Value: Variant)
    var
        Caption: Text;
    begin
        ConvertDateToDateTime(Value);
        Caption := GetPeriodCaption(Value);
        if "Period Length" = "Period Length"::Day then
            AddColumnWithCaption(Value, Format(Value, 0, 9))
        else
            AddColumnWithCaption(Value, Caption);
    end;

    local procedure AddColumnWithCaption(Value: Variant; Caption: Text)
    var
        dotNetDataRow: DotNet DataRow;
    begin
        dotNetDataRow := dotNetDataTable.NewRow;
        dotNetDataRow.Item(GetXCaption, Caption);
        dotNetDataTable.Rows.Add(dotNetDataRow);
        TempBusChartMapToColumn.Add(Caption, Value);
    end;

    local procedure ConvertDateToDateTime(var Value: Variant)
    begin
        if IsXAxisDateTime and Value.IsDate then
            Value := CreateDateTime(Value, 120000T);
    end;

    local procedure AddDataColumn(Caption: Text; ValueType: Option)
    var
        dotNetDataColumn: DotNet DataColumn;
        dotNetSystemType: DotNet Type;
    begin
        dotNetDataColumn := dotNetDataColumn.DataColumn(Caption);
        dotNetDataColumn.Caption := Caption;
        dotNetDataColumn.ColumnName(Caption);
        dotNetDataColumn.DataType(dotNetSystemType.GetType(GetSystemTypeName(ValueType)));
        dotNetDataTable.Columns.Add(dotNetDataColumn);
    end;

    local procedure GetSystemTypeName(Type: Option): Text
    begin
        case Type of
            "Data Type"::String:
                exit('System.String');
            "Data Type"::Integer:
                exit('System.Int32');
            "Data Type"::Decimal:
                exit('System.Decimal');
            "Data Type"::DateTime:
                exit('System.DateTime');
        end;
    end;

    procedure SetValue(MeasureName: Text; XAxisIndex: Integer; Value: Variant)
    var
        dotNetDataRow: DotNet DataRow;
    begin
        dotNetDataRow := dotNetDataTable.Rows.Item(XAxisIndex);
        dotNetDataRow.Item(MeasureName, Value);
    end;

    procedure SetValueByIndex(MeasureIndex: Integer; XAxisIndex: Integer; Value: Variant)
    var
        dotNetDataRow: DotNet DataRow;
    begin
        dotNetDataRow := dotNetDataTable.Rows.Item(XAxisIndex);
        dotNetDataRow.Item(TempBusChartMapToMeasure.GetName(MeasureIndex), Value);
    end;

    procedure FindFirstMeasure(var BusChartMap: Record "Business Chart Map") Result: Boolean
    begin
        TempBusChartMapToMeasure.Reset();
        Result := TempBusChartMapToMeasure.FindSet;
        BusChartMap := TempBusChartMapToMeasure;
    end;

    procedure NextMeasure(var BusChartMap: Record "Business Chart Map") Result: Boolean
    begin
        Result := TempBusChartMapToMeasure.Next <> 0;
        BusChartMap := TempBusChartMapToMeasure;
    end;

    procedure FindFirstColumn(var BusChartMap: Record "Business Chart Map") Result: Boolean
    begin
        TempBusChartMapToColumn.Reset();
        Result := TempBusChartMapToColumn.FindSet;
        BusChartMap := TempBusChartMapToColumn;
    end;

    procedure FindMidColumn(var BusChartMap: Record "Business Chart Map") Result: Boolean
    var
        MidColumnIndex: Integer;
    begin
        TempBusChartMapToColumn.Reset();
        TempBusChartMapToColumn.FindLast;
        MidColumnIndex := -Round(TempBusChartMapToColumn.Count div 2);
        Result := MidColumnIndex = TempBusChartMapToColumn.Next(MidColumnIndex);
        BusChartMap := TempBusChartMapToColumn;
    end;

    procedure NextColumn(var BusChartMap: Record "Business Chart Map") Result: Boolean
    begin
        Result := TempBusChartMapToColumn.Next <> 0;
        BusChartMap := TempBusChartMapToColumn;
    end;

    procedure GetValue(MeasureName: Text; XAxisIndex: Integer; var Value: Variant)
    var
        dotNetDataRow: DotNet DataRow;
    begin
        dotNetDataRow := dotNetDataTable.Rows.Item(XAxisIndex);
        Value := dotNetDataRow.Item(MeasureName);
    end;

    procedure GetXValue(XAxisIndex: Integer; var Value: Variant)
    begin
        GetValue(GetXCaption, XAxisIndex, Value);
    end;

    procedure GetXValueAsDate(XIndex: Integer): Date
    var
        Value: Variant;
    begin
        if IsXAxisDateTime then begin
            GetXValue(XIndex, Value);
            exit(Variant2Date(Value));
        end;
        TempBusChartMapToColumn.Get(XIndex);
        exit(TempBusChartMapToColumn.GetValueAsDate);
    end;

    procedure GetMeasureValueString(MeasureIndex: Integer): Text
    begin
        exit(TempBusChartMapToMeasure.GetValueString(MeasureIndex));
    end;

    procedure GetMeasureName(MeasureIndex: Integer): Text
    begin
        exit(TempBusChartMapToMeasure.GetName(MeasureIndex));
    end;

    procedure GetCurrMeasureValueString(): Text
    begin
        exit(TempBusChartMapToMeasure.GetValueString("Drill-Down Measure Index"));
    end;

    procedure Update(dotNetChartAddIn: DotNet BusinessChartAddIn)
    begin
        dotNetChartData.DataTable := dotNetDataTable;
        dotNetChartAddIn.Update(dotNetChartData);
    end;

    [Scope('OnPrem')]
    procedure SetDrillDownIndexes(dotNetPoint: DotNet BusinessChartDataPoint)
    begin
        SetDrillDownIndexesByCoordinate(dotNetPoint.Measures.GetValue(0), dotNetPoint.XValueString, dotNetPoint.YValues.GetValue(0));
    end;

    local procedure GetDateString(XValueString: Text[249]): Text[249]
    var
        Days: Decimal;
        DateTime: DateTime;
    begin
        if Evaluate(Days, XValueString, 9) then begin
            DateTime := CreateDateTime(DMY2Date(30, 12, 1899) + Round(Days, 1, '<'), 120000T);
            exit(Format(DateTime, 0, 9));
        end;
        exit(XValueString);
    end;

    procedure IsXAxisDateTime(): Boolean
    begin
        exit(Format(dotNetDataTable.Columns.Item(0).DataType) = 'System.DateTime')
    end;

    [Scope('OnPrem')]
    procedure WriteToXML(var XMLDoc: DotNet XmlDocument)
    var
        XMLElement: DotNet XmlElement;
        OutStream: OutStream;
        InStream: InStream;
        XMLLine: Text[80];
        XMLText: Text;
    begin
        XML.CreateOutStream(OutStream);
        dotNetDataTable.WriteXml(OutStream);
        XML.CreateInStream(InStream);
        while not InStream.EOS do begin
            InStream.ReadText(XMLLine);
            XMLText := XMLText + XMLLine;
        end;
        XMLElement := XMLDoc.CreateElement('DataTable', 'test', '');
        XMLElement.InnerXml(XMLText);
        XMLDoc.AppendChild(XMLElement);
    end;

    procedure CalcFromDate(Date: Date): Date
    begin
        exit(CalcPeriodDate(Date, true));
    end;

    procedure CalcToDate(Date: Date): Date
    begin
        exit(CalcPeriodDate(Date, false));
    end;

    local procedure CalcPeriodDate(Date: Date; CalcStartDate: Boolean): Date
    var
        Modificator: Text[1];
    begin
        if Date = 0D then
            exit(Date);

        case "Period Length" of
            "Period Length"::Day:
                exit(Date);
            "Period Length"::Week,
            "Period Length"::Month,
            "Period Length"::Quarter,
            "Period Length"::Year:
                begin
                    if CalcStartDate then
                        Modificator := '-';
                    exit(CalcDate(StrSubstNo('<%1C%2>', Modificator, GetPeriodLength), Date));
                end;
        end;
    end;

    procedure CalcNumberOfPeriods(FromDate: Date; ToDate: Date): Integer
    var
        NumberOfPeriods: Integer;
    begin
        if FromDate = ToDate then
            exit(1);
        if ToDate < FromDate then
            SwapDates(FromDate, ToDate);

        case "Period Length" of
            "Period Length"::Day:
                NumberOfPeriods := ToDate - FromDate;
            "Period Length"::Week:
                NumberOfPeriods := (CalcDate('<-CW>', ToDate) - CalcDate('<-CW>', FromDate)) div 7;
            "Period Length"::Month:
                NumberOfPeriods := Date2DMY(ToDate, 2) - Date2DMY(FromDate, 2) + GetNumberOfYears(FromDate, ToDate) * 12;
            "Period Length"::Quarter:
                NumberOfPeriods := GetQuarterIndex(ToDate) - GetQuarterIndex(FromDate) + GetNumberOfYears(FromDate, ToDate) * 4;
            "Period Length"::Year:
                NumberOfPeriods := GetNumberOfYears(FromDate, ToDate);
        end;
        exit(NumberOfPeriods + 1);
    end;

    local procedure SwapDates(var FromDate: Date; var ToDate: Date)
    var
        Date: Date;
    begin
        Date := FromDate;
        FromDate := ToDate;
        ToDate := Date;
    end;

    local procedure GetNumberOfYears(FromDate: Date; ToDate: Date): Integer
    begin
        exit(Date2DMY(ToDate, 3) - Date2DMY(FromDate, 3));
    end;

    local procedure GetQuarterIndex(Date: Date): Integer
    begin
        exit((Date2DMY(Date, 2) - 1) div 3 + 1);
    end;

    procedure GetPeriodLength(): Text[1]
    begin
        case "Period Length" of
            "Period Length"::Day:
                exit('D');
            "Period Length"::Week:
                exit('W');
            "Period Length"::Month:
                exit('M');
            "Period Length"::Quarter:
                exit('Q');
            "Period Length"::Year:
                exit('Y');
        end;
    end;

    procedure GetPeriodCaption(Date: Variant): Text
    var
        PeriodFormManagement: Codeunit PeriodFormManagement;
    begin
        if Date.IsDateTime or Date.IsDate then
            exit(PeriodFormManagement.CreatePeriodFormat("Period Length", Date));
        exit(Format(Date, 0, 9));
    end;

    procedure GetPeriodFromMapColumn(ColumnIndex: Integer; var FromDate: Date; var ToDate: Date)
    begin
        ToDate := GetXValueAsDate(ColumnIndex);
        FromDate := CalcFromDate(ToDate);
    end;

    procedure InitializePeriodFilter(StartDate: Date; EndDate: Date)
    begin
        "Period Filter Start Date" := StartDate;
        "Period Filter End Date" := EndDate;
    end;

    procedure RecalculatePeriodFilter(var StartDate: Date; var EndDate: Date; MovePeriod: Option " ",Next,Previous)
    var
        Calendar: Record Date;
        PeriodFormMgt: Codeunit PeriodFormManagement;
        SearchText: Text[3];
    begin
        if StartDate <> 0D then begin
            Calendar.SetFilter("Period Start", '%1..%2', StartDate, EndDate);
            if not PeriodFormMgt.FindDate('+', Calendar, "Period Length") then
                PeriodFormMgt.FindDate('+', Calendar, Calendar."Period Type"::Date);
            Calendar.SetRange("Period Start");
        end;

        case MovePeriod of
            MovePeriod::Next:
                SearchText := '>=';
            MovePeriod::Previous:
                SearchText := '<=';
            else
                SearchText := '';
        end;

        PeriodFormMgt.FindDate(SearchText, Calendar, "Period Length");

        StartDate := Calendar."Period Start";
        EndDate := Calendar."Period End";
    end;

    procedure SetDrillDownIndexesByCoordinate(MeasureName: Text[249]; XValueString: Text[249]; YValue: Decimal)
    begin
        "Drill-Down Measure Index" := TempBusChartMapToMeasure.GetIndex(MeasureName);

        if IsXAxisDateTime then
            XValueString := GetDateString(XValueString);

        "Drill-Down X Index" := TempBusChartMapToColumn.GetIndex(XValueString);
        "Drill-Down Y Value" := YValue;
    end;
}

