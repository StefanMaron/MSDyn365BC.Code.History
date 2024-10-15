codeunit 799 "VAT Reporting Date Mgt"
{
    SingleInstance = true;

    trigger OnRun()
    begin    
    end;

   procedure IsVATDateEnabled(): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not GLSetup.Get() then
            exit(false);

        exit(GLSetup."VAT Reporting Date Usage" <> GLSetup."VAT Reporting Date Usage"::Disabled);
    end;

}