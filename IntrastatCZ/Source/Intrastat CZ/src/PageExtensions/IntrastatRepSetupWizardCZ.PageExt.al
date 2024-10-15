pageextension 31376 "Intrastat Rep. Setup Wizard CZ" extends "Intrastat Report Setup Wizard"
{
    layout
    {
        addafter("Default Trans. Type - Returns")
        {
            field("Def. Phys. Trans. - Returns CZ"; Rec."Def. Phys. Trans. - Returns CZ")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the default value of the Physical Movement field for sales returns and service returns, and purchase returns.';
            }
        }
    }
}