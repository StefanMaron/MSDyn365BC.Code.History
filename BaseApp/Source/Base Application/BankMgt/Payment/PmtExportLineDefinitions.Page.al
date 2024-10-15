namespace Microsoft.Bank.Payment;

using System.IO;

page 1227 "Pmt. Export Line Definitions"
{
    Caption = 'Pmt. Export Line Definitions';
    DelayedInsert = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Data Exch. Line Def";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line in the file.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the mapping setup.';
                }
            }
        }
    }

    actions
    {
    }
}

