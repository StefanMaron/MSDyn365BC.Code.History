page 31130 "Certificate Code List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Certificate Code List';
    PageType = List;
    SourceTable = "Certificate CZ Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the general identification of the certificate.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the certificate code.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Certificates)
            {
                Caption = 'Certificates';
                Image = Certificate;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Certificate List";
                RunPageLink = "Certificate Code" = FIELD(Code);
                RunPageMode = View;
                RunPageView = ORDER(Descending);
                ApplicationArea = Basic, Suite;
                ToolTip = 'View or edit the certificates that are set up for the certificate code.';
            }
        }
    }
}