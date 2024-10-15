codeunit 10148 "Sales Tax Amount Line Calc"
{

    trigger OnRun()
    begin
    end;

    var
        RecRef: RecordRef;
        TaxGroupCodeFieldRef: FieldRef;
        LineType: Option;
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        VATBaseAmount: Decimal;
        LineAmount: Decimal;
        LineQuantity: Decimal;
        TaxLiable: Boolean;
        UseTax: Boolean;

    local procedure Clean()
    begin
        LineType := 0;
        TaxAreaCode := '';
        TaxGroupCode := '';
        VATBaseAmount := 0;
        LineAmount := 0;
        LineQuantity := 0;
        TaxLiable := false;
        UseTax := false;
        Clear(RecRef);
    end;

    procedure InitFromServCrMemoLine(ServiceCrMemoLine: Record "Service Cr.Memo Line")
    begin
        Clean;
        RecRef.GetTable(ServiceCrMemoLine);
        TaxGroupCodeFieldRef := RecRef.Field(ServiceCrMemoLine.FieldNo("Tax Group Code"));
        with ServiceCrMemoLine do begin
            LineType := Type;
            TaxAreaCode := "Tax Area Code";
            TaxGroupCode := "Tax Group Code";
            VATBaseAmount := "VAT Base Amount";
            LineAmount := "Line Amount";
            LineQuantity := Quantity;
            TaxLiable := "Tax Liable";
        end;
    end;

    procedure InitFromServInvLine(ServiceInvoiceLine: Record "Service Invoice Line")
    begin
        Clean;
        RecRef.GetTable(ServiceInvoiceLine);
        TaxGroupCodeFieldRef := RecRef.Field(ServiceInvoiceLine.FieldNo("Tax Group Code"));
        with ServiceInvoiceLine do begin
            LineType := Type;
            TaxAreaCode := "Tax Area Code";
            TaxGroupCode := "Tax Group Code";
            VATBaseAmount := "VAT Base Amount";
            LineAmount := "Line Amount";
            LineQuantity := Quantity;
            TaxLiable := "Tax Liable";
        end;
    end;

    procedure InitFromPurchCrMemoLine(PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        Clean;
        RecRef.GetTable(PurchCrMemoLine);
        TaxGroupCodeFieldRef := RecRef.Field(PurchCrMemoLine.FieldNo("Tax Group Code"));
        with PurchCrMemoLine do begin
            LineType := Type;
            TaxAreaCode := "Tax Area Code";
            TaxGroupCode := "Tax Group Code";
            VATBaseAmount := "VAT Base Amount";
            LineAmount := "Line Amount";
            LineQuantity := "Quantity (Base)";
            TaxLiable := "Tax Liable";
            UseTax := "Use Tax";
        end;
    end;

    procedure InitFromPurchInvLine(PurchInvLine: Record "Purch. Inv. Line")
    begin
        Clean;
        RecRef.GetTable(PurchInvLine);
        TaxGroupCodeFieldRef := RecRef.Field(PurchInvLine.FieldNo("Tax Group Code"));
        with PurchInvLine do begin
            LineType := Type;
            TaxAreaCode := "Tax Area Code";
            TaxGroupCode := "Tax Group Code";
            VATBaseAmount := "VAT Base Amount";
            LineAmount := "Line Amount";
            LineQuantity := "Quantity (Base)";
            TaxLiable := "Tax Liable";
            UseTax := "Use Tax";
        end;
    end;

    procedure InitFromSalesCrMemoLine(SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        Clean;
        RecRef.GetTable(SalesCrMemoLine);
        TaxGroupCodeFieldRef := RecRef.Field(SalesCrMemoLine.FieldNo("Tax Group Code"));
        with SalesCrMemoLine do begin
            LineType := Type;
            TaxAreaCode := "Tax Area Code";
            TaxGroupCode := "Tax Group Code";
            VATBaseAmount := "VAT Base Amount";
            LineAmount := "Line Amount";
            LineQuantity := "Quantity (Base)";
            TaxLiable := "Tax Liable";
        end;
    end;

    procedure InitFromSalesInvLine(SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        Clean;
        RecRef.GetTable(SalesInvoiceLine);
        TaxGroupCodeFieldRef := RecRef.Field(SalesInvoiceLine.FieldNo("Tax Group Code"));
        with SalesInvoiceLine do begin
            LineType := Type;
            TaxAreaCode := "Tax Area Code";
            TaxGroupCode := "Tax Group Code";
            VATBaseAmount := "VAT Base Amount";
            LineAmount := "Line Amount";
            LineQuantity := "Quantity (Base)";
            TaxLiable := "Tax Liable";
        end;
    end;

    procedure CalcSalesOrServLineSalesTaxAmountLine(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var TaxAreaLine: Record "Tax Area Line"; TaxCountry: Option US,CA; var TaxArea: Record "Tax Area"; var TaxJurisdiction: Record "Tax Jurisdiction"; ExchangeFactor: Decimal)
    begin
        with SalesTaxAmountLine do begin
            Reset;
            if (LineType <> 0) and (TaxAreaCode <> '') then begin
                TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
                TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
                TaxAreaLine.FindSet;
                repeat
                    case TaxCountry of
                        TaxCountry::US:  // Area Code
                            SetRange("Tax Area Code for Key", TaxAreaCode);
                        TaxCountry::CA:  // Jurisdictions
                            SetRange("Tax Area Code for Key", '');
                    end;
                    TaxGroupCodeFieldRef.TestField;
                    SetRange("Tax Group Code", TaxGroupCode);
                    SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                    if not FindFirst then begin
                        Init;
                        case TaxCountry of
                            TaxCountry::US:  // Area Code
                                "Tax Area Code for Key" := TaxAreaCode;
                            TaxCountry::CA:  // Jurisdictions
                                "Tax Area Code for Key" := '';
                        end;
                        "Tax Group Code" := TaxGroupCode;
                        "Tax Area Code" := TaxAreaCode;
                        "Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                        if TaxCountry = TaxCountry::US then begin
                            if "Tax Area Code" <> TaxArea.Code then
                                TaxArea.Get("Tax Area Code");
                            "Round Tax" := TaxArea."Round Tax";
                            TaxJurisdiction.Get("Tax Jurisdiction Code");
                            "Is Report-to Jurisdiction" :=
                              ("Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                        end;
                        "Line Amount" := LineAmount / ExchangeFactor;
                        SetTaxBaseAmount(SalesTaxAmountLine, VATBaseAmount, ExchangeFactor, false);
                        Quantity := LineQuantity;
                        "Tax Liable" := TaxLiable;

                        "Calculation Order" := TaxAreaLine."Calculation Order";
                        Insert;
                    end else begin
                        "Line Amount" := "Line Amount" + (LineAmount / ExchangeFactor);
                        SetTaxBaseAmount(SalesTaxAmountLine, VATBaseAmount, ExchangeFactor, true);
                        Quantity := Quantity + LineQuantity;
                        if TaxLiable then
                            "Tax Liable" := TaxLiable;
                        Modify;
                    end;
                until TaxAreaLine.Next = 0;
            end;
        end;
    end;

    procedure CalcPurchLineSalesTaxAmountLine(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var TaxAreaLine: Record "Tax Area Line"; TaxCountry: Option US,CA; var TaxArea: Record "Tax Area"; var TaxJurisdiction: Record "Tax Jurisdiction"; ExchangeFactor: Decimal; TaxDetail: Record "Tax Detail"; PostingDate: Date)
    begin
        with SalesTaxAmountLine do begin
            Reset;
            if (LineType <> 0) and (TaxAreaCode <> '') then begin
                TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
                TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
                TaxAreaLine.FindSet;
                repeat
                    case TaxCountry of
                        TaxCountry::US:  // Area Code
                            SetRange("Tax Area Code for Key", TaxAreaCode);
                        TaxCountry::CA:  // Jurisdictions
                            SetRange("Tax Area Code for Key", '');
                    end;
                    TaxGroupCodeFieldRef.TestField;
                    SetRange("Tax Group Code", TaxGroupCode);
                    SetRange("Use Tax", UseTax);
                    SetRange("Tax Jurisdiction Code", TaxAreaLine."Tax Jurisdiction Code");
                    if not FindFirst then begin
                        Init;
                        case TaxCountry of
                            TaxCountry::US:  // Area Code
                                "Tax Area Code for Key" := TaxAreaCode;
                            TaxCountry::CA:  // Jurisdictions
                                "Tax Area Code for Key" := '';
                        end;
                        "Tax Group Code" := TaxGroupCode;
                        "Tax Area Code" := TaxAreaCode;
                        "Tax Jurisdiction Code" := TaxAreaLine."Tax Jurisdiction Code";
                        if TaxCountry = TaxCountry::US then begin
                            if "Tax Area Code" <> TaxArea.Code then
                                TaxArea.Get("Tax Area Code");
                            "Round Tax" := TaxArea."Round Tax";
                            TaxJurisdiction.Get("Tax Jurisdiction Code");
                            "Is Report-to Jurisdiction" :=
                              ("Tax Jurisdiction Code" = TaxJurisdiction."Report-to Jurisdiction");
                        end;
                        "Line Amount" := LineAmount / ExchangeFactor;
                        SetTaxBaseAmount(SalesTaxAmountLine, VATBaseAmount, ExchangeFactor, false);
                        Quantity := LineQuantity;
                        "Tax Liable" := TaxLiable;
                        "Use Tax" := UseTax;

                        TaxDetail.Reset();
                        TaxDetail.SetRange("Tax Jurisdiction Code", "Tax Jurisdiction Code");
                        if "Tax Group Code" = '' then
                            TaxDetail.SetFilter("Tax Group Code", '%1', "Tax Group Code")
                        else
                            TaxDetail.SetFilter("Tax Group Code", '%1|%2', '', "Tax Group Code");
                        if PostingDate = 0D then
                            TaxDetail.SetFilter("Effective Date", '<=%1', WorkDate)
                        else
                            TaxDetail.SetFilter("Effective Date", '<=%1', PostingDate);
                        TaxDetail.SetFilter("Tax Type", '%1|%2', TaxDetail."Tax Type"::"Sales and Use Tax",
                          TaxDetail."Tax Type"::"Sales Tax Only");
                        if TaxDetail.FindLast then
                            "Expense/Capitalize" := TaxDetail."Expense/Capitalize";

                        "Calculation Order" := TaxAreaLine."Calculation Order";
                        Insert;
                    end else begin
                        "Line Amount" := "Line Amount" + (LineAmount / ExchangeFactor);
                        SetTaxBaseAmount(SalesTaxAmountLine, VATBaseAmount, ExchangeFactor, true);
                        Quantity := Quantity + LineQuantity;
                        if TaxLiable then
                            "Tax Liable" := TaxLiable;
                        Modify;
                    end;
                until TaxAreaLine.Next = 0;
            end;
        end;
    end;

    procedure SetTaxBaseAmount(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; Value: Decimal; ExchangeFactor: Decimal; Increment: Boolean)
    begin
        with SalesTaxAmountLine do begin
            if Increment then
                "Tax Base Amount FCY" += Value
            else
                "Tax Base Amount FCY" := Value;
            "Tax Base Amount" := "Tax Base Amount FCY" / ExchangeFactor;
        end;
    end;
}

