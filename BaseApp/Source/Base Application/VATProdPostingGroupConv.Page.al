page 551 "VAT Prod. Posting Group Conv."
{
    AdditionalSearchTerms = 'vat value added tax product posting group conversion';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Prod. Posting Group Conv.';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "VAT Rate Change Conversion";
    SourceTableView = WHERE(Type = CONST("VAT Prod. Posting Group"));
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("From Code"; "From Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current VAT product posting group that will be changed in connection with the VAT rate conversion.';
                }
                field("To Code"; "To Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new VAT product posting group that will result from the conversion in connection with the VAT rate conversion.';
                }
                field("Converted Date"; "Converted Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the VAT rate change conversion was performed.';
                }
            }
        }
    }

    actions
    {
    }
}

