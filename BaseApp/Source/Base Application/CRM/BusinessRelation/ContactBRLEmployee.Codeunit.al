namespace Microsoft.CRM.BusinessRelation;

using Microsoft.HumanResources.Employee;

codeunit 5560 "Contact BRL Employee" implements "Contact Business Relation Link"
{

    procedure GetTableAndSystemId(No: Code[20]; var TableId: Integer; var SystemId: Guid): Boolean
    var
        Employee: Record Employee;
    begin
        TableId := Database::Employee;
        Employee.SetRange("No.", No);
        Employee.FindFirst();
        SystemId := Employee.SystemId;
        exit(Employee.Count() = 1);
    end;
}