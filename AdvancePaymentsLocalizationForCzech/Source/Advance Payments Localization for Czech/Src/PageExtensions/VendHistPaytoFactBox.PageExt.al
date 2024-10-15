pageextension 31218 "Vend.Hist.Pay-to FactBox CZZ" extends "Vendor Hist. Pay-to FactBox"
{
    layout
    {
#if not CLEAN19
#pragma warning disable AL0432
        modify("Pay-to No. of Out. Adv. L.")
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
        modify("Pay-to No. of Closed Adv. L.")
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
        modify(PayToNoOfOutAdvLettersTile)
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
        modify(PayToNoOfClosedAdvLettersTile)
        {
            Visible = not AdvancePaymentsEnabledCZZ;
        }
#pragma warning restore AL0432
#endif
        addlast(Control23)
        {
            field(AdvancesCZZ; AdvancesCZZ)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Advances';
                ToolTip = 'Specifies the number of advance payments for the vendor.';
#if not CLEAN19
                Visible = AdvancePaymentsEnabledCZZ;
#endif

                trigger OnDrillDown()
                begin
                    DrillDownPurchAdvanceLetters();
                end;
            }
        }
        addlast(Control1)
        {
            field(CueAdvancesCZZ; AdvancesCZZ)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Advances';
                ToolTip = 'Specifies the number of advance payments for the vendor.';
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
        AdvancesCZZ := Rec.GetPurchaseAdvancesCountCZZ();
    end;

    var
#if not CLEAN19
        AdvancePaymentsMgtCZZ: Codeunit "Advance Payments Mgt. CZZ";
        AdvancePaymentsEnabledCZZ: Boolean;
#endif
        AdvancesCZZ: Integer;

    local procedure DrillDownPurchAdvanceLetters()
    var
        PurchAdvLetterHeaderCZZ: Record "Purch. Adv. Letter Header CZZ";
        PurchAdvanceLettersCZZ: Page "Purch. Advance Letters CZZ";
    begin
        PurchAdvLetterHeaderCZZ.SetRange("Pay-to Vendor No.", Rec."No.");
        PurchAdvLetterHeaderCZZ.SetFilter(Status, '%1|%2', PurchAdvLetterHeaderCZZ.Status::"To Pay", PurchAdvLetterHeaderCZZ.Status::"To Use");
        PurchAdvanceLettersCZZ.SetTableView(PurchAdvLetterHeaderCZZ);
        PurchAdvanceLettersCZZ.Run();
    end;
}