page 352 "Vendor Purchase Lines"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Vendor Purchase Buffer";
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
                field(BalanceDueLCY; "Balance Due (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance Due (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the balance due to the vendor, in local currency.';

                    trigger OnDrillDown()
                    begin
                        ShowVendEntriesDue();
                    end;
                }
                field("Vend.""Purchases (LCY)"""; "Purchases (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchases (LCY)';
                    DrillDown = true;
                    ToolTip = 'Specifies the purchases, in local currency.';

                    trigger OnDrillDown()
                    begin
                        ShowVendEntries();
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
        VendLedgEntry: Record "Vendor Ledger Entry";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        AmountType: Option "Net Change","Balance at Date";

    protected var
        Vend: Record Vendor;

    procedure Set(var NewVend: Record Vendor; NewPeriodType: Integer; NewAmountType: Option "Net Change","Balance at Date")
    begin
        Vend.Copy(NewVend);
        DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure ShowVendEntries()
    begin
        SetDateFilter();
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        VendLedgEntry.SetFilter("Posting Date", Vend.GetFilter("Date Filter"));
        VendLedgEntry.SetFilter("Global Dimension 1 Code", Vend.GetFilter("Global Dimension 1 Filter"));
        VendLedgEntry.SetFilter("Global Dimension 2 Code", Vend.GetFilter("Global Dimension 2 Filter"));
        VendLedgEntry.SetFilter("Agreement No.", Vend.GetFilter("Agreement Filter"));
        PAGE.Run(0, VendLedgEntry);
    end;

    local procedure ShowVendEntriesDue()
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        SetDateFilter();
        DtldVendLedgEntry.Reset();
        DtldVendLedgEntry.SetCurrentKey("Vendor No.", "Initial Entry Due Date", "Posting Date", "Currency Code");
        DtldVendLedgEntry.SetRange("Vendor No.", Vend."No.");
        DtldVendLedgEntry.SetFilter("Initial Entry Due Date", Vend.GetFilter("Date Filter"));
        DtldVendLedgEntry.SetFilter("Posting Date", '..%1', Vend.GetRangeMax("Date Filter"));
        DtldVendLedgEntry.SetFilter("Initial Entry Global Dim. 1", Vend.GetFilter("Global Dimension 1 Filter"));
        DtldVendLedgEntry.SetFilter("Initial Entry Global Dim. 2", Vend.GetFilter("Global Dimension 2 Filter"));
        DtldVendLedgEntry.SetFilter("Agreement No.", Vend.GetFilter("Agreement Filter"));
        PAGE.Run(0, DtldVendLedgEntry)
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        Vend.CalcFields("Balance Due (LCY)", "Purchases (LCY)");
        "Balance Due (LCY)" := Vend."Balance Due (LCY)";
        "Purchases (LCY)" := Vend."Purchases (LCY)";

        OnAfterCalcLine(Vend, Rec);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Vend.SetRange("Date Filter", "Period Start", "Period End")
        else
            Vend.SetRange("Date Filter", 0D, "Period End");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var Vendor: Record Vendor; var VendorPurchaseBuffer: Record "Vendor Purchase Buffer")
    begin
    end;
}

