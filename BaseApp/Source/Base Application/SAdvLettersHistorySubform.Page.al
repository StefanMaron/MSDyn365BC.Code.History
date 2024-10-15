#if not CLEAN19
page 31009 "S.Adv. Letters History Subform"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Sales Advance Letter Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220011)
            {
                ShowCaption = false;
                field("Letter No."; "Letter No.")
                {
                    ApplicationArea = Basic, Suite;
                    HideValue = LetterNoHideValue;
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the number of letter.';
                }
                field("Advance Due Date"; "Advance Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the advance must be paid.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the sales advance letter.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for sales advance.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                    Visible = false;
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage used to calculate Amount Including VAT on this line.';
                    Visible = false;
                }
                field("VAT Amount"; "VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT amount of advance.';
                    Visible = false;
                }
                field("Amount Linked"; "Amount Linked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount paid by customer.';
                }
                field("Amount Invoiced"; "Amount Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount with advance VAT document.';
                }
                field("Amount Deducted"; "Amount Deducted")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that was used in final sales invoice.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Show Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Document';
                    Image = View;
                    ToolTip = 'Specifies document';

                    trigger OnAction()
                    begin
                        ShowDoc;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LetterNoHideValue := false;
        LetterNoOnFormat;
    end;

    var
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        [InDataSet]
        LetterNoHideValue: Boolean;

    [Scope('OnPrem')]
    procedure ShowDoc()
    var
        SalesAdvanceLetter: Page "Sales Advance Letter";
    begin
        SalesAdvanceLetterHeader.SetRange("No.", "Letter No.");
        SalesAdvanceLetter.SetTableView(SalesAdvanceLetterHeader);
        SalesAdvanceLetter.Run;
    end;

    [Scope('OnPrem')]
    procedure IsFirstDocLine(): Boolean
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        SalesAdvanceLetterLine.Reset();
        SalesAdvanceLetterLine.CopyFilters(Rec);
        SalesAdvanceLetterLine.SetRange("Letter No.", "Letter No.");
        if SalesAdvanceLetterLine.FindFirst then
            exit(SalesAdvanceLetterLine."Line No." = "Line No.");
        exit(true);
    end;

    local procedure LetterNoOnFormat()
    begin
        if not IsFirstDocLine then
            LetterNoHideValue := true;
    end;

    [Scope('OnPrem')]
    procedure SetCurrSubPageUpdate()
    begin
        CurrPage.Update(false);
    end;
}
#endif
