pageextension 18810 "G/L Registers" extends "G/L Registers"
{
    actions
    {
        addafter("Item Ledger Relation")
        {
            action("TCS Entries")
            {
                ApplicationArea = Basic, Suite;
                Image = CollectedTax;
                ToolTip = 'TCS entries shows the invoice wise details for TCS amount.';
                trigger OnAction()
                var
                    TCSManagement: Codeunit "TCS Management";
                begin
                    TCSManagement.OpenTCSEntries("From Entry No.", "To Entry No.");
                end;
            }
        }
    }
}