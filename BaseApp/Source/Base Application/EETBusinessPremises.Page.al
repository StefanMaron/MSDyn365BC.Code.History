#if not CLEAN18
page 31121 "EET Business Premises"
{
    Caption = 'EET Business Premises (Obsolete)';
    PageType = List;
    SourceTable = "EET Business Premises";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

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
#endif