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
        field(2; "Notification Type"; Enum "Notification Entry Type")
        {
            Caption = 'Notification Type';
        }
        field(3; "Notification Method"; Enum "Notification Method Type")
        {
            Caption = 'Notification Method';
        }
        field(5; Schedule; Enum "Notification Schedule Type")
        {
            CalcFormula = Lookup("Notification Schedule".Recurrence WHERE("User ID" = FIELD("User ID"),
                                                                           "Notification Type" = FIELD("Notification Type")));
            Caption = 'Schedule';
            FieldClass = FlowField;
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

    procedure GetNotificationTypeSetup(NotificationType: Enum "Notification Entry Type")
    var
        NotificationManagement: Codeunit "Notification Management";
    begin
        if Get(UserId, NotificationType) then
            exit;
        if Get('', NotificationType) then
            exit;
        NotificationManagement.CreateDefaultNotificationTypeSetup(NotificationType);
        Get('', NotificationType)
    end;

    procedure GetNotificationTypeSetupForUser(NotificationType: Enum "Notification Entry Type"; RecipientUserID: Code[50])
    begin
        if Get(RecipientUserID, NotificationType) then
            exit;
        GetNotificationTypeSetup(NotificationType);
    end;
}

