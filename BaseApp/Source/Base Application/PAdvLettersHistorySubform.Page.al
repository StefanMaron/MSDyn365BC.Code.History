#if not CLEAN19
page 31029 "P.Adv. Letters History Subform"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Purch. Advance Letter Line";
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
                field("Letter No."; Rec."Letter No.")
                {
                    ApplicationArea = Basic, Suite;
                    HideValue = "LetterNoHideValue";
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies the number of letter.';
                }
                field("Advance Due Date"; Rec."Advance Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the advance must be paid.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the purchase advance letter.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for purchase advance.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                    Visible = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage used to calculate Amount Including VAT on this line.';
                    Visible = false;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies VAT amount of advance.';
                    Visible = false;
                }
                field("Amount Linked"; Rec."Amount Linked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount paid by customer.';
                }
                field("Amount Invoiced"; Rec."Amount Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount with advance VAT document.';
                }
                field("Amount Deducted"; Rec."Amount Deducted")
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
                        ShowDoc();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LetterNoHideValue := false;
        LetterNoOnFormat();
    end;

    var
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        [InDataSet]
        LetterNoHideValue: Boolean;

    [Scope('OnPrem')]
    procedure ShowDoc()
    var
        PurchAdvanceLetter: Page "Purchase Advance Letter";
    begin
        PurchAdvanceLetterHeader.SetRange("No.", "Letter No.");
        PurchAdvanceLetter.SetTableView(PurchAdvanceLetterHeader);
        PurchAdvanceLetter.Run();
    end;

    [Scope('OnPrem')]
    procedure IsFirstDocLine(): Boolean
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterLine.Reset();
        PurchAdvanceLetterLine.CopyFilters(Rec);
        PurchAdvanceLetterLine.SetRange("Letter No.", "Letter No.");
        if PurchAdvanceLetterLine.FindFirst() then
            exit(PurchAdvanceLetterLine."Line No." = "Line No.");
        exit(true);
    end;

    local procedure LetterNoOnFormat()
    begin
        if not IsFirstDocLine() then
            LetterNoHideValue := true;
    end;

    [Scope('OnPrem')]
    procedure SetCurrSubPageUpdate()
    begin
        CurrPage.Update(false);
    end;
}
#endif
