pageextension 12145 NoSeriesIT extends "No. Series"
{
    layout
    {
#if not CLEAN24
#pragma warning disable AL0432
        modify(StartDate)
        {
            trigger OnDrillDown()
            var
                NoSeriesIT: Codeunit "No. Series IT";
            begin
                NoSeriesIT.DrillDown(Rec);
                CurrPage.Update(false);
            end;
        }
        modify(StartNo)
        {
            trigger OnDrillDown()
            var
                NoSeriesIT: Codeunit "No. Series IT";
            begin
                NoSeriesIT.DrillDown(Rec);
                CurrPage.Update(false);
            end;
        }
        modify(EndNo)
        {
            trigger OnDrillDown()
            var
                NoSeriesIT: Codeunit "No. Series IT";
            begin
                NoSeriesIT.DrillDown(Rec);
                CurrPage.Update(false);
            end;
        }
        modify(LastDateUsed)
        {
            trigger OnDrillDown()
            var
                NoSeriesIT: Codeunit "No. Series IT";
            begin
                NoSeriesIT.DrillDown(Rec);
                CurrPage.Update(false);
            end;
        }
        modify(LastNoUsed)
        {
            trigger OnDrillDown()
            var
                NoSeriesIT: Codeunit "No. Series IT";
            begin
                NoSeriesIT.DrillDown(Rec);
                CurrPage.Update(false);
            end;
        }
        modify(WarningNo)
        {
            trigger OnDrillDown()
            var
                NoSeriesIT: Codeunit "No. Series IT";
            begin
                NoSeriesIT.DrillDown(Rec);
                CurrPage.Update(false);
            end;
        }
        modify(IncrementByNo)
        {
            trigger OnDrillDown()
            var
                NoSeriesIT: Codeunit "No. Series IT";
            begin
                NoSeriesIT.DrillDown(Rec);
                CurrPage.Update(false);
            end;
        }
#pragma warning restore AL0432
#endif
        addafter(Code)
        {
            field("No. Series Type"; Rec."No. Series Type")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'No. Series Type';
                ToolTip = 'Specifies the number series type that is associated with the number series code.';
            }
        }
        addafter(Description)
        {
            field("VAT Register"; Rec."VAT Register")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the VAT register that is associated with the number series code.';
            }
            field("Reverse Sales VAT No. Series"; Rec."Reverse Sales VAT No. Series")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the numbers series that must be used for a reverse sales VAT transaction.';
            }
            field("VAT Reg. Print Priority"; Rec."VAT Reg. Print Priority")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the print priority that is associated with the VAT register.';
            }
        }
    }

#if not CLEAN24
    actions
    {
        modify(Lines)
        {
            Visible = UseLegacyNoSeriesLines;
        }
        addafter(Lines)
        {
            action(Lines_IT)
            {
                ObsoleteReason = 'The No. Series Line Sales and No. Series Line Purchase tables are obsolte. Use the No. Series Line table instead.';
                ObsoleteState = Pending;
                ObsoleteTag = '24.0';
                ApplicationArea = Basic, Suite;
                Caption = 'Lines';
                ToolTip = 'Open the Lines page to view the lines that are associated with the number series code.';
                Visible = not UseLegacyNoSeriesLines;

                trigger OnAction()
                var
                    NoSeriesIT: Codeunit "No. Series IT";
                begin
                    NoSeriesIT.ShowNoSeriesLines(Rec);
                end;
            }
        }
        addafter(Lines_Promoted)
        {
            actionref(Lines_Promoted_IT; Lines_IT)
            {
                ObsoleteReason = 'The No. Series Line Sales and No. Series Line Purchase tables are obsolte. Use the No. Series Line table instead.';
                ObsoleteState = Pending;
                ObsoleteTag = '24.0';
            }
        }
    }

    var
        UseLegacyNoSeriesLines: Boolean;

    trigger OnOpenPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        UseLegacyNoSeriesLines := GeneralLedgerSetup."Use Legacy No. Series Lines";
    end;
#endif
}