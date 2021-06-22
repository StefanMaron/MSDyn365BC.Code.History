page 355 "Receivables-Payables Lines"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Receivables-Payables Buffer";
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
                field(CustBalancesDue; "Cust. Balances Due")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Cust. Balances Due';
                    DrillDown = true;
                    ToolTip = 'Specifies the total amount your company is owed by customers. The program automatically calculates and updates the contents of the field, using entries in the Remaining Amt. (LCY) field in the Cust. Ledger Entry table.';

                    trigger OnDrillDown()
                    begin
                        ShowCustEntriesDue();
                    end;
                }
                field(VendorBalancesDue; "Vendor Balances Due")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Vendor Balances Due';
                    DrillDown = true;
                    ToolTip = 'Specifies the total amount your company owes its vendors. The program automatically calculates and updates the contents of the field, using entries in the Remaining Amt. (LCY) field in the Vendor Ledger Entry table.';

                    trigger OnDrillDown()
                    begin
                        ShowVendEntriesDue();
                    end;
                }
                field(ReceivablesPayables; "Receivables-Payables")
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
        GLSetup: Record "General Ledger Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    procedure Set(var NewGLSetup: Record "General Ledger Setup"; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        GLSetup.Copy(NewGLSetup);
        DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure ShowCustEntriesDue()
    begin
        SetDateFilter();
        CustLedgEntry.Reset();
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetFilter("Due Date", GLSetup.GetFilter("Date Filter"));
        CustLedgEntry.SetFilter("Global Dimension 1 Code", GLSetup.GetFilter("Global Dimension 1 Filter"));
        CustLedgEntry.SetFilter("Global Dimension 2 Code", GLSetup.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, CustLedgEntry)
    end;

    local procedure ShowVendEntriesDue()
    begin
        SetDateFilter();
        VendLedgEntry.Reset();
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

    local procedure CalcLine()
    begin
        SetDateFilter();
        GLSetup.CalcFields("Cust. Balances Due", "Vendor Balances Due");
        "Cust. Balances Due" := GLSetup."Cust. Balances Due";
        "Vendor Balances Due" := GLSetup."Vendor Balances Due";
        "Receivables-Payables" := GLSetup."Cust. Balances Due" - GLSetup."Vendor Balances Due";

        OnAfterCalcLine(GLSetup, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var GLSetup: Record "General Ledger Setup"; var ReceivablesPayablesBuffer: Record "Receivables-Payables Buffer")
    begin
    end;
}

