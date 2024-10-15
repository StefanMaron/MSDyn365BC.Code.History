page 31058 "Posted Credit Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Posted Credit Line";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Control1220018)
            {
                ShowCaption = false;
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of source (customer or vendor).';
                }
                field("Source Entry No."; "Source Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of customer''s or vendor''s entries.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of customer or vendor.';
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting group that will be used in posting the journal line.The field is used only if the account type is either customer or vendor.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the credit card was posted.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document type of the customer or vendor ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of customer''s or vendor''s document.';
                }
                field("Variable Symbol"; "Variable Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the detail information for advance payment.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description for credit card.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';
                }
                field("Ledg. Entry Original Amount"; "Ledg. Entry Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the original amount of document.';
                    Visible = false;
                }
                field("Ledg. Entry Remaining Amount"; "Ledg. Entry Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount which can be counted.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry. The amount is shown in the currency of the original transaction.';
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount after doing credit process. The amount is in the local currency.';
                }
                field("Ledg. Entry Original Amt.(LCY)"; "Ledg. Entry Original Amt.(LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original amount of document. The amount is in the local currency.';
                    Visible = false;
                }
                field("Ledg. Entry Rem. Amt. (LCY)"; "Ledg. Entry Rem. Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount which can be counted. The amount is in the local currency.';
                    Visible = false;
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
                field("Remaining Amount (LCY)"; "Remaining Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount after doing credit process. The amount is in the local currency.';
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
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'Specifies credit dimensions.';

                    trigger OnAction()
                    begin
                        ShowDim;
                    end;
                }
            }
        }
    }

    [Scope('OnPrem')]
    procedure ShowDim()
    begin
        ShowDimensions();
    end;
}

