page 31130 "Certificates CZ Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Certificates Codes';
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
                    ToolTip = 'Specifies the code for the general identification of the certificate.';
                }
                field(Description; Description)
                {
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
                RunObject = Page "Certificates CZ";
                RunPageLink = "Certificate Code" = FIELD(Code);
                RunPageMode = View;
                RunPageView = ORDER(Descending);
                ToolTip = 'View or edit the certificates that are set up for the certificate code.';
            }
        }
    }
}

