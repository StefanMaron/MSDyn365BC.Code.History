page 362 "Res. Gr. Availability Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = Date;

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
                field(Capacity; ResGr.Capacity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Capacity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total capacity for the corresponding time period.';
                }
                field("ResGr.""Qty. on Order (Job)"""; ResGr."Qty. on Order (Job)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. on Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of measuring units allocated to jobs with the status order.';
                }
                field("ResGr.""Qty. on Service Order"""; ResGr."Qty. on Service Order")
                {
                    ApplicationArea = Service;
                    Caption = 'Qty. Allocated on Service Order';
                    ToolTip = 'Specifies the amount of measuring units allocated to service orders.';
                }
                field(CapacityAfterOrders; CapacityAfterOrders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Availability After Orders';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the capacity minus the quantity on order.';
                }
                field("ResGr.""Qty. Quoted (Job)"""; ResGr."Qty. Quoted (Job)")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Quotes Allocation';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of measuring units allocated to jobs with the status quote.';
                }
                field(CapacityAfterQuotes; CapacityAfterQuotes)
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
        SetDateFilter;
        CalcLine;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(PeriodFormMgt.FindDate(Which, Rec, PeriodType));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(PeriodFormMgt.NextDate(Steps, Rec, PeriodType));
    end;

    trigger OnOpenPage()
    begin
        Reset;
    end;

    var
        ResGr: Record "Resource Group";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        CapacityAfterOrders: Decimal;
        CapacityAfterQuotes: Decimal;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    procedure Set(var NewResGr: Record "Resource Group"; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        ResGr.Copy(NewResGr);
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
        ResGr.CalcFields(Capacity, "Qty. on Order (Job)", "Qty. Quoted (Job)", "Qty. on Service Order");
        CapacityAfterOrders := ResGr.Capacity - ResGr."Qty. on Order (Job)" - ResGr."Qty. on Service Order";
        CapacityAfterQuotes := CapacityAfterOrders - ResGr."Qty. Quoted (Job)";

        OnAfterCalcLine(ResGr, CapacityAfterOrders, CapacityAfterQuotes);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterCalcLine(var ResourceGroup: Record "Resource Group"; var CapacityAfterOrders: Decimal; var CapacityAfterQuotes: Decimal)
    begin
    end;
}

