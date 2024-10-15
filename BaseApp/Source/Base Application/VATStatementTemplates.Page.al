page 318 "VAT Statement Templates"
{
    ApplicationArea = VAT;
    Caption = 'VAT Statement Templates';
    PageType = List;
    SourceTable = "VAT Statement Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the name of the VAT statement template you are about to create.';
                }
                field(Description; Description)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a description of the VAT statement template.';
                }
                field("XML Format"; "XML Format")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the XML format for VAT statement reporting.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The file format DPHDP2 is deprecated. Only the DPHDP3 format will be supported. This field will be removed and should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Allow Comments/Attachments"; "Allow Comments/Attachments")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the possibillity to allow or not allow comments or attachments insert.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                action("Statement Names")
                {
                    ApplicationArea = VAT;
                    Caption = 'Statement Names';
                    Image = List;
                    RunObject = Page "VAT Statement Names";
                    RunPageLink = "Statement Template Name" = FIELD(Name);
                    ToolTip = 'View or edit special tables to manage the tasks necessary for settling Tax and reporting to the customs and tax authorities.';
                }
                action("VAT Attribute Codes")
                {
                    ApplicationArea = VAT;
                    Caption = 'VAT Attribute Codes';
                    Image = List;
                    RunObject = Page "VAT Attribute Codes";
                    RunPageLink = "VAT Statement Template Name" = FIELD(Name);
                    ToolTip = 'Specifies vat statement templates';
                }
            }
        }
    }
}

