page 6007 "Res. Availability Lines (SM)"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Res. Availability Buffer";
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies a series of dates according to the selected time interval.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
                field(Capacity; Capacity)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total capacity for the corresponding time period.';

                    trigger OnDrillDown()
                    var
                        ResCapacityEntry: Record "Res. Capacity Entry";
                        IsHandled: Boolean;
                    begin
                        ResCapacityEntry.SetRange("Resource No.", Res."No.");
                        ResCapacityEntry.SetRange(Date, "Period Start", "Period End");
                        IsHandled := false;
                        OnAfterCapacityOnDrillDown(ResCapacityEntry, IsHandled);
                        if IsHandled then
                            exit;

                        PAGE.RunModal(0, ResCapacityEntry);
                    end;
                }
                field("Res.""Qty. on Service Order"""; "Qty. on Service Order")
                {
                    ApplicationArea = Service;
                    Caption = 'Qty. on Service Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are allocated to service orders, meaning listed on outstanding service order lines.';

                    trigger OnDrillDown()
                    begin
                        ServOrderAlloc.SetCurrentKey("Resource No.", "Document Type", "Allocation Date", Status, Posted);
                        ServOrderAlloc.SetRange("Resource No.", Res."No.");
                        ServOrderAlloc.SetFilter("Document Type", '%1|%2', ServOrderAlloc."Document Type"::Quote, ServOrderAlloc."Document Type"::Order);
                        ServOrderAlloc.SetRange("Allocation Date", "Period Start", "Period End");
                        ServOrderAlloc.SetFilter(Status, '=%1|%2', ServOrderAlloc.Status::Active, ServOrderAlloc.Status::Finished);
                        ServOrderAlloc.SetRange(Posted, false);
                        PAGE.RunModal(0, ServOrderAlloc);
                    end;
                }
                field(NetAvailability; "Net Availability")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Availability';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies capacity, minus the quantity on order, minus the jobs quotes allocation.';
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
        Res: Record Resource;
        ServOrderAlloc: Record "Service Order Allocation";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    procedure Set(var NewRes: Record Resource; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        Res.Copy(NewRes);
        DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Res.SetRange("Date Filter", "Period Start", "Period End")
        else
            Res.SetRange("Date Filter", 0D, "Period End");
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        Res.CalcFields(Capacity, "Qty. on Service Order");

        Capacity := Res.Capacity;
        "Qty. on Service Order" := Res."Qty. on Service Order";
        "Net Availability" := Capacity - "Qty. on Service Order";

        OnAfterCalcLine(Res, Rec);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterCalcLine(var Resource: Record Resource; var ResAvailabilityBuffer: Record "Res. Availability Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCapacityOnDrillDown(var ResCapacityEntry: Record "Res. Capacity Entry"; var IsHandled: Boolean)
    begin
    end;
}

