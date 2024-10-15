namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Foundation.AuditCodes;

pageextension 45 GLSourceCodesExt extends "Source Codes"
{
    actions
    {
        addfirst(Navigation)
        {
            group("&Source")
            {
                Caption = '&Source';
                Image = CodesList;
                action("G/L Registers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Registers';
                    Image = GLRegisters;
                    RunObject = Page "G/L Registers";
                    RunPageLink = "Source Code" = field(Code);
                    RunPageView = sorting("Source Code");
                    ToolTip = 'View posted G/L entries.';
                }
            }
        }
    }
}