codeunit 10627 "E-Invoice Exp. Serv. Cr. Memo"
{
    Permissions = TableData "Service Cr.Memo Header" = rm;
    TableNo = "Service Cr.Memo Header";

    trigger OnRun()
    var
        TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary;
        TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary;
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        // check section
        ServiceCrMemoLine.SetRange("Document No.", "No.");
        ServiceCrMemoLine.SetFilter(Type, '>%1', 0);
        ServiceCrMemoLine.SetFilter("No.", '<>%1', ' ');
        if not ServiceCrMemoLine.FindSet then
            exit;

        CODEUNIT.Run(CODEUNIT::"E-Invoice Check Serv. Cr. Memo", Rec);

        // transfer data section
        FillHeaderTableData(TempEInvoiceExportHeader, Rec);
        repeat
            if not IsRoundingLine(ServiceCrMemoLine) then
                FillLineTableData(TempEInvoiceExportLine, ServiceCrMemoLine);
        until ServiceCrMemoLine.Next = 0;

        // export section
        ExportToXML(TempEInvoiceExportHeader, TempEInvoiceExportLine);
        ModifyServiceCrMemoHeader("No.");
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;

    [Scope('OnPrem')]
    procedure GetExportedFileInfo(var EInvoiceTransferFile: Record "E-Invoice Transfer File")
    begin
        EInvoiceTransferFile := TempEInvoiceTransferFile;
    end;

    local procedure ExportToXML(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary; var TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary)
    var
        EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
    begin
        // initialize
        with EInvoiceExportCommon do begin
            SetEInvoiceCommonTables(TempEInvoiceExportHeader, TempEInvoiceExportLine);

            // common
            CreateDocAndRootNode;
            AddHeaderCommonContent;
            AddHeaderNote;
            AddHeaderDocumentCurrencyCode;
            AddHeaderTaxCurrencyCode;
            AddHeaderBillingReference;
            AddHeaderAccountingSupplierParty;
            AddHeaderAccountingCustomerParty;
            AddDelivery;
            AddHeaderTaxExchangeRate;
            AddHeaderAllowanceCharge;
            AddHeaderTaxTotal;
            AddHeaderLegalMonetaryTotal;

            // Common for invoice and credit memo header
            TempEInvoiceExportLine.FindSet;

            repeat
                CreateLineNode(TempEInvoiceExportLine);
                AddLineInvCrMemoCommonContent;
                AddDelivery;
                AddLineTaxTotal;
                AddLineItem;
                AddLinePrice;
            until TempEInvoiceExportLine.Next = 0;

            // Save file
            ServiceMgtSetup.Get();
            SaveToXML(TempEInvoiceTransferFile, ServiceMgtSetup."E-Invoice Serv. Cr. Memo Path", TempEInvoiceExportHeader."No.");
        end;
    end;

    local procedure FillHeaderTableData(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary; ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        ServiceCommentLine: Record "Service Comment Line";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
    begin
        with TempEInvoiceExportHeader do begin
            Init;

            // header fields related to the source table
            TransferFields(ServiceCrMemoHeader);

            // calculated fields
            if "Currency Code" = '' then begin
                GLSetup.Get();
                "Currency Code" := GLSetup."LCY Code";
            end;

            if ServiceCrMemoHeader."Applies-to Doc. Type" = ServiceCrMemoHeader."Applies-to Doc. Type"::Invoice then
                "Document No." := ServiceCrMemoHeader."Applies-to Doc. No."
            else
                "Document No." := ServiceCrMemoHeader."External Document No.";

            // header fields not related to the source table
            "Schema Name" := 'CreditNote';
            "Schema Location" := 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2 UBL-CreditNote-2.0.xsd';
            xmlns :=
              'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2';
            "Customization ID" := GetCustomizationID(ServiceCrMemoHeader);
            "Profile ID" := 'urn:www.cenbii.eu:profile:bii05:ver2.0';
            "Uses Common Aggregate Comp." := true;
            "Uses Common Basic Comp." := true;
            "Uses Common Extension Comp." := false;
            "Quantity Name" := 'CreditedQuantity';

            // header fields related to tax amounts
            FillHeaderTaxAmounts(TempEInvoiceExportHeader);

            // custom
            "Shipment Date" := ServiceCrMemoHeader."Delivery Date";
            "Bill-to Country/Region Code" := EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode("Bill-to Country/Region Code");
            if ServiceCommentLine.Get(
                 ServiceCommentLine."Table Name"::"Service Invoice Header", 0, ServiceCrMemoHeader."No.", ServiceCommentLine.Type::General,
                 0, 10000)
            then
                Note := ServiceCommentLine.Comment;
        end;
    end;

    local procedure FillHeaderTaxAmounts(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary)
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoLine.SetRange("Document No.", TempEInvoiceExportHeader."No.");
        if ServiceCrMemoLine.FindSet then begin
            TempEInvoiceExportHeader."Sales Line Found" := true;
            repeat
                if IsRoundingLine(ServiceCrMemoLine) then
                    TempEInvoiceExportHeader."Total Rounding Amount" += ServiceCrMemoLine."Amount Including VAT"
                else begin
                    TempEInvoiceExportHeader."Total Invoice Discount Amount" +=
                      ServiceCrMemoLine."Inv. Discount Amount" + ServiceCrMemoLine."Line Discount Amount";
                    TempEInvoiceExportHeader."Legal Taxable Amount" += ServiceCrMemoLine.Amount;
                    TempEInvoiceExportHeader."Total Amount" += ServiceCrMemoLine."Amount Including VAT";
                    TempEInvoiceExportHeader."Tax Amount" += ServiceCrMemoLine."Amount Including VAT" - ServiceCrMemoLine.Amount;
                end;
            until ServiceCrMemoLine.Next = 0;
        end;
    end;

    local procedure FillLineTableData(var TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary; ServiceCrMemoLine: Record "Service Cr.Memo Line")
    var
        SalesCommentLine: Record "Sales Comment Line";
        Id: Integer;
    begin
        if TempEInvoiceExportLine.FindLast then
            Id := TempEInvoiceExportLine.ID + 1;

        TempEInvoiceExportLine.Init();
        TempEInvoiceExportLine.ID := Id;
        TempEInvoiceExportLine.Init();
        TempEInvoiceExportLine.TransferFields(ServiceCrMemoLine, true);
        if SalesCommentLine.Get(
             SalesCommentLine."Document Type"::"Posted Credit Memo", ServiceCrMemoLine."Document No.", ServiceCrMemoLine."Line No.", 10000)
        then
            TempEInvoiceExportLine.Comment := SalesCommentLine.Comment;
        TempEInvoiceExportLine.Insert();
    end;

    local procedure GetCustomizationID(ServiceCrMemoHeader: Record "Service Cr.Memo Header"): Text[250]
    var
        ResponsibilityCenter: Record "Responsibility Center";
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        CountryCode: Code[10];
        CustomizationID: Text[250];
    begin
        CustomizationID :=
          'urn:www.cenbii.eu:transaction:biitrns014:ver2.0:extended:' +
          'urn:www.peppol.eu:bis:peppol5a:ver2.0';

        if Customer.Get(ServiceCrMemoHeader."Bill-to Customer No.") then begin
            if ResponsibilityCenter.Get(ServiceCrMemoHeader."Responsibility Center") then
                CountryCode := ResponsibilityCenter."Country/Region Code"
            else begin
                CompanyInformation.Get();
                CountryCode := CompanyInformation."Country/Region Code";
            end;

            if Customer."Country/Region Code" = CountryCode then
                CustomizationID += ':extended:urn:www.difi.no:ehf:kreditnota:ver2.0';
        end;

        exit(CustomizationID);
    end;

    local procedure IsRoundingLine(ServiceCrMemoLine: Record "Service Cr.Memo Line"): Boolean
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if ServiceCrMemoLine.Type = ServiceCrMemoLine.Type::"G/L Account" then begin
            Customer.Get(ServiceCrMemoLine."Bill-to Customer No.");
            CustomerPostingGroup.SetFilter(Code, Customer."Customer Posting Group");
            if CustomerPostingGroup.FindFirst then
                if ServiceCrMemoLine."No." = CustomerPostingGroup."Invoice Rounding Account" then
                    exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ModifyServiceCrMemoHeader(DocumentNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.Get(DocumentNo);
        ServiceCrMemoHeader."E-Invoice Created" := true;
        ServiceCrMemoHeader.Modify();
    end;
}

