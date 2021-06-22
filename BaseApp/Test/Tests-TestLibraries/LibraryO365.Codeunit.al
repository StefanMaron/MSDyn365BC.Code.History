codeunit 131922 "Library - O365"
{

    trigger OnRun()
    begin
    end;

    var
        CashTxt: Label 'CASH', Comment = 'Cash';
        PaymentTxt: Label 'PAYMENT', Comment = 'Payment';
        DefaultCustomerTemplateDescriptionTxt: Label 'Cash-Payment / Retail Customer (Cash)';
        DefaultItemTemplateDescriptionTxt: Label 'Service';
        CHECKTxt: Label 'CHECK';
        X14DAYSTxt: Label '14 DAYS';
        DomesticTxt: Label 'DOMESTIC';
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";

    procedure PopulateO365Setup()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        CustomerConfigTemplateHeader: Record "Config. Template Header";
        ItemConfigTemplateHeader: Record "Config. Template Header";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        CustomerConfigTemplateHeader.SetRange(Description, DefaultCustomerTemplateDescriptionTxt);
        if not CustomerConfigTemplateHeader.FindFirst then
            InsertConfigTemplateHeader(CustomerConfigTemplateHeader, DefaultCustomerTemplateDescriptionTxt);
        ItemConfigTemplateHeader.SetRange(Description, DefaultItemTemplateDescriptionTxt);
        if ItemConfigTemplateHeader.FindFirst then;

        with O365SalesInitialSetup do begin
            Init;
            Validate("Default Payment Method Code", CHECKTxt);
            Validate("Default Payment Terms Code", X14DAYSTxt);
            Validate("Tax Type", "Tax Type"::VAT);
            Validate("Default VAT Bus. Posting Group", DomesticTxt);

            if VATProductPostingGroup.FindSet then
                Validate("Normal VAT Prod. Posting Gr.", VATProductPostingGroup.Code);
            if VATProductPostingGroup.Next <> 0 then
                Validate("Reduced VAT Prod. Posting Gr.", VATProductPostingGroup.Code);
            if VATProductPostingGroup.Next <> 0 then
                Validate("Zero VAT Prod. Posting Gr.", VATProductPostingGroup.Code);

            Validate("Sales Quote No. Series", LibraryERM.CreateNoSeriesCode);
            Validate("Sales Invoice No. Series", LibraryERM.CreateNoSeriesCode);
            Validate("Posted Sales Inv. No. Series", LibraryERM.CreateNoSeriesCode);

            Validate("Payment Reg. Template Name", PaymentTxt);
            Validate("Payment Reg. Batch Name", CashTxt);
            Validate("Default Customer Template", CustomerConfigTemplateHeader.Code);
            Validate("Default Item Template", ItemConfigTemplateHeader.Code);

            Insert(true);
        end;
    end;

    local procedure InsertConfigTemplateHeader(var ConfigTemplateHeader: Record "Config. Template Header"; TemplateDescription: Text[50])
    begin
        ConfigTemplateHeader.Code :=
          LibraryUtility.GenerateRandomCode(ConfigTemplateHeader.FieldNo(Code), DATABASE::"Config. Template Header");
        ConfigTemplateHeader.Validate(Description, TemplateDescription);
        ConfigTemplateHeader.Validate("Table ID", DATABASE::Customer);
        ConfigTemplateHeader.Insert();
    end;
}

