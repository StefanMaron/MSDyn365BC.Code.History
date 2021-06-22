page 5984 "Service Item Trend Lines"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Service Item Trend Buffer";
    SourceTableTemporary = true;


    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Period Start"; "Period Start")
                {
                    ApplicationArea = Service;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the start date of the period defined on the line for the service trend.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Service;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
                field("ServItem.""Prepaid Amount"""; "Prepaid Income")
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepaid Income';
                    ToolTip = 'Specifies the total income (in LCY) that has been posted to the prepaid account with regard to the service item in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        ShowServLedgEntries(false);
                    end;
                }
                field("ServItem.""Invoiced Amount"""; "Posted Income")
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Income';
                    DrillDown = true;
                    ToolTip = 'Specifies the total income (in LCY) that has been posted to the general ledger for the service item in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        ShowServLedgEntries(true);
                    end;
                }
                field("ServItem.""Parts Used"""; "Parts Used")
                {
                    ApplicationArea = Service;
                    Caption = 'Parts Used';
                    DrillDown = true;
                    ToolTip = 'Specifies the cost of resources used in the specified period.';

                    trigger OnDrillDown()
                    begin
                        ShowServLedgEntriesByType(ServLedgEntry.Type::Item);
                    end;
                }
                field("ServItem.""Resources Used"""; "Resources Used")
                {
                    ApplicationArea = Service;
                    Caption = 'Resources Used';
                    DrillDown = true;
                    ToolTip = 'Specifies the cost of spare parts used in the period shown in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        ShowServLedgEntriesByType(ServLedgEntry.Type::Resource);
                    end;
                }
                field("ServItem.""Cost Used"""; "Cost Used")
                {
                    ApplicationArea = Service;
                    Caption = 'Cost Used';
                    ToolTip = 'Specifies the amount of service usage based on service cost for this service item.';

                    trigger OnDrillDown()
                    begin
                        ShowServLedgEntriesByType(ServLedgEntry.Type::"Service Cost");
                    end;
                }
                field(Profit; Profit)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit';
                    ToolTip = 'Specifies the profit (posted income minus posted cost in LCY) for the service item in the period specified in the Period Start field.';
                }
                field(ProfitPct; "Profit %")
                {
                    ApplicationArea = Service;
                    Caption = 'Profit %';
                    ToolTip = 'Specifies the profit percentage for the service item in the specified period.';
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
        ServItem: Record "Service Item";
        ServLedgEntry: Record "Service Ledger Entry";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    procedure Set(var ServItem1: Record "Service Item"; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        ServItem.Copy(ServItem1);
        DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            ServItem.SetRange("Date Filter", "Period Start", "Period End")
        else
            ServItem.SetRange("Date Filter", 0D, "Period End");
    end;

    local procedure ShowServLedgEntries(Prepaid: Boolean)
    begin
        SetDateFilter();
        ServLedgEntry.Reset();
        ServLedgEntry.SetCurrentKey("Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", Type, "Posting Date");
        ServLedgEntry.SetRange("Service Item No. (Serviced)", ServItem."No.");
        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Sale);
        ServLedgEntry.SetRange("Moved from Prepaid Acc.", Prepaid);
        ServLedgEntry.SetRange(Open, false);
        ServLedgEntry.SetFilter("Posting Date", ServItem.GetFilter("Date Filter"));
        PAGE.Run(0, ServLedgEntry);
    end;

    local procedure ShowServLedgEntriesByType(Type: Option)
    begin
        SetDateFilter();
        ServLedgEntry.Reset();
        ServLedgEntry.SetCurrentKey("Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", Type, "Posting Date");
        ServLedgEntry.SetRange("Service Item No. (Serviced)", ServItem."No.");
        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Sale);
        ServLedgEntry.SetRange(Type, Type);
        ServLedgEntry.SetFilter("Posting Date", ServItem.GetFilter("Date Filter"));
        PAGE.Run(0, ServLedgEntry);
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        ServItem.CalcFields("Invoiced Amount", "Resources Used", "Parts Used", "Cost Used", "Prepaid Amount");
        Profit := ServItem."Invoiced Amount" - ServItem."Resources Used" - ServItem."Parts Used" - ServItem."Cost Used";
        if ServItem."Invoiced Amount" <> 0 then
            "Profit %" := Round((Profit / ServItem."Invoiced Amount") * 100, 0.01)
        else
            "Profit %" := 0;

        "Prepaid Income" := ServItem."Prepaid Amount";
        "Posted Income" := ServItem."Invoiced Amount";
        "Parts Used" := ServItem."Parts Used";
        "Resources Used" := ServItem."Resources Used";
        "Cost Used" := ServItem."Cost Used";

        OnAfterCalcLine(ServItem, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var ServItem: Record "Service Item"; var ServiceItemTrendBuffer: Record "Service Item Trend Buffer")
    begin
    end;
}

