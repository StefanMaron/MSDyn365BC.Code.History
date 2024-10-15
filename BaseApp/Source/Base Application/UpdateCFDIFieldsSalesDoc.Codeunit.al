codeunit 27032 "Update CFDI Fields Sales Doc"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Service Invoice Header" = rm,
                  TableData "Service Cr.Memo Header" = rm;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCFDIPurposeRelationFieldsDocUpdateTag) then
            exit;

        UpdateSalesDocuments;
        UpdateServiceDocuments;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCFDIPurposeRelationFieldsDocUpdateTag);
    end;

    local procedure UpdateSalesDocuments()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        Customer.SetFilter("CFDI Purpose", '<>%1', '');
        if Customer.IsEmpty then
            exit;

        Customer.FindSet;
        repeat
            SalesHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not SalesHeader.IsEmpty then begin
                SalesHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                SalesHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;

            SalesHeader.SetRange("Bill-to Customer No.", '');
            SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
            if not SalesHeader.IsEmpty then begin
                SalesHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                SalesHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;

            SalesInvoiceHeader.SetFilter(
              "Electronic Document Status", '%1|%2|%3',
              SalesInvoiceHeader."Electronic Document Status"::" ",
              SalesInvoiceHeader."Electronic Document Status"::"Stamp Request Error",
              SalesInvoiceHeader."Electronic Document Status"::"Cancel Error");
            SalesInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not SalesInvoiceHeader.IsEmpty then
                SalesInvoiceHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
            SalesInvoiceHeader.SetRange("Bill-to Customer No.", '');
            SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
            if not SalesInvoiceHeader.IsEmpty then
                SalesInvoiceHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");

            SalesCrMemoHeader.SetFilter(
              "Electronic Document Status", '%1|%2|%3',
              SalesCrMemoHeader."Electronic Document Status"::" ",
              SalesCrMemoHeader."Electronic Document Status"::"Stamp Request Error",
              SalesCrMemoHeader."Electronic Document Status"::"Cancel Error");
            SalesCrMemoHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not SalesCrMemoHeader.IsEmpty then begin
                SalesCrMemoHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                SalesCrMemoHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;
            SalesCrMemoHeader.SetRange("Bill-to Customer No.", '');
            SalesCrMemoHeader.SetRange("Sell-to Customer No.", Customer."No.");
            if not SalesCrMemoHeader.IsEmpty then begin
                SalesCrMemoHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                SalesCrMemoHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;
        until Customer.Next = 0;
    end;

    local procedure UpdateServiceDocuments()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        Customer.SetFilter("CFDI Purpose", '<>%1', '');
        if Customer.IsEmpty then
            exit;

        Customer.FindSet;
        repeat
            ServiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not ServiceHeader.IsEmpty then begin
                ServiceHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                ServiceHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;

            ServiceInvoiceHeader.SetFilter(
              "Electronic Document Status", '%1|%2|%3',
              ServiceInvoiceHeader."Electronic Document Status"::" ",
              ServiceInvoiceHeader."Electronic Document Status"::"Stamp Request Error",
              ServiceInvoiceHeader."Electronic Document Status"::"Cancel Error");
            ServiceInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not ServiceInvoiceHeader.IsEmpty then
                ServiceInvoiceHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");

            ServiceCrMemoHeader.SetFilter(
              "Electronic Document Status", '%1|%2|%3',
              ServiceCrMemoHeader."Electronic Document Status"::" ",
              ServiceCrMemoHeader."Electronic Document Status"::"Stamp Request Error",
              ServiceCrMemoHeader."Electronic Document Status"::"Cancel Error");
            ServiceCrMemoHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not ServiceCrMemoHeader.IsEmpty then begin
                ServiceCrMemoHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                ServiceCrMemoHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;
        until Customer.Next = 0;
    end;
}

