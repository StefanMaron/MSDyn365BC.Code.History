tableextension 31351 "Customer CZ" extends Customer
{
    procedure GetDefaultTransactionTypeCZ(IsPhysicalTransfer: Boolean; IsCreditDocType: Boolean): Code[10]
    begin
        if (IsCreditDocType and IsPhysicalTransfer) or
           (not IsCreditDocType and not IsPhysicalTransfer)
        then
            exit("Default Trans. Type - Return");
        exit("Default Trans. Type");
    end;
}