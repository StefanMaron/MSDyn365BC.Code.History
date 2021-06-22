codeunit 3996 "Reten. Pol. Upgrade - BaseApp"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerCompany()
    var
        RetenPolInstallBaseApp: Codeunit "Reten. Pol. Install - BaseApp";
    begin
        RetenPolInstallBaseApp.AddAllowedTables(); // also sets the tag!
    end;
}