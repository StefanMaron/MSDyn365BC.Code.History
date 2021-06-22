codeunit 131033 "Active Directory Mock Events"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        IsEnabled: Boolean;
        TestEmailTxt: Label 'test@microsoft.com', Comment = 'Locked';

    procedure Enabled(): Boolean
    begin
        exit(IsEnabled);
    end;

    procedure Enable()
    begin
        IsEnabled := true;
    end;

    procedure Disable()
    begin
        IsEnabled := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, 397, 'OnGetEmailAddressFromActiveDirectory', '', false, false)]
    local procedure OnGetEmailAddressFromActiveDirectory(var Email: Text; var Handled: Boolean)
    begin
        if not IsEnabled then
            exit;
        Email := TestEmailTxt;
        Handled := true;
    end;
}

