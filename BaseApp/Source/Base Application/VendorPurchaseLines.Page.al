page 352 "Vendor Purchase Lines"
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
                    ToolTip = 'Specifies purchase statistics for each vendor for a period of time, starting on the date that you specify.';
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period that you want to view.';
                }
                field(BalanceDueLCY; Vend."Balance Due (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance Due (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the balance due to the vendor, in local currency.';

                    trigger OnDrillDown()
                    begin
                        ShowVendEntriesDue;
                    end;
                }
                field("Vend.""Purchases (LCY)"""; Vend."Purchases (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchases (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the purchases, in local currency.';

                    trigger OnDrillDown()
                    begin
                        ShowVendEntries;
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
        Vend.CalcFields("Balance Due (LCY)", "Purchases (LCY)");
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
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        PeriodFormMgt: Codeunit PeriodFormManagement;
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    procedure Set(var NewVend: Record Vendor; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        Vend.Copy(NewVend);
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure ShowVendEntries()
    begin
        SetDateFilter;
        VendLedgEntry.Reset;
        VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        VendLedgEntry.SetFilter("Posting Date", Vend.GetFilter("Date Filter"));
        VendLedgEntry.SetFilter("Global Dimension 1 Code", Vend.GetFilter("Global Dimension 1 Filter"));
        VendLedgEntry.SetFilter("Global Dimension 2 Code", Vend.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, VendLedgEntry);
    end;

    local procedure ShowVendEntriesDue()
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        SetDateFilter;
        DtldVendLedgEntry.Reset;
        DtldVendLedgEntry.SetCurrentKey("Vendor No.", "Initial Entry Due Date", "Posting Date", "Currency Code");
        DtldVendLedgEntry.SetRange("Vendor No.", Vend."No.");
        DtldVendLedgEntry.SetFilter("Initial Entry Due Date", Vend.GetFilter("Date Filter"));
        DtldVendLedgEntry.SetFilter("Posting Date", '..%1', Vend.GetRangeMax("Date Filter"));
        DtldVendLedgEntry.SetFilter("Initial Entry Global Dim. 1", Vend.GetFilter("Global Dimension 1 Filter"));
        DtldVendLedgEntry.SetFilter("Initial Entry Global Dim. 2", Vend.GetFilter("Global Dimension 2 Filter"));
        PAGE.Run(0, DtldVendLedgEntry)
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Vend.SetRange("Date Filter", "Period Start", "Period End")
        else
            Vend.SetRange("Date Filter", 0D, "Period End");
    end;
}

