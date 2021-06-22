codeunit 9165 "Help & Support Management"
{
    Permissions = TableData "Support Contact Information" = rimd;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000006, 'GetSupportInformation', '', true, true)]
    [Scope('OnPrem')]
    procedure GetSupportInformation(var Name: Text; var Email: Text; var Url: Text)
    var
        SupportContactInformation: Record "Support Contact Information";
    begin
        OnBeforeGetSupportInformation(Name, Email, Url);

        if (Name <> '') or (Email <> '') or (Url <> '') then
            exit;

        if not SupportContactInformation.ReadPermission then
            exit;

        if not SupportContactInformation.Get then
            exit;

        Name := SupportContactInformation.Name;
        Email := SupportContactInformation.Email;
        Url := SupportContactInformation.URL;
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000006, 'OpenLastErrorPage', '', true, true)]
    local procedure OpenLastError()
    begin
        PAGE.Run(PAGE::"Latest Error");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSupportInformation(var SupportName: Text; var SupportEmail: Text; var SupportUrl: Text)
    begin
    end;
}

