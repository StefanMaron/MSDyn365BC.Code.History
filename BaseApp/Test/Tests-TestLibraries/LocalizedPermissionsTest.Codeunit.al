codeunit 132219 "Localized Permissions Test"
{
    // This codeunit is only modified in countries, do not change anything in W1!
    // Any W1 changes should go directly into COD132218


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
        exit(false);
    end;
}

