page 7328 "Warehouse Employees"
{
    AdditionalSearchTerms = 'warehouse worker';
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Employees';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Warehouse Employee";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the user ID of a warehouse employee. Each user who performs warehouse activities must be set up as a warehouse employee and assigned to at least one location.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code of the location in which the employee works.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the location code that is defined as the default location for this employee''s activities.';
                }
                field("ADCS User"; Rec."ADCS User")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'ADCS User';
                    ToolTip = 'Specifies the ADCS user name of a warehouse employee.';
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
    }
}

