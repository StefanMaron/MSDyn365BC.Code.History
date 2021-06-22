page 6061 "Contract Trend Lines"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Contract Trend Buffer";
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
                    ToolTip = 'Specifies the starting date of the period that you want to view.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Service;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
                field("ServContract.""Contract Prepaid Amount"""; "Prepaid Income")
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepaid Income';
                    ToolTip = 'Specifies the total income (in LCY) that has been posted to the prepaid account for the service contract in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter();
                        ServLedgEntry.Reset();
                        ServLedgEntry.SetCurrentKey(Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date");
                        ServLedgEntry.SetRange("Service Contract No.", ServContract."Contract No.");
                        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Sale);
                        ServLedgEntry.SetRange("Moved from Prepaid Acc.", false);
                        ServLedgEntry.SetRange(Type, ServLedgEntry.Type::"Service Contract");
                        ServLedgEntry.SetRange(Open, false);
                        ServLedgEntry.SetRange(Prepaid, true);
                        ServLedgEntry.SetFilter("Posting Date", ServContract.GetFilter("Date Filter"));
                        PAGE.RunModal(0, ServLedgEntry);
                    end;
                }
                field("ServContract.""Contract Invoice Amount"""; "Posted Income")
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Income';
                    DrillDown = true;
                    ToolTip = 'Specifies the total income (in LCY) that has been posted to the general ledger for the service contract in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter();
                        ServLedgEntry.Reset();
                        ServLedgEntry.SetCurrentKey(Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date");
                        ServLedgEntry.SetRange("Service Contract No.", ServContract."Contract No.");
                        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Sale);
                        ServLedgEntry.SetRange("Moved from Prepaid Acc.", true);
                        ServLedgEntry.SetRange(Open, false);
                        ServLedgEntry.SetFilter("Posting Date", ServContract.GetFilter("Date Filter"));
                        PAGE.RunModal(0, ServLedgEntry);
                    end;
                }
                field("ServContract.""Contract Cost Amount"""; "Posted Cost")
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Cost';
                    ToolTip = 'Specifies the cost of the service contract based on its service usage in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter();
                        Clear(ServLedgEntry);
                        ServLedgEntry.SetCurrentKey(Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date");
                        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Usage);
                        ServLedgEntry.SetRange("Service Contract No.", ServContract."Contract No.");
                        ServLedgEntry.SetRange("Moved from Prepaid Acc.", true);
                        ServLedgEntry.SetRange(Open, false);
                        ServLedgEntry.SetFilter("Posting Date", ServContract.GetFilter("Date Filter"));
                        PAGE.RunModal(0, ServLedgEntry);
                    end;
                }
                field("ServContract.""Contract Discount Amount"""; "Discount Amount")
                {
                    ApplicationArea = Service;
                    Caption = 'Discount Amount';
                    ToolTip = 'Specifies the amount of discount being applied for the line.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter();
                        Clear(ServLedgEntry);
                        ServLedgEntry.SetCurrentKey("Service Contract No.");
                        ServLedgEntry.SetRange("Service Contract No.", ServContract."Contract No.");
                        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Usage);
                        ServLedgEntry.SetRange("Moved from Prepaid Acc.", true);
                        ServLedgEntry.SetRange(Open, false);
                        ServLedgEntry.SetFilter("Posting Date", ServContract.GetFilter("Date Filter"));
                        PAGE.RunModal(0, ServLedgEntry);
                    end;
                }
                field(ProfitAmount; Profit)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit';
                    ToolTip = 'Specifies the profit (posted incom0e minus posted cost in LCY) for the service contract in the periods specified in the Period Start field.';
                }
                field(ProfitPct; "Profit %")
                {
                    ApplicationArea = Service;
                    Caption = 'Profit %';
                    ToolTip = 'Specifies the profit percentage for the service contract in the periods specified in the Period Start field. ';
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
        ServContract: Record "Service Contract Header";
        ServLedgEntry: Record "Service Ledger Entry";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
        ProfitAmount: Decimal;
        ProfitPct: Decimal;

    procedure Set(var NewServContract: Record "Service Contract Header"; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        ServContract.Copy(NewServContract);
        DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            ServContract.SetRange("Date Filter", "Period Start", "Period End")
        else
            ServContract.SetRange("Date Filter", 0D, "Period End");
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        ServContract.CalcFields(
          "Contract Invoice Amount",
          "Contract Discount Amount",
          "Contract Cost Amount",
          "Contract Prepaid Amount");

        "Prepaid Income" := ServContract."Contract Prepaid Amount";
        "Posted Income" := ServContract."Contract Invoice Amount";
        "Posted Cost" := ServContract."Contract Cost Amount";
        "Discount Amount" := ServContract."Contract Discount Amount";

        Profit := ServContract."Contract Invoice Amount" - ServContract."Contract Cost Amount";
        if ServContract."Contract Invoice Amount" <> 0 then
            "Profit %" := Round((Profit / ServContract."Contract Invoice Amount") * 100, 0.01)
        else
            "Profit %" := 0;

        OnAfterCalcLine(ServContract, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var ServiceContractHeader: Record "Service Contract Header"; var ServiceItemTrendBuffer: Record "Contract Trend Buffer")
    begin
    end;
}

