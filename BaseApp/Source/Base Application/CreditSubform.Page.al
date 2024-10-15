page 31051 "Credit Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Credit Line";
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
                    BlankZero = true;
                    ShowMandatory = true;
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
                    ToolTip = 'Specifies the date when the posting of the credit card will be recorded.';
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
                    ToolTip = 'Specifies description for credit.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency of amounts on the document.';

                    trigger OnAssistEdit()
                    var
                        CreditHeader: Record "Credit Header";
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        CreditHeader.Get("Credit No.");
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", CreditHeader."Posting Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);
                    end;
                }
                field("Ledg. Entry Original Amount"; "Ledg. Entry Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the original amount of document.';
                    Visible = false;
                }
                field("Ledg. Entry Remaining Amount"; "Ledg. Entry Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the amount which can be counted.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the amount which can be counted.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the amount after doing credit process.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Ledg. Entry Original Amt.(LCY)"; "Ledg. Entry Original Amt.(LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the original amount of document. The amount is in the local currency.';
                    Visible = false;
                }
                field("Ledg. Entry Rem. Amt. (LCY)"; "Ledg. Entry Rem. Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the amount which can be counted. The amount is in the local currency.';
                    Visible = false;
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the amount which can be counted. The amount is in the local currency.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Remaining Amount (LCY)"; "Remaining Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the amount after doing credit process. The amount is in the local currency.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Manual Change Only"; "Manual Change Only")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit lines which can''not be used by function apll. document balance.';
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

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update();
    end;

    [Scope('OnPrem')]
    procedure ShowDim()
    begin
        CurrPage.Activate(true);
        ShowDimensions();
    end;
}

