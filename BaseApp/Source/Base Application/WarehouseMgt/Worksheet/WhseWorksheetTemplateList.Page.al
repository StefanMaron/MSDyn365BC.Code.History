namespace Microsoft.Warehouse.Worksheet;

page 7366 "Whse. Worksheet Template List"
{
    Caption = 'Whse. Worksheet Template List';
    Editable = false;
    PageType = List;
    SourceTable = "Whse. Worksheet Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the name you enter for the warehouse worksheet template you are creating.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the warehouse worksheet template you are creating.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies information about the activity you can plan in the warehouse worksheets that will be defined by this template.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
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
                action(Names)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Names';
                    Image = Description;
                    RunObject = Page "Whse. Worksheet Names";
                    RunPageLink = "Worksheet Template Name" = field(Name);
                    ToolTip = 'View the list of available template names.';
                }
            }
        }
    }
}

