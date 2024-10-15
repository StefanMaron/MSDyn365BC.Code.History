pageextension 18841 "Sales Order TCS" extends "Sales Order"
{
    layout
    {
        addlast("Invoice Details")
        {
            field("Applies-to Doc. Type"; "Applies-to Doc. Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of the posted document that this document line will be applied to.';
            }
            field("Applies-to Doc. No."; "Applies-to Doc. No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the posted document that this document line will be applied to.';
            }
        }
    }
}