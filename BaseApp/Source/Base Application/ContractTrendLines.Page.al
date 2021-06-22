page 6061 "Contract Trend Lines"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = Date;

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
                field("ServContract.""Contract Prepaid Amount"""; ServContract."Contract Prepaid Amount")
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepaid Income';
                    ToolTip = 'Specifies the total income (in LCY) that has been posted to the prepaid account for the service contract in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter;
                        ServLedgEntry.Reset;
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
                field("ServContract.""Contract Invoice Amount"""; ServContract."Contract Invoice Amount")
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Income';
                    DrillDown = true;
                    ToolTip = 'Specifies the total income (in LCY) that has been posted to the general ledger for the service contract in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter;
                        ServLedgEntry.Reset;
                        ServLedgEntry.SetCurrentKey(Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date");
                        ServLedgEntry.SetRange("Service Contract No.", ServContract."Contract No.");
                        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Sale);
                        ServLedgEntry.SetRange("Moved from Prepaid Acc.", true);
                        ServLedgEntry.SetRange(Open, false);
                        ServLedgEntry.SetFilter("Posting Date", ServContract.GetFilter("Date Filter"));
                        PAGE.RunModal(0, ServLedgEntry);
                    end;
                }
                field("ServContract.""Contract Cost Amount"""; ServContract."Contract Cost Amount")
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Cost';
                    ToolTip = 'Specifies the cost of the service contract based on its service usage in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter;
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
                field("ServContract.""Contract Discount Amount"""; ServContract."Contract Discount Amount")
                {
                    ApplicationArea = Service;
                    Caption = 'Discount Amount';
                    ToolTip = 'Specifies the amount of discount being applied for the line.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter;
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
                field(ProfitAmount; ProfitAmount)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit';
                    ToolTip = 'Specifies the profit (posted incom0e minus posted cost in LCY) for the service contract in the periods specified in the Period Start field.';
                }
                field(ProfitPct; ProfitPct)
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
        SetDateFilter;
        ServContract.CalcFields(
          "Contract Invoice Amount",
          "Contract Discount Amount",
          "Contract Cost Amount",
          "Contract Prepaid Amount");
        ProfitAmount := ServContract."Contract Invoice Amount" - ServContract."Contract Cost Amount";
        if ServContract."Contract Invoice Amount" <> 0 then
            ProfitPct := Round((ProfitAmount / ServContract."Contract Invoice Amount") * 100, 0.01)
        else
            ProfitPct := 0;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(PeriodFormMgt.FindDate(Which, Rec, PeriodType));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(PeriodFormMgt.NextDate(Steps, Rec, PeriodType));
    end;

    var
        ServContract: Record "Service Contract Header";
        ServLedgEntry: Record "Service Ledger Entry";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";
        ProfitAmount: Decimal;
        ProfitPct: Decimal;

    procedure Set(var NewServContract: Record "Service Contract Header"; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        ServContract.Copy(NewServContract);
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
}

