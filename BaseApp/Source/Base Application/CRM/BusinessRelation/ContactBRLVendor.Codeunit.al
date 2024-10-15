namespace Microsoft.CRM.BusinessRelation;

using Microsoft.Purchases.Vendor;

codeunit 5559 "Contact BRL Vendor" implements "Contact Business Relation Link"
{

    procedure GetTableAndSystemId(No: Code[20]; var TableId: Integer; var SystemId: Guid): Boolean
    var
        Vendor: Record Vendor;
    begin
        TableId := Database::Vendor;
        Vendor.SetRange("No.", No);
        Vendor.FindFirst();
        SystemId := Vendor.SystemId;
        exit(Vendor.Count() = 1);
    end;
}
