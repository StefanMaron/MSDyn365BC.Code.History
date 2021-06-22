page 293 "Req. Worksheet Templates"
{
    AdditionalSearchTerms = 'supply planning template,mrp template,mps template';
    ApplicationArea = Planning;
    Caption = 'Requisition Worksheet Templates';
    PageType = List;
    SourceTable = "Req. Wksh. Template";
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
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the name of the requisition worksheet template you are creating.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a description of the requisition worksheet template you are creating.';
                }
                field(Recurring; Recurring)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies whether the requisition worksheet template will be a recurring requisition worksheet.';
                }
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = Planning;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; "Page Caption")
                {
                    ApplicationArea = Planning;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
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
                action("Requisition Worksheet Names")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheet Names';
                    Image = Description;
                    RunObject = Page "Req. Wksh. Names";
                    RunPageLink = "Worksheet Template Name" = FIELD(Name);
                    ToolTip = 'View the list worksheets that are set up to handle requisition planning.';
                }
            }
        }
    }
}

