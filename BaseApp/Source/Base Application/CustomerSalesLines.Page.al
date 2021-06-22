page 351 "Customer Sales Lines"
{
    Caption = 'Lines';
    Editable = false;
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the starting date of the period that you want to view.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period that you want to view.';
                }
                field(BalanceDueLCY; Cust."Balance Due (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance Due (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the balance due, in local currency.';

                    trigger OnDrillDown()
                    begin
                        ShowCustEntriesDue;
                    end;
                }
                field("Cust.""Sales (LCY)"""; Cust."Sales (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the sales related to the customer, in local currency.';

                    trigger OnDrillDown()
                    begin
                        ShowCustEntries;
                    end;
                }
                field("Cust.""Profit (LCY)"""; Cust."Profit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Profit (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the profit related to the customer, in local currency.';

                    trigger OnDrillDown()
                    begin
                        ShowCustEntries;
                    end;
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
        Cust.CalcFields("Balance Due (LCY)", "Sales (LCY)", "Profit (LCY)");
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
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    procedure Set(var NewCust: Record Customer; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        Cust.Copy(NewCust);
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure ShowCustEntries()
    begin
        SetDateFilter;
        CustLedgEntry.Reset;
        CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgEntry.SetRange("Customer No.", Cust."No.");
        CustLedgEntry.SetFilter("Posting Date", Cust.GetFilter("Date Filter"));
        CustLedgEntry.SetFilter("Global Dimension 1 Code", Cust.GetFilter("Global Dimension 1 Filter"));
        CustLedgEntry.SetFilter("Global Dimension 2 Code", Cust.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, CustLedgEntry);
    end;

    local procedure ShowCustEntriesDue()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        SetDateFilter;
        DtldCustLedgEntry.Reset;
        DtldCustLedgEntry.SetCurrentKey("Customer No.", "Initial Entry Due Date", "Posting Date", "Currency Code");
        DtldCustLedgEntry.SetRange("Customer No.", Cust."No.");
        DtldCustLedgEntry.SetFilter("Initial Entry Due Date", Cust.GetFilter("Date Filter"));
        DtldCustLedgEntry.SetFilter("Posting Date", '..%1', Cust.GetRangeMax("Date Filter"));
        DtldCustLedgEntry.SetFilter("Initial Entry Global Dim. 1", Cust.GetFilter("Global Dimension 1 Filter"));
        DtldCustLedgEntry.SetFilter("Initial Entry Global Dim. 2", Cust.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, DtldCustLedgEntry)
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Cust.SetRange("Date Filter", "Period Start", "Period End")
        else
            Cust.SetRange("Date Filter", 0D, "Period End");
    end;
}

