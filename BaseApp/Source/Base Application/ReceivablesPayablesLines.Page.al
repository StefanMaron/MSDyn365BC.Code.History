page 355 "Receivables-Payables Lines"
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
                    ApplicationArea = Suite;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the beginning of the period covered by the summary report of receivables for customers and payables for vendors.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period covered by the summary report of receivables for customers and payables for vendors.';
                }
                field(CustBalancesDue; GLSetup."Cust. Balances Due")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Cust. Balances Due';
                    DrillDown = true;
                    ToolTip = 'Specifies the total amount your company is owed by customers. The program automatically calculates and updates the contents of the field, using entries in the Remaining Amt. (LCY) field in the Cust. Ledger Entry table.';

                    trigger OnDrillDown()
                    begin
                        ShowCustEntriesDue;
                    end;
                }
                field(VendorBalancesDue; GLSetup."Vendor Balances Due")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Vendor Balances Due';
                    DrillDown = true;
                    ToolTip = 'Specifies the total amount your company owes its vendors. The program automatically calculates and updates the contents of the field, using entries in the Remaining Amt. (LCY) field in the Vendor Ledger Entry table.';

                    trigger OnDrillDown()
                    begin
                        ShowVendEntriesDue;
                    end;
                }
                field(ReceivablesPayables; GLSetup."Cust. Balances Due" - GLSetup."Vendor Balances Due")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Receivables-Payables';
                    ToolTip = 'Specifies expected payments from customers and to vendors. It does not include other transactions that affect liquidity or the liquid balance at the beginning of the period. Therefore, the amounts in the column do not represent the liquid balance at the close of the period.';
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
        GLSetup.CalcFields("Cust. Balances Due", "Vendor Balances Due");
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
        GLSetup: Record "General Ledger Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    procedure Set(var NewGLSetup: Record "General Ledger Setup"; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        GLSetup.Copy(NewGLSetup);
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure ShowCustEntriesDue()
    begin
        SetDateFilter;
        CustLedgEntry.Reset;
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetFilter("Due Date", GLSetup.GetFilter("Date Filter"));
        CustLedgEntry.SetFilter("Global Dimension 1 Code", GLSetup.GetFilter("Global Dimension 1 Filter"));
        CustLedgEntry.SetFilter("Global Dimension 2 Code", GLSetup.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, CustLedgEntry)
    end;

    local procedure ShowVendEntriesDue()
    begin
        SetDateFilter;
        VendLedgEntry.Reset;
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetFilter("Due Date", GLSetup.GetFilter("Date Filter"));
        VendLedgEntry.SetFilter("Global Dimension 1 Code", GLSetup.GetFilter("Global Dimension 1 Filter"));
        VendLedgEntry.SetFilter("Global Dimension 2 Code", GLSetup.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, VendLedgEntry);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            GLSetup.SetRange("Date Filter", "Period Start", "Period End")
        else
            GLSetup.SetRange("Date Filter", 0D, "Period End");
    end;
}

