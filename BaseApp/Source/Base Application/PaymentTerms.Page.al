page 4 "Payment Terms"
{
    AdditionalSearchTerms = 'payment conditions';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Terms';
    PageType = List;
    SourceTable = "Payment Terms";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify this set of payment terms.';
                }
                field("Payment Nos."; "Payment Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of installments allowed for this payment term.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an explanation of the payment terms.';
                }
                field("Fattura Payment Terms Code"; "Fattura Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment terms for Fattura payments.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Calculation")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Calculation';
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Payment Terms Lines";
                RunPageLink = Type = CONST("Payment Terms"),
                              Code = FIELD(Code);
                ToolTip = 'View or edit the conditions of the current payment term.';
            }
            action("T&ranslation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T&ranslation';
                Image = Translation;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Payment Term Translations";
                RunPageLink = "Payment Term" = FIELD(Code);
                ToolTip = 'View or edit descriptions for each payment method in different languages.';
            }
        }
    }

    var
        FatturaCode: Record "Fattura Code";
}

