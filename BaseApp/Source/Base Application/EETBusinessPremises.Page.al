page 31121 "EET Business Premises"
{
    Caption = 'EET Business Premises';
    PageType = List;
    SourceTable = "EET Business Premises";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the premises.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the premises.';
                }
                field(Identification; Identification)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification number of the promises.';
                }
                field("Certificate Code"; "Certificate Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the certificate needed to register sales.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Cash Registers")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Registers';
                Image = ElectronicPayment;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "EET Cash Registers";
                RunPageLink = "Business Premises Code" = FIELD(Code);
                ToolTip = 'Displays a list of POS devices assigned to the promises.';
            }
        }
    }
}

