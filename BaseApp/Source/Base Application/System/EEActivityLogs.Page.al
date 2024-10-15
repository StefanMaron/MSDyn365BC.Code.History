namespace System.Environment.Configuration;

using System.Integration;
page 3302 "EE Activity Logs"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    Caption = 'Business Event Activity Log';
    PageType = List;
    PopulateAllFields = true;
    Editable = false;

    SourceTable = "External Event Activity Log";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Activity Status';
                    ToolTip = 'Specifies the Activity Status.';
                }
                field(ActivityMessage; Rec."Activity Message")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Activity Message"';
                    ToolTip = 'Specifies the Activity Message".';
                }
                field(NotificationUrl; Rec."Notification Url")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Notification Url"';
                    ToolTip = 'Specifies the Notification Url".';
                }

            }
        }
    }
}