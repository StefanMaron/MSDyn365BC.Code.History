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
        if (Employee."Salespers./Purch. Code" <> '') and
           ((OldEmployee."Salespers./Purch. Code" <> Employee."Salespers./Purch. Code") or
            (OldEmployee.Name <> Employee.Name) or
            (OldEmployee."Second Family Name" <> Employee."Second Family Name") or
            (OldEmployee."First Family Name" <> Employee."First Family Name"))
        then
            SalesPersonUpdate(Employee)
        else
            exit;
    end;

    local procedure SalesPersonUpdate(Employee: Record Employee)
    begin
        SalespersonPurchaser.Get(Employee."Salespers./Purch. Code");
        SalespersonPurchaser.Name := CopyStr(Employee.FullName, 1, 50);
        SalespersonPurchaser.Modify
    end;
}

