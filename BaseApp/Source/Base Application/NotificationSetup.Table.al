table 1512 "Notification Setup"
{
    Caption = 'Notification Setup';
    DrillDownPageID = "Notification Setup";
    LookupPageID = "Notification Setup";
    ReplicateData = false;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(2; "Notification Type"; Option)
        {
            Caption = 'Notification Type';
            OptionCaption = 'New Record,Approval,Overdue';
            OptionMembers = "New Record",Approval,Overdue;
        }
        field(3; "Notification Method"; Option)
        {
            Caption = 'Notification Method';
            OptionCaption = 'Email,Note';
            OptionMembers = Email,Note;
        }
        field(5; Schedule; Option)
        {
            CalcFormula = Lookup ("Notification Schedule".Recurrence WHERE("User ID" = FIELD("User ID"),
                                                                           "Notification Type" = FIELD("Notification Type")));
            Caption = 'Schedule';
            FieldClass = FlowField;
            OptionCaption = 'Instantly,Daily,Weekly,Monthly';
            OptionMembers = Instantly,Daily,Weekly,Monthly;
        }
        field(6; "Display Target"; Option)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'The Windows client is discontinued.';
            Caption = 'Display Target';
            OptionCaption = 'Web,Windows';
            OptionMembers = Web,Windows;
            ObsoleteTag = '15.0';
        }
    }

    keys
    {
        key(Key1; "User ID", "Notification Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        NotificationSchedule: Record "Notification Schedule";
    begin
        if NotificationSchedule.Get("User ID", "Notification Type") then
            NotificationSchedule.Delete(true);
    end;

    procedure GetNotificationSetup(NotificationType: Option "New Record",Approval,Overdue)
    var
        NotificationManagement: Codeunit "Notification Management";
    begin
        if Get(UserId, NotificationType) then
            exit;
        if Get('', NotificationType) then
            exit;
        NotificationManagement.CreateDefaultNotificationSetup(NotificationType);
        Get('', NotificationType)
    end;

    procedure GetNotificationSetupForUser(NotificationType: Option "New Record",Approval,Overdue; RecipientUserID: Code[50])
    begin
        if Get(RecipientUserID, NotificationType) then
            exit;
        GetNotificationSetup(NotificationType);
    end;
}

