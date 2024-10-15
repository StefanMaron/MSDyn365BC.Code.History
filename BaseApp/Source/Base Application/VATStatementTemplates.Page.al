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
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the page number.';
                }
                field("VAT Statement Report ID"; "VAT Statement Report ID")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the ID of the report that you can print for the VAT statement template.';
                }
                field("VAT Stat. Export Report ID"; "VAT Stat. Export Report ID")
                {
                    ApplicationArea = VAT;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID of the batch job that must be used to export the annual VAT communication to an ASCII file.';
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
            }
        }
    }
}

