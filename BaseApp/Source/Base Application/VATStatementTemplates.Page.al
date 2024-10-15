page 318 "VAT Statement Templates"
{
    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the VAT statement template you are about to create.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT statement template.';
                }
                field("Allow Comments/Attachments"; "Allow Comments/Attachments")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the possibillity to allow or not allow comments or attachments insert.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
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
                    ApplicationArea = Basic, Suite;
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
                    ToolTip = 'Specifies a set of VAT attributes to use in this VAT Statement Template.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
            }
        }
    }
}

