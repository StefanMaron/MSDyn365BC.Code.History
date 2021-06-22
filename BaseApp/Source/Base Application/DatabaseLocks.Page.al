page 9511 "Database Locks"
{
    Caption = 'Database Locks';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Database Locks";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("SQL Session ID"; "SQL Session ID")
                {
                    ApplicationArea = All;
                    Caption = 'SQL Session ID';
                    ToolTip = 'Specifies the session ID.';
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;
                    Caption = 'Table name';
                    ToolTip = 'Specifies the name of table on which the lock request was done.';
                }
                field("Resource Type"; "Resource Type")
                {
                    ApplicationArea = All;
                    Caption = 'SQL Lock Resource Type';
                    ToolTip = 'Specifies the database resource affected by the SQL lock';
                }
                field("Request Mode"; "Request Mode")
                {
                    ApplicationArea = All;
                    Caption = 'SQL Lock Request Mode';
                    ToolTip = 'Specifies the SQL lock request mode that determines how concurrent transactions can access the resource. For granted requests, this is the granted mode; for waiting requests, this is the mode being requested.';
                }
                field("Request Status"; "Request Status")
                {
                    ApplicationArea = All;
                    Caption = 'SQL Lock Request Status';
                    ToolTip = 'Specifies the SQL lock request status.';
                }
                field("User Name"; "User Name")
                {
                    ApplicationArea = All;
                    Caption = 'User Name';
                    ToolTip = 'Specifies the user that has requested the SQL lock.';
                }
                field("AL Object Type"; "AL Object Type")
                {
                    ApplicationArea = All;
                    Caption = 'Executing AL Object Type';
                    ToolTip = 'Specifies the AL object type that is executed in the context of the SQL lock.';
                }
                field("AL Object Id"; "AL Object Id")
                {
                    ApplicationArea = All;
                    Caption = 'Executing AL Object ID';
                    ToolTip = 'Specifies the AL object ID that is executed in the context of the SQL lock.';
                }
                field("AL Method Scope"; "AL Method Scope")
                {
                    ApplicationArea = All;
                    Caption = 'Executing AL Method';
                    ToolTip = 'Specifies the AL method that is executed in the context of the given AL object.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        Notification: Notification;
    begin
        Notification.Message := DatabaseLocksPageMsg;
        Notification.Send();
    end;

    var
        DatabaseLocksPageMsg: Label 'This page shows a snapshot of all database locks. Where possible, it displays details on the AL session that is causing the SQL lock.';
}

