codeunit 799 "VAT Reporting Date Mgt"
{
    SingleInstance = true;

    trigger OnRun()
    begin    
    end;

    internal procedure IsVATDateUsageSetToPostingDate() IsPostingDate: Boolean
    begin
        IsPostingDate := true;
    end;

    internal procedure IsVATDateUsageSetToDocumentDate() IsDocumentDate: Boolean
    begin
        IsDocumentDate := false;    
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