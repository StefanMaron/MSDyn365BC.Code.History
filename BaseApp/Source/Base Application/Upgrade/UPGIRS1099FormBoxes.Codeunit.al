#if not CLEAN23
codeunit 104150 "UPG. IRS 1099 Form Boxes"
{
    Subtype = Upgrade;
    ObsoleteReason = 'Not used.';
    ObsoleteState = Pending;
    ObsoleteTag = '23.0';

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
    end;
}
#endif