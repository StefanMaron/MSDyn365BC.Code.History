pageextension 31344 "Intrastat Report CZ" extends "Intrastat Report"
{
    layout
    {
        addlast(General)
        {
            field("Statement Type CZ"; Rec."Statement Type CZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the statement type of the Intrastat Report.';

                trigger OnValidate()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }
}