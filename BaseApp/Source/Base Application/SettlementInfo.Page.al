page 15000011 "Settlement Info"
{
    Caption = 'Settlement Info';
    PageType = Card;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Remittance Handling Ref."; "Remittance Handling Ref.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference that the bank identifies for foreign payments.';
                }
                field("Remittance Warning"; "Remittance Warning")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the journal line contains a warning.';
                }
                field("Remittance Warning Text"; "Remittance Warning Text")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the description of the warning, if applicable.';
                }
            }
        }
    }

    actions
    {
    }
}

