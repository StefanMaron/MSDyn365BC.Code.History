#pragma warning disable AA0247
codeunit 31483 "Create Sales Document CZC"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        CreateSalesCreditMemosToPost();
    end;

    local procedure CreateSalesCreditMemosToPost()
    var
        SalesHeader: Record "Sales Header";
        ContosoSales: Codeunit "Contoso Sales";
        CreateCustomer: Codeunit "Create Customer";
        ContosoUtilities: Codeunit "Contoso Utilities";
        CreatePaymentTerms: Codeunit "Create Payment Terms";
        CreateItem: Codeunit "Create Item";
        CreatePaymentMethod: Codeunit "Create Payment Method";
    begin
        SalesHeader := ContosoSales.InsertSalesHeader(Enum::"Sales Document Type"::"Credit Memo", CreateCustomer.DomesticAdatumCorporation(), '', ContosoUtilities.AdjustDate(19020101D), ContosoUtilities.AdjustDate(19020101D), CreatePaymentTerms.PaymentTermsCOD(), '', ContosoUtilities.AdjustDate(19020101D), CreatePaymentMethod.Cash(), '', ContosoUtilities.AdjustDate(0D), '', '');
        ContosoSales.InsertSalesLineWithItem(SalesHeader, CreateItem.AmsterdamLamp(), 3);
    end;

    procedure PostSalesCreditMemos()
    var
        SalesHeader: Record "Sales Header";
        CreateSalesDocument: Codeunit "Create Sales Document";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetFilter("Your Reference", '<>%1', CreateSalesDocument.OpenYourReference());
        if SalesHeader.Findset() then
            repeat
                Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);
            until SalesHeader.Next() = 0;
    end;
}
