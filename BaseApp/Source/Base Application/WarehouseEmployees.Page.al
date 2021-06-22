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
                field("User ID"; "User ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location in which the employee works.';
                }
                field(Default; Default)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the location code that is defined as the default location for this employee''s activities.';
                }
                field("ADCS User"; "ADCS User")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'ADCS User';
                    ToolTip = 'Specifies the ADCS user name of a warehouse employee.';
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

