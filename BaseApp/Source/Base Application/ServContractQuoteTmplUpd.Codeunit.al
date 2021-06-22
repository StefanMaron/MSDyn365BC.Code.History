codeunit 5942 "ServContractQuote-Tmpl. Upd."
{
    TableNo = "Service Contract Header";

    trigger OnRun()
    begin
        ServiceContractTemplate.Reset();
        if not ServiceContractTemplate.FindFirst then
            exit;

        TestField("Contract No.");

        if PAGE.RunModal(PAGE::"Service Contract Template List", ServiceContractTemplate) = ACTION::LookupOK then
            ApplyTemplate(Rec, ServiceContractTemplate);
    end;

    var
        ServiceContractTemplate: Record "Service Contract Template";

    procedure ApplyTemplate(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractTemplate: Record "Service Contract Template")
    var
        ContractServiceDiscount: Record "Contract/Service Discount";
        TemplateContractServiceDiscount: Record "Contract/Service Discount";
    begin
        OnBeforeApplyTemplate(ServiceContractHeader, ServiceContractTemplate);
        with ServiceContractHeader do begin
            Description := ServiceContractTemplate.Description;
            Validate("Contract Group Code", ServiceContractTemplate."Contract Group Code");
            Validate("Service Order Type", ServiceContractTemplate."Service Order Type");
            Validate("Service Period", ServiceContractTemplate."Default Service Period");
            Validate("Price Update Period", ServiceContractTemplate."Price Update Period");
            Validate("Response Time (Hours)", ServiceContractTemplate."Default Response Time (Hours)");
            Validate("Max. Labor Unit Price", ServiceContractTemplate."Max. Labor Unit Price");
            Validate("Invoice after Service", ServiceContractTemplate."Invoice after Service");
            Validate("Invoice Period", ServiceContractTemplate."Invoice Period");
            Validate("Price Inv. Increase Code", ServiceContractTemplate."Price Inv. Increase Code");
            Validate("Allow Unbalanced Amounts", ServiceContractTemplate."Allow Unbalanced Amounts");
            Validate("Contract Lines on Invoice", ServiceContractTemplate."Contract Lines on Invoice");
            Validate("Combine Invoices", ServiceContractTemplate."Combine Invoices");
            Validate("Automatic Credit Memos", ServiceContractTemplate."Automatic Credit Memos");
            Validate(Prepaid, ServiceContractTemplate.Prepaid);
            Validate("Serv. Contract Acc. Gr. Code", ServiceContractTemplate."Serv. Contract Acc. Gr. Code");
            "Template No." := ServiceContractTemplate."No.";

            CreateDim(
              DATABASE::"Service Contract Template", ServiceContractTemplate."No.",
              0, '', 0, '', 0, '', 0, '');
            CreateDim(
              DATABASE::"Service Contract Template", "Template No.",
              DATABASE::Customer, "Bill-to Customer No.",
              DATABASE::"Salesperson/Purchaser", "Salesperson Code",
              DATABASE::"Responsibility Center", "Responsibility Center",
              DATABASE::"Service Order Type", "Service Order Type");

            ContractServiceDiscount.Reset();
            ContractServiceDiscount.SetRange("Contract Type", "Contract Type");
            ContractServiceDiscount.SetRange("Contract No.", "Contract No.");
            ContractServiceDiscount.DeleteAll();

            TemplateContractServiceDiscount.Reset();
            TemplateContractServiceDiscount.SetRange("Contract Type", TemplateContractServiceDiscount."Contract Type"::Template);
            TemplateContractServiceDiscount.SetRange("Contract No.", ServiceContractTemplate."No.");
            if TemplateContractServiceDiscount.Find('-') then
                repeat
                    ContractServiceDiscount := TemplateContractServiceDiscount;
                    ContractServiceDiscount."Contract Type" := "Contract Type";
                    ContractServiceDiscount."Contract No." := "Contract No.";
                    ContractServiceDiscount.Insert();
                until TemplateContractServiceDiscount.Next = 0;
        end;
        OnAfterApplyTemplate(ServiceContractHeader, ServiceContractTemplate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyTemplate(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractTemplate: Record "Service Contract Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyTemplate(var ServiceContractHeader: Record "Service Contract Header"; ServiceContractTemplate: Record "Service Contract Template")
    begin
    end;
}

