#pragma warning disable AA0247
codeunit 31486 "Create Search Rule CZB"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        SearchRuleCZB: Record "Search Rule CZB";
        ContosoBankDocumentsCZB: Codeunit "Contoso Bank Documents CZB";
    begin
        ContosoBankDocumentsCZB.InsertSearchRule(Default(), DefaultMatchingRulesLbl, true);
        if SearchRuleCZB.Get(Default()) then
            SearchRuleCZB.CreateDefaultLines();
    end;

    procedure Default(): Code[10]
    begin
        exit(DefaultTok);
    end;

    var
        DefaultTok: Label 'Default', MaxLength = 10;
        DefaultMatchingRulesLbl: Label 'Default matching rules', MaxLength = 100;
}
