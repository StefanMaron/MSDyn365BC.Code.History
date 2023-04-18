codeunit 952 "Time Sheet Chart Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        Text001: Label 'Time Sheet Resource';
        MeasureType: Option Open,Submitted,Rejected,Approved,Scheduled,Posted,"Not Posted",Resource,Job,Service,Absence,"Assembly Order";

    procedure OnOpenPage(var TimeSheetChartSetup: Record "Time Sheet Chart Setup")
    begin
        with TimeSheetChartSetup do
            if not Get(UserId) then begin
                "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
                "Starting Date" := TimeSheetMgt.FindNearestTimeSheetStartDate(WorkDate());
                Insert();
            end;
    end;

    procedure UpdateData(var BusChartBuf: Record "Business Chart Buffer")
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        BusChartMapColumn: Record "Business Chart Map";
        BusChartMapMeasure: Record "Business Chart Map";
    begin
        TimeSheetChartSetup.Get(UserId);

        with BusChartBuf do begin
            Initialize();
            SetXAxis(Text001, "Data Type"::String);

            AddColumns(BusChartBuf);
            AddMeasures(BusChartBuf, TimeSheetChartSetup);

            if FindFirstMeasure(BusChartMapMeasure) then
                repeat
                    if FindFirstColumn(BusChartMapColumn) then
                        repeat
                            SetValue(
                              BusChartMapMeasure.Name,
                              BusChartMapColumn.Index,
                              CalcAmount(
                                TimeSheetChartSetup,
                                BusChartMapColumn.Name,
                                TimeSheetChartSetup.MeasureIndex2MeasureType(BusChartMapMeasure.Index)));
                        until not NextColumn(BusChartMapColumn);

                until not NextMeasure(BusChartMapMeasure);
        end;
    end;

    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        ResCapacityEntry: Record "Res. Capacity Entry";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetPostingEntry: Record "Time Sheet Posting Entry";
        Value: Variant;
        ResourceNo: Code[20];
        CurrMeasureType: Integer;
    begin
        BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", Value);
        ResourceNo := Format(Value);
        TimeSheetChartSetup.Get(UserId);

        CurrMeasureType := TimeSheetChartSetup.MeasureIndex2MeasureType(BusChartBuf."Drill-Down Measure Index");
        if CurrMeasureType = MeasureType::Scheduled then begin
            ResCapacityEntry.SetRange("Resource No.", ResourceNo);
            ResCapacityEntry.SetRange(Date, TimeSheetChartSetup."Starting Date", TimeSheetChartSetup.GetEndingDate());
            PAGE.Run(PAGE::"Res. Capacity Entries", ResCapacityEntry);
        end else begin
            TimeSheetHeader.SetRange("Starting Date", TimeSheetChartSetup."Starting Date");
            TimeSheetHeader.SetRange("Resource No.", ResourceNo);
            if TimeSheetHeader.FindFirst() then
                if CurrMeasureType = MeasureType::Posted then begin
                    TimeSheetPostingEntry.FilterGroup(2);
                    TimeSheetPostingEntry.SetRange("Time Sheet No.", TimeSheetHeader."No.");
                    TimeSheetPostingEntry.FilterGroup(0);
                    PAGE.Run(PAGE::"Time Sheet Posting Entries", TimeSheetPostingEntry);
                end else begin
                    TimeSheetMgt.SetTimeSheetNo(TimeSheetHeader."No.", TimeSheetLine);
                    case TimeSheetChartSetup."Show by" of
                        TimeSheetChartSetup."Show by"::Status:
                            TimeSheetLine.SetRange(Status, CurrMeasureType);
                        TimeSheetChartSetup."Show by"::Type:
                            TimeSheetLine.SetRange(Type, BusChartBuf."Drill-Down Measure Index" + 1);
                    end;
                    PAGE.Run(PAGE::"Manager Time Sheet", TimeSheetLine);
                end;
        end;
    end;

    local procedure AddColumns(var BusChartBuf: Record "Business Chart Buffer")
    var
        UserSetup: Record "User Setup";
        Resource: Record Resource;
    begin
        if not UserSetup.Get(UserId) then
            exit;

        Resource.SetRange("Use Time Sheet", true);
        if not UserSetup."Time Sheet Admin." then
            Resource.SetRange("Time Sheet Approver User ID", UserId);
        OnAddColumnsOnAfterSetFilters(Resource);
        if Resource.FindSet() then
            repeat
                BusChartBuf.AddColumn(Resource."No.");
            until Resource.Next() = 0;
    end;

    local procedure AddMeasures(var BusChartBuf: Record "Business Chart Buffer"; TimeSheetChartSetup: Record "Time Sheet Chart Setup")
    begin
        with BusChartBuf do begin
            case TimeSheetChartSetup."Show by" of
                TimeSheetChartSetup."Show by"::Status:
                    begin
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::Open), '', "Chart Type"::StackedColumn);
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::Submitted), '', "Chart Type"::StackedColumn);
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::Rejected), '', "Chart Type"::StackedColumn);
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::Approved), '', "Chart Type"::StackedColumn);
                    end;
                TimeSheetChartSetup."Show by"::Type:
                    begin
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::Resource), '', "Chart Type"::StackedColumn);
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::Job), '', "Chart Type"::StackedColumn);
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::Service), '', "Chart Type"::StackedColumn);
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::Absence), '', "Chart Type"::StackedColumn);
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::"Assembly Order"), '', "Chart Type"::StackedColumn);
                    end;
                TimeSheetChartSetup."Show by"::Posted:
                    begin
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::Posted), '', "Chart Type"::StackedColumn);
                        AddDecimalMeasure(GetMeasureCaption(MeasureType::"Not Posted"), '', "Chart Type"::StackedColumn);
                    end;
            end;
            AddDecimalMeasure(GetMeasureCaption(MeasureType::Scheduled), '', "Chart Type"::Point);
        end;
    end;

    procedure CalcAmount(TimeSheetChartSetup: Record "Time Sheet Chart Setup"; ResourceNo: Code[249]; MType: Integer): Decimal
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetPostingEntry: Record "Time Sheet Posting Entry";
    begin
        if MType = MeasureType::Scheduled then begin
            Resource.Get(ResourceNo);
            Resource.SetRange("Date Filter", TimeSheetChartSetup."Starting Date", TimeSheetChartSetup.GetEndingDate());
            Resource.CalcFields(Capacity);
            exit(Resource.Capacity);
        end;

        TimeSheetHeader.SetRange("Starting Date", TimeSheetChartSetup."Starting Date");
        TimeSheetHeader.SetRange("Resource No.", ResourceNo);
        if not TimeSheetHeader.FindFirst() then
            exit(0);

        case TimeSheetChartSetup."Show by" of
            TimeSheetChartSetup."Show by"::Status:
                begin
                    // status option is the same with MType here
                    TimeSheetHeader.SetRange("Status Filter", MType);
                    TimeSheetHeader.CalcFields(Quantity);
                    exit(TimeSheetHeader.Quantity);
                end;
            TimeSheetChartSetup."Show by"::Type:
                begin
                    TimeSheetHeader.SetRange("Type Filter", MType - 6);
                    TimeSheetHeader.CalcFields(Quantity);
                    exit(TimeSheetHeader.Quantity);
                end;
            TimeSheetChartSetup."Show by"::Posted:
                begin
                    TimeSheetPostingEntry.SetCurrentKey("Time Sheet No.", "Time Sheet Line No.");
                    TimeSheetPostingEntry.SetRange("Time Sheet No.", TimeSheetHeader."No.");
                    TimeSheetPostingEntry.CalcSums(Quantity);
                    TimeSheetHeader.CalcFields(Quantity);
                    case MType of
                        MeasureType::Posted:
                            exit(TimeSheetPostingEntry.Quantity);
                        MeasureType::"Not Posted":
                            exit(TimeSheetHeader.Quantity - TimeSheetPostingEntry.Quantity);
                    end;
                end;
        end;
    end;

    procedure GetMeasureCaption(Type: Option): Text
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
    begin
        TimeSheetChartSetup.Init();
        TimeSheetChartSetup."Measure Type" := Type;
        exit(Format(TimeSheetChartSetup."Measure Type"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddColumnsOnAfterSetFilters(var Resource: Record Resource)
    begin
    end;
}

