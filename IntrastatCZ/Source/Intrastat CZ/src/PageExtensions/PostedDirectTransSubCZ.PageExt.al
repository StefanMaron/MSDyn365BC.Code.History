pageextension 31336 "Posted Direct Trans. Sub. CZ" extends "Posted Direct Transfer Subform"
{
    layout
    {
        addafter(Quantity)
        {
            field("Statistic Indication CZ"; Rec."Statistic Indication CZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the statistic indication code.';
                Visible = false;
            }
        }
    }
}