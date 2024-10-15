codeunit 11515 "CH Report Management"
{

    trigger OnRun()
    begin
    end;

    var
        PurchPersonTxt: Label 'Purchaser';
        SalesPersonTxt: Label 'Salesperson';
        YourReferenceTxt: Label 'Reference';
        OrderNoTxt: Label 'Order No.';
        InvoiceNoTxt: Label 'Ext. Invoice No.';
        PaymentTermsTxt: Label 'Payment Terms';
        ApplyToDocTxt: Label 'Refers to Document';
        ShipCondTxt: Label 'Shipping Conditions';
        ShipAdrTxt: Label 'Shipping Address';
        InvAdrTxt: Label 'Invoice Address';
        OrderAdrTxt: Label 'Order Address';
        ShipDateTxt: Label 'Shipping Date';
        BankInformationTxt: Label 'Bank Information';
        AccountTxt: Label 'Account';

    procedure PrepareHeader(RecRef: RecordRef; ReportId: Integer; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    begin
        Clear(HeaderLabel);
        Clear(HeaderTxt);

        case ReportId of
            REPORT::"Sales - Quote",
          REPORT::"Blanket Sales Order",
          REPORT::"Sales Picking List",
          REPORT::"Order Confirmation",
          REPORT::"Return Order Confirmation",
          REPORT::"Sales - Shipment",
          REPORT::"Sales - Credit Memo":
                PrepareHeaderSalesCommonPart(RecRef, HeaderLabel, HeaderTxt);
            REPORT::"Sales Invoice ESR",
          REPORT::"Sales - Invoice":
                PrepareHeaderSalesInvoice(RecRef, HeaderLabel, HeaderTxt);
            REPORT::"Purchase - Quote",
          REPORT::"Purchase - Credit Memo",
          REPORT::"Purchase - Receipt",
          REPORT::"Return Order",
          REPORT::"Blanket Purchase Order",
          REPORT::Order:
                PrepareHeadePurchaseCommonPart(RecRef, HeaderLabel, HeaderTxt);
            REPORT::"Purchase - Invoice":
                PrepareHeaderPurchaseInvoice(RecRef, HeaderLabel, HeaderTxt);
        end;

        OnAfterPrepareHeader(RecRef, ReportId, HeaderLabel, HeaderTxt);

        CompressArray(HeaderLabel);
        CompressArray(HeaderTxt);
    end;

    local procedure PrepareHeaderSalesCommonPart(RecRef: RecordRef; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    var
        SalesHeader: Record "Sales Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        YourReference: Text;
    begin
        if SalespersonPurchaser.Get(GetFieldValue(RecRef, SalesHeader.FieldNo("Salesperson Code"))) then begin
            HeaderLabel[2] := SalesPersonTxt;
            HeaderTxt[2] := SalespersonPurchaser.Name;
        end;

        YourReference := GetFieldValue(RecRef, SalesHeader.FieldNo("Your Reference"));
        if YourReference <> '' then begin
            HeaderLabel[3] := YourReferenceTxt;
            HeaderTxt[3] := YourReference;
        end;
    end;

    local procedure PrepareHeaderSalesInvoice(RecRef: RecordRef; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        RecRef.SetTable(SalesInvoiceHeader);
        with SalesInvoiceHeader do
            if "Order No." <> '' then begin
                HeaderLabel[1] := OrderNoTxt;
                HeaderTxt[1] := "Order No.";
            end;

        PrepareHeaderSalesCommonPart(RecRef, HeaderLabel, HeaderTxt);
    end;

    local procedure PrepareHeadePurchaseCommonPart(RecRef: RecordRef; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    var
        PurchaseHeader: Record "Purchase Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        YourReference: Text;
    begin
        if SalespersonPurchaser.Get(GetFieldValue(RecRef, PurchaseHeader.FieldNo("Purchaser Code"))) then begin
            HeaderLabel[3] := PurchPersonTxt;
            HeaderTxt[3] := SalespersonPurchaser.Name;
        end;

        YourReference := GetFieldValue(RecRef, PurchaseHeader.FieldNo("Your Reference"));
        if YourReference <> '' then begin
            HeaderLabel[4] := YourReferenceTxt;
            HeaderTxt[4] := YourReference;
        end;
    end;

    procedure PrepareFooter(RecRef: RecordRef; ReportId: Integer; var FooterLabel: array[20] of Text[30]; var FooterTxt: array[20] of Text)
    begin
        Clear(FooterLabel);
        Clear(FooterTxt);

        case ReportId of
            REPORT::"Sales - Quote",
          REPORT::"Blanket Sales Order",
          REPORT::"Order Confirmation",
          REPORT::"Return Order Confirmation",
          REPORT::"Sales - Invoice",
          REPORT::"Sales Invoice ESR",
          REPORT::"Sales - Credit Memo":
                PrepareFooterSalesCommonPart(RecRef, FooterLabel, FooterTxt, true);
            REPORT::"Sales Picking List",
          REPORT::"Sales - Shipment":
                PrepareFooterSalesCommonPart(RecRef, FooterLabel, FooterTxt, false);
            REPORT::"Purchase - Quote",
          REPORT::"Purchase - Invoice",
          REPORT::"Purchase - Credit Memo",
          REPORT::"Purchase - Receipt",
          REPORT::"Return Order",
          REPORT::"Blanket Purchase Order",
          REPORT::Order:
                PrepareFooterPurchaseCommonPart(RecRef, FooterLabel, FooterTxt);
        end;

        OnAfterPrepareFooter(RecRef, ReportId, FooterLabel, FooterTxt);

        CompressArray(FooterLabel);
        CompressArray(FooterTxt);
    end;

    local procedure PrepareFooterSalesCommonPart(RecRef: RecordRef; var FooterLabel: array[20] of Text[30]; var FooterTxt: array[20] of Text; ShowBankInfo: Boolean)
    var
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        SalesHeader: Record "Sales Header";
        CompanyInformation: Record "Company Information";
        AppliesToDocNo: Text;
    begin
        with SalesHeader do begin
            if PaymentTerms.Get(GetFieldValue(RecRef, FieldNo("Payment Terms Code"))) then begin
                FooterLabel[1] := PaymentTermsTxt;
                PaymentTerms.TranslateDescription(PaymentTerms, "Language Code");
                FooterTxt[1] := PaymentTerms.Description;
            end;

            AppliesToDocNo := GetFieldValue(RecRef, FieldNo("Applies-to Doc. No."));
            if AppliesToDocNo <> '' then begin
                FooterLabel[2] := ApplyToDocTxt;
                FooterTxt[2] := GetFieldValue(RecRef, FieldNo("Applies-to Doc. Type")) + ' ' + AppliesToDocNo;
            end;

            if ShipmentMethod.Get(GetFieldValue(RecRef, FieldNo("Shipment Method Code"))) then begin
                FooterLabel[3] := ShipCondTxt;
                ShipmentMethod.TranslateDescription(ShipmentMethod, "Language Code");
                FooterTxt[3] := ShipmentMethod.Description;
            end;

            if GetFieldValue(RecRef, FieldNo("Ship-to Code")) <> '' then begin
                FooterLabel[4] := ShipAdrTxt;
                FooterTxt[4] := GetFieldValue(RecRef, FieldNo("Ship-to Name")) + ' ' + GetFieldValue(RecRef, FieldNo("Ship-to City"));
            end;

            if GetFieldValue(RecRef, FieldNo("Sell-to Customer No.")) <> GetFieldValue(RecRef, FieldNo("Bill-to Customer No.")) then begin
                FooterLabel[5] := InvAdrTxt;
                FooterTxt[5] := GetFieldValue(RecRef, FieldNo("Bill-to Name")) + ', ' + GetFieldValue(RecRef, FieldNo("Bill-to City"));
                FooterLabel[6] := OrderAdrTxt;
                FooterTxt[6] :=
                  GetFieldValue(RecRef, FieldNo("Sell-to Customer Name")) + ', ' + GetFieldValue(RecRef, FieldNo("Sell-to City"));
            end;

            if (GetFieldValue(RecRef, FieldNo("Shipment Date")) <> GetFieldValue(RecRef, FieldNo("Document Date"))) and
               (GetFieldValue(RecRef, FieldNo("Shipment Date")) <> '')
            then begin
                FooterLabel[7] := ShipDateTxt;
                FooterTxt[7] := GetDateFieldValue(RecRef, FieldNo("Shipment Date"));
            end;

            if ShowBankInfo then begin
                CompanyInformation.Get();
                CompanyInformation.TestField("Bank Name");
                FooterLabel[8] := BankInformationTxt;
                FooterTxt[8] := StrSubstNo('%1, %2 %3', CompanyInformation."Bank Name", AccountTxt, CompanyInformation."Bank Account No.");
            end;
        end;
    end;

    local procedure PrepareFooterPurchaseCommonPart(RecRef: RecordRef; var FooterLabel: array[20] of Text[30]; var FooterTxt: array[20] of Text)
    var
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        PurchaseHeader: Record "Purchase Header";
    begin
        with PurchaseHeader do begin
            if PaymentTerms.Get(GetFieldValue(RecRef, FieldNo("Payment Terms Code"))) then begin
                FooterLabel[1] := PaymentTermsTxt;
                PaymentTerms.TranslateDescription(PaymentTerms, "Language Code");
                FooterTxt[1] := PaymentTerms.Description;
            end;

            if ShipmentMethod.Get(GetFieldValue(RecRef, FieldNo("Shipment Method Code"))) then begin
                FooterLabel[2] := ShipCondTxt;
                ShipmentMethod.TranslateDescription(ShipmentMethod, "Language Code");
                FooterTxt[2] := ShipmentMethod.Description;
            end;

            if GetFieldValue(RecRef, FieldNo("Ship-to Code")) <> '' then begin
                FooterLabel[3] := ShipAdrTxt;
                FooterTxt[3] := GetFieldValue(RecRef, FieldNo("Ship-to Name")) + ' ' + GetFieldValue(RecRef, FieldNo("Ship-to City"));
            end;

            if GetFieldValue(RecRef, FieldNo("Buy-from Vendor No.")) <> GetFieldValue(RecRef, FieldNo("Pay-to Vendor No.")) then begin
                FooterLabel[4] := InvAdrTxt;
                FooterTxt[4] := GetFieldValue(RecRef, FieldNo("Pay-to Name")) + ', ' + GetFieldValue(RecRef, FieldNo("Pay-to City"));
                FooterLabel[5] := OrderAdrTxt;
                FooterTxt[5] :=
                  GetFieldValue(RecRef, FieldNo("Buy-from Vendor Name")) + ', ' + GetFieldValue(RecRef, FieldNo("Buy-from City"));
            end;

            if (GetFieldValue(RecRef, FieldNo("Expected Receipt Date")) = GetFieldValue(RecRef, FieldNo("Document Date"))) and
               (GetFieldValue(RecRef, FieldNo("Expected Receipt Date")) = '')
            then begin
                FooterLabel[6] := ShipDateTxt;
                FooterTxt[6] := GetDateFieldValue(RecRef, FieldNo("Expected Receipt Date"));
            end;
        end;
    end;

    local procedure PrepareHeaderPurchaseInvoice(RecRef: RecordRef; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        RecRef.SetTable(PurchInvHeader);
        with PurchInvHeader do begin
            if "Order No." <> '' then begin
                HeaderLabel[1] := OrderNoTxt;
                HeaderTxt[1] := "Order No.";
            end;

            if "Vendor Invoice No." <> '' then begin
                HeaderLabel[2] := InvoiceNoTxt;
                HeaderTxt[2] := "Vendor Invoice No.";
            end;
        end;
        PrepareHeadePurchaseCommonPart(RecRef, HeaderLabel, HeaderTxt);
    end;

    local procedure GetFieldValue(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldNo);
        exit(Format(FieldRef.Value));
    end;

    local procedure GetDateFieldValue(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldNo);
        exit(Format(FieldRef.Value, 0, 4));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareHeader(RecRef: RecordRef; ReportId: Integer; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareFooter(RecRef: RecordRef; ReportId: Integer; var FooterLabel: array[20] of Text[30]; var FooterTxt: array[20] of Text)
    begin
    end;
}

