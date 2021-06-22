page 595 "Change Log Entries"
{
    AdditionalSearchTerms = 'user log,user activity,track';
    ApplicationArea = Basic, Suite;
    Caption = 'Change Log Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Change Log Entry";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
                field("Date and Time"; "Date and Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when this change log entry was created.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Table No."; "Table No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the table containing the changed field.';
                    Visible = false;
                }
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the table containing the changed field.';
                }
                field("Primary Key"; "Primary Key")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the primary key or keys of the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 1 No."; "Primary Key Field 1 No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the field number of the first primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 1 Caption"; "Primary Key Field 1 Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the field name of the first primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 1 Value"; "Primary Key Field 1 Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the first primary key for the changed field.';
                }
                field("Primary Key Field 2 No."; "Primary Key Field 2 No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the field number of the second primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 2 Caption"; "Primary Key Field 2 Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the field name of the second primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 2 Value"; "Primary Key Field 2 Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the second primary key for the changed field.';
                }
                field("Primary Key Field 3 No."; "Primary Key Field 3 No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the field number of the third primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 3 Caption"; "Primary Key Field 3 Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the field name of the third primary key for the changed field.';
                    Visible = false;
                }
                field("Primary Key Field 3 Value"; "Primary Key Field 3 Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the third primary key for the changed field.';
                }
                field("Field No."; "Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the field number of the changed field.';
                    Visible = false;
                }
                field("Field Caption"; "Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the field caption of the changed field.';
                }
                field("Type of Change"; "Type of Change")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of change made to the field.';
                }
                field("Old Value"; "Old Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value that the field had before a user made changes to the field.';
                }
                field("Old Value Local"; GetLocalOldValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Old Value (Local)';
                    ToolTip = 'Specifies the value that the field had before a user made changes to the field.';
                }
                field("New Value"; "New Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value that the field had after a user made changes to the field.';
                }
                field("New Value Local"; GetLocalNewValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Value (Local)';
                    ToolTip = 'Specifies the value that the field had after a user made changes to the field.';
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
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    REPORT.Run(REPORT::"Change Log Entries", true, false, Rec);
                end;
            }
            action(Setup)
            {
                ApplicationArea = All;
                Caption = 'Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Change Log Setup";
                ToolTip = 'Enable, disable or setup change logging.';
            }
            action("Delete Entries")
            {
                ApplicationArea = All;
                Caption = 'Delete Entries';
                Image = Delete;
                RunObject = Report "Change Log - Delete";
                ToolTip = 'Find and delete change log entries.';
            }
        }
    }
}

