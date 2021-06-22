page 6012 "Res.Gr Availability Lines (SM)"
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
                    ToolTip = 'Specifies the start date of the period defined on the line for the resource group. ';
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
                        ResCapacityEntry.SetRange("Resource Group No.", ResGr."No.");
                        ResCapacityEntry.SetRange(Date, "Period Start", "Period End");
                        IsHandled := false;
                        OnAfterCapacityOnDrillDown(ResCapacityEntry, IsHandled);
                        if IsHandled then
                            exit;

                        PAGE.RunModal(0, ResCapacityEntry);
                    end;
                }
                field("ResGr.""Qty. on Service Order"""; "Qty. on Service Order")
                {
                    ApplicationArea = Service;
                    Caption = 'Qty. on Service Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are allocated to service orders, meaning listed on outstanding service order lines.';

                    trigger OnDrillDown()
                    var
                        ServOrderAlloc: Record "Service Order Allocation";
                    begin
                        ServOrderAlloc.SetRange("Resource Group No.", ResGr."No.");
                        ServOrderAlloc.SetRange("Allocation Date", "Period Start", "Period End");
                        ServOrderAlloc.SetFilter(Status, '%1|%2', ServOrderAlloc.Status::Active, ServOrderAlloc.Status::Finished);
                        ServOrderAlloc.SetRange(Posted, false);
                        PAGE.RunModal(0, ServOrderAlloc);
                    end;
                }
                field(NetAvailability; "Net Availability")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Availability';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies capacity, minus the quantity on order (Job), minus quantity on Service Order, minus Job Quotes Allocation.';
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
        ResGr: Record "Resource Group";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    procedure Set(var NewResGr: Record "Resource Group"; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        ResGr.Copy(NewResGr);
        DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            ResGr.SetRange("Date Filter", "Period Start", "Period End")
        else
            ResGr.SetRange("Date Filter", 0D, "Period End");
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        ResGr.CalcFields(Capacity, "Qty. on Service Order");

        Capacity := ResGr.Capacity;
        "Qty. on Service Order" := ResGr."Qty. on Service Order";
        "Net Availability" := Capacity - "Qty. on Service Order";

        OnAfterCalcLine(ResGr, Rec);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterCalcLine(var ResourceGroup: Record "Resource Group"; var ResAvailabilityBuffer: Record "Res. Availability Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCapacityOnDrillDown(var ResCapacityEntry: Record "Res. Capacity Entry"; var IsHandled: Boolean)
    begin
    end;
}

