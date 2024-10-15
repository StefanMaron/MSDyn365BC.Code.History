codeunit 132219 "Localized Permissions Test"
{

    trigger OnRun()
    begin
    end;

    procedure EnablePermissionTests(): Boolean
    begin
        // Defines if permission level should be changed
        exit(true);
    end;

    procedure EnableD365Build(): Boolean
    begin
        // Specifies if build contains O365 Company
        // O365 Company has significantly less demo data and different scope
        // causing different test execution path
        exit(true);
    end;
}

