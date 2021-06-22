page 1280 "Bank Clearing Standards"
{
    Caption = 'Bank Clearing Standards';
    PageType = List;
    SourceTable = "Bank Clearing Standard";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the bank clearing standard that you choose in the Bank Clearing Standard field on a company, customer, or vendor bank account card.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the bank clearing standard that you choose in the Bank Clearing Standard field on a company, customer, or vendor bank account card.';
                }
            }
        }
    }

    actions
    {
    }
}

