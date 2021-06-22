codeunit 280 "My Records Demo Setup"
{
    Permissions = TableData Customer = r,
                  TableData Vendor = r,
                  TableData Item = r,
                  TableData "My Customer" = rimd,
                  TableData "My Vendor" = rimd,
                  TableData "My Item" = rimd,
                  TableData "My Account" = rimd;

    trigger OnRun()
    begin
    end;

    local procedure SetupMyRecords()
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if not CompanyInformationMgt.IsDemoCompany then
            exit;

        if SetupMyCustomer then
            exit;

        if SetupMyItem then
            exit;

        if SetupMyVendor then
            exit;

        SetupMyAccount;
    end;

    local procedure SetupMyCustomer(): Boolean
    var
        Customer: Record Customer;
        MyCustomer: Record "My Customer";
        MaxCustomersToAdd: Integer;
        I: Integer;
    begin
        if not Customer.ReadPermission then
            exit;

        MyCustomer.SetRange("User ID", UserId);
        if not MyCustomer.IsEmpty then
            exit(true);

        I := 0;
        MaxCustomersToAdd := 5;
        Customer.SetFilter(Balance, '<>0');
        if Customer.FindSet then
            repeat
                I += 1;
                MyCustomer."User ID" := UserId;
                MyCustomer.Validate("Customer No.", Customer."No.");
                if MyCustomer.Insert() then;
            until (Customer.Next = 0) or (I >= MaxCustomersToAdd);
    end;

    local procedure SetupMyItem(): Boolean
    var
        Item: Record Item;
        MyItem: Record "My Item";
        MaxItemsToAdd: Integer;
        I: Integer;
    begin
        if not Item.ReadPermission then
            exit;

        MyItem.SetRange("User ID", UserId);
        if not MyItem.IsEmpty then
            exit(true);

        I := 0;
        MaxItemsToAdd := 5;

        Item.SetFilter("Unit Price", '<>0');
        if Item.FindSet then
            repeat
                I += 1;
                MyItem."User ID" := UserId;
                MyItem.Validate("Item No.", Item."No.");
                if MyItem.Insert() then;
            until (Item.Next = 0) or (I >= MaxItemsToAdd);
    end;

    local procedure SetupMyVendor(): Boolean
    var
        Vendor: Record Vendor;
        MyVendor: Record "My Vendor";
        MaxVendorsToAdd: Integer;
        I: Integer;
    begin
        if not Vendor.ReadPermission then
            exit;

        MyVendor.SetRange("User ID", UserId);
        if not MyVendor.IsEmpty then
            exit(true);

        I := 0;
        MaxVendorsToAdd := 5;
        Vendor.SetFilter(Balance, '<>0');
        if Vendor.FindSet then
            repeat
                I += 1;
                MyVendor."User ID" := UserId;
                MyVendor.Validate("Vendor No.", Vendor."No.");
                if MyVendor.Insert() then;
            until (Vendor.Next = 0) or (I >= MaxVendorsToAdd);
    end;

    local procedure SetupMyAccount(): Boolean
    var
        GLAccount: Record "G/L Account";
        MyAccount: Record "My Account";
        MaxAccountsToAdd: Integer;
        I: Integer;
    begin
        if not GLAccount.ReadPermission then
            exit;

        MyAccount.SetRange("User ID", UserId);
        if not MyAccount.IsEmpty then
            exit(true);

        I := 0;
        MaxAccountsToAdd := 5;
        GLAccount.SetRange("Reconciliation Account", true);
        if GLAccount.FindSet then
            repeat
                I += 1;
                MyAccount."User ID" := UserId;
                MyAccount.Validate("Account No.", GLAccount."No.");
                if MyAccount.Insert() then;
            until (GLAccount.Next = 0) or (I >= MaxAccountsToAdd);
    end;

    [EventSubscriber(ObjectType::Codeunit, 40, 'OnAfterLogInStart', '', false, false)]
    local procedure OnAfterLogInStartSubscriber()
    begin
        SetupMyRecords();
    end;
}