page 99000888 "Work Center Load Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Load Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period Start"; "Period Start")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the starting date for the evaluation of the load on a work center.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
                field(Capacity; Capacity)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of work that can be done in a specified time period at this work center group. ';

                    trigger OnDrillDown()
                    var
                        CalendarEntry: Record "Calendar Entry";
                    begin
                        CurrPage.Update(true);
                        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Work Center");
                        CalendarEntry.SetRange("No.", WorkCenter."No.");
                        CalendarEntry.SetFilter(Date, WorkCenter.GetFilter("Date Filter"));
                        PAGE.Run(0, CalendarEntry);
                    end;
                }
                field(AllocatedQty; "Allocated Qty.")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Allocated Qty.';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of capacity that is needed to produce a desired output in a given time period. ';

                    trigger OnDrillDown()
                    var
                        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
                    begin
                        CurrPage.Update(true);
                        ProdOrderCapNeed.SetCurrentKey("Work Center No.", Date);
                        ProdOrderCapNeed.SetRange("Requested Only", false);
                        ProdOrderCapNeed.SetRange("Work Center No.", WorkCenter."No.");
                        ProdOrderCapNeed.SetFilter(Date, WorkCenter.GetFilter("Date Filter"));
                        PAGE.Run(0, ProdOrderCapNeed);
                    end;
                }
                field(CapacityAvailable; "Availability After Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Availability After Orders';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the available capacity of this resource.';
                }
                field(CapacityEfficiency; Load)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Load';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of the required number of times that all the planned and actual orders are run on the work center in a specified period.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if DateRec.Get("Period Type", "Period Start") then;
        CalcLine();
    end;

    trigger OnFindRecord(Which: Text) FoundDate: Boolean
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        FoundDate := PeriodFormLinesMgt.FindDate(VariantRec, DateRec, Which, PeriodType);
        Rec := VariantRec;
    end;

    trigger OnNextRecord(Steps: Integer) ResultSteps: Integer
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ResultSteps := PeriodFormLinesMgt.NextDate(VariantRec, DateRec, Steps, PeriodType);
        Rec := VariantRec;
    end;

    trigger OnOpenPage()
    begin
        Reset();
    end;

    var
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    protected var
        WorkCenter: Record "Work Center";

    procedure Set(var NewWorkCenter: Record "Work Center"; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        WorkCenter.Copy(NewWorkCenter);
        DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);

        OnSet(WorkCenter, PeriodType, AmountType);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            WorkCenter.SetRange("Date Filter", "Period Start", "Period End")
        else
            WorkCenter.SetRange("Date Filter", 0D, "Period End");
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        WorkCenter.CalcFields("Capacity (Effective)", "Prod. Order Need (Qty.)");
        Capacity := WorkCenter."Capacity (Effective)";
        "Allocated Qty." := WorkCenter."Prod. Order Need (Qty.)";
        "Availability After Orders" := WorkCenter."Capacity (Effective)" - WorkCenter."Prod. Order Need (Qty.)";
        if WorkCenter."Capacity (Effective)" <> 0 then
            Load := Round(WorkCenter."Prod. Order Need (Qty.)" / WorkCenter."Capacity (Effective)" * 100, 0.1)
        else
            Load := 0;

        OnAfterCalcLine(WorkCenter, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var WorkCenter: Record "Work Center"; var LoadBuffer: Record "Load Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSet(var WorkCenter: Record "Work Center"; PeriodType: Option; AmountType: Option)
    begin
    end;
}

