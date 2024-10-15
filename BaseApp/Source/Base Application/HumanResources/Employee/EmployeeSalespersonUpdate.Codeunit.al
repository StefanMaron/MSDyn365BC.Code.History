namespace Microsoft.HumanResources.Employee;

using Microsoft.CRM.Team;

codeunit 5201 "Employee/Salesperson Update"
{
    Permissions = TableData "Salesperson/Purchaser" = rimd;

    trigger OnRun()
    begin
    end;

    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";

    procedure HumanResToSalesPerson(OldEmployee: Record Employee; Employee: Record Employee)
    begin
        if ShouldRunUpdate(OldEmployee, Employee) then
            SalesPersonUpdate(Employee)
        else
            exit;
    end;

    local procedure ShouldRunUpdate(OldEmployee: Record Employee; Employee: Record Employee) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldRunUpdate(OldEmployee, Employee, Result, IsHandled);
        if not IsHandled then
            Result := (Employee."Salespers./Purch. Code" <> '') and
                    ((OldEmployee."Salespers./Purch. Code" <> Employee."Salespers./Purch. Code") or
                        (OldEmployee.Name <> Employee.Name) or
                        (OldEmployee."Second Family Name" <> Employee."Second Family Name") or
                        (OldEmployee."First Family Name" <> Employee."First Family Name"));
        OnAfterShouldRunUpdate(OldEmployee, Employee, Result);
    end;

    local procedure SalesPersonUpdate(Employee: Record Employee)
    begin
        SalespersonPurchaser.Get(Employee."Salespers./Purch. Code");
        SalespersonPurchaser.Name := CopyStr(Employee.FullName(), 1, 50);
        OnSalesPersonUpdateOnBeforeModify(Employee, SalespersonPurchaser);
        SalespersonPurchaser.Modify();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterShouldRunUpdate(OldEmployee: Record Employee; Employee: Record Employee; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnSalesPersonUpdateOnBeforeModify(Employee: Record Employee; var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeShouldRunUpdate(OldEmployee: Record Employee; Employee: Record Employee; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

