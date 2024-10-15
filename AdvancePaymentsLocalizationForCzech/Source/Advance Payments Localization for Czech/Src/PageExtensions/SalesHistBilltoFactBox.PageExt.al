pageextension 31220 "Sales Hist.Bill-to FactBox CZZ" extends "Sales Hist. Bill-to FactBox"
{
    layout
    {
#if not CLEAN19
#pragma warning disable AL0432
        modify("Bill-To No. of Out. Adv. L.")
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
        modify("Bill-To No. of Closed Adv. L.")
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
        modify(BillToNoOfOutAdvLettersTile)
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
        modify(BillToNoOfClosedAdvLettersTile)
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
#pragma warning restore AL0432
#endif
        addlast(Control2)
        {
            field(AdvancesCZZ; AdvancesCZZ)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Advances';
                ToolTip = 'Specifies the number of advance payments for the customer.';
#if not CLEAN19
                Visible = AdvancePaymentsEnabledCZZ;
#endif

                trigger OnDrillDown()
                begin
                    DrillDownPurchAdvanceLetters();
                end;
            }
        }
        addlast(Control23)
        {
            field(CueAdvancesCZZ; AdvancesCZZ)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Advances';
                ToolTip = 'Specifies the number of advance payments for the customer.';
#if not CLEAN19
                Visible = AdvancePaymentsEnabledCZZ;
#endif

                trigger OnDrillDown()
                begin
                    DrillDownPurchAdvanceLetters();
                end;
            }
        }
    }
#if not CLEAN19
    trigger OnOpenPage()
    begin
        AdvancePaymentsEnabledCZZ := AdvancePaymentsMgtCZZ.IsEnabled();
    end;
#endif

    trigger OnAfterGetRecord()
    begin
        AdvancesCZZ := Rec.GetSalesAdvancesCountCZZ();
    end;

    var
#if not CLEAN19
        AdvancePaymentsMgtCZZ: Codeunit "Advance Payments Mgt. CZZ";
        AdvancePaymentsEnabledCZZ: Boolean;
#endif
        AdvancesCZZ: Integer;

    local procedure DrillDownPurchAdvanceLetters()
    var
        SalesAdvLetterHeaderCZZ: Record "Sales Adv. Letter Header CZZ";
        SalesAdvanceLettersCZZ: Page "Sales Advance Letters CZZ";
    begin
        SalesAdvLetterHeaderCZZ.SetRange("Bill-to Customer No.", Rec."No.");
        SalesAdvLetterHeaderCZZ.SetFilter(Status, '%1|%2', SalesAdvLetterHeaderCZZ.Status::"To Pay", SalesAdvLetterHeaderCZZ.Status::"To Use");
        SalesAdvanceLettersCZZ.SetTableView(SalesAdvLetterHeaderCZZ);
        SalesAdvanceLettersCZZ.Run();
    end;
}