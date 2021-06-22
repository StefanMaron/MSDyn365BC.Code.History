page 1511 "Notification Entries"
{
    ApplicationArea = Suite;
    Caption = 'Notification Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Notification Entry";
    SourceTableView = SORTING("Created Date-Time")
                      ORDER(Ascending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the notification entry.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of notification.';
                }
                field("Recipient User ID"; "Recipient User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who received the notification.';
                }
                field("FORMAT(""Triggered By Record"")"; Format("Triggered By Record"))
                {
                    ApplicationArea = Suite;
                    Caption = 'Triggered By Record';
                    ToolTip = 'Specifies the record that triggered the notification.';
                }
                field("Created Date-Time"; "Created Date-Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time that the notification was created.';
                }
                field("Created By"; "Created By")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who created the notification.';
                }
                field("Error Message"; "Error Message")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies an error that relates to the notification entry.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }
}

