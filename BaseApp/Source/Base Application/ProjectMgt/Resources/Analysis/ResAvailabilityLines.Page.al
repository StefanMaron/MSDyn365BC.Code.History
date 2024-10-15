﻿namespace Microsoft.Projects.Resources.Analysis;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Resources.Resource;
using System.Utilities;

page 361 "Res. Availability Lines"
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
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies a series of dates according to the selected time interval.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Capacity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total capacity for the corresponding time period.';
                }
                field("Resource.""Qty. on Order (Job)"""; Rec."Qty. on Order (Job)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. on Order (Job)';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of measuring units allocated to jobs with the status order.';
                }
                field(CapacityAfterOrders; Rec."Availability After Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Availability After Orders';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies capacity minus the quantity on order.';
                }
                field("Resource.""Qty. Quoted (Job)"""; Rec."Job Quotes Allocation")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Job Quotes Allocation';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of measuring units allocated to jobs with the status quote.';
                }
                field(CapacityAfterQuotes; Rec."Availability After Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Availability After Quotes';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies capacity, minus quantity on order (Job), minus quantity on service order, minus job quotes allocation. ';
                }
                field("Resource.""Qty. on Service Order"""; Rec."Qty. on Service Order")
                {
                    ApplicationArea = Service;
                    Caption = 'Qty. on Service Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are allocated to service orders, meaning listed on outstanding service order lines.';
                }
                field(QtyOnAssemblyOrder; Rec."Qty. on Assembly Order")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Qty. on Assembly Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are allocated to assembly orders, which is how many are listed on outstanding assembly order headers.';
                }
                field(NetAvailability; Rec."Net Availability")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 5;
                    Caption = 'Net Availability';
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
        if DateRec.Get(Rec."Period Type", Rec."Period Start") then;
        CalcLine();
    end;

    trigger OnFindRecord(Which: Text) FoundDate: Boolean
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        FoundDate := PeriodFormLinesMgt.FindDate(VariantRec, DateRec, Which, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnNextRecord(Steps: Integer) ResultSteps: Integer
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ResultSteps := PeriodFormLinesMgt.NextDate(VariantRec, DateRec, Steps, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
    end;

    var
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        CapacityAfterOrders: Decimal;
        CapacityAfterQuotes: Decimal;
        NetAvailability: Decimal;
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    protected var
        Resource: Record Resource;

    procedure SetLines(var NewRes: Record Resource; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type")
    begin
        Resource.Copy(NewRes);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Resource.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            Resource.SetRange("Date Filter", 0D, Rec."Period End");
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        Resource.CalcFields(Capacity, "Qty. on Order (Job)", "Qty. Quoted (Job)", "Qty. on Service Order", "Qty. on Assembly Order");

        Rec.Capacity := Resource.Capacity;
        Rec."Qty. on Order (Job)" := Resource."Qty. on Order (Job)";
        Rec."Availability After Orders" := Resource.Capacity - Resource."Qty. on Order (Job)";
        Rec."Job Quotes Allocation" := Resource."Qty. Quoted (Job)";
        Rec."Availability After Quotes" := Rec."Availability After Orders" - Resource."Qty. Quoted (Job)";
        Rec."Qty. on Service Order" := Resource."Qty. on Service Order";
        Rec."Qty. on Assembly Order" := Resource."Qty. on Assembly Order";
        Rec."Net Availability" := Rec."Availability After Quotes" - Resource."Qty. on Service Order" - Resource."Qty. on Assembly Order";

        CapacityAfterOrders := Resource.Capacity - Resource."Qty. on Order (Job)";
        CapacityAfterQuotes := CapacityAfterOrders - Resource."Qty. Quoted (Job)";
        NetAvailability := CapacityAfterQuotes - Resource."Qty. on Service Order" - Resource."Qty. on Assembly Order";

        OnAfterCalcLine(Resource, CapacityAfterOrders, CapacityAfterQuotes, NetAvailability, Rec);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterCalcLine(var Resource: Record Resource; var CapacityAfterOrders: Decimal; var CapacityAfterQuotes: Decimal; var NetAvailability: Decimal; var ResAvailabilityBuffer: Record "Res. Availability Buffer")
    begin
    end;
}

