page 2157 "O365 Sales Invoice Line Card"
{
    Caption = 'Invoice Line';
    DeleteAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Sales Line";

    layout
    {
        area(content)
        {
            group(grpGeneral)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        RedistributeTotalsOnAfterValidate;
                    end;
                }
                group(grpPricelist)
                {
                    Caption = '';
                    field(Description; Description)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Choose from price list';
                        LookupPageID = "O365 Sales Item Lookup";
                        ShowCaption = false;
                        ToolTip = 'Specifies a description of the item or service on the line.';

                        trigger OnValidate()
                        begin
                            if IsLookupRequested then
                                if not O365SalesInvoiceMgmt.LookupDescription(Rec, Description, DescriptionSelected) then
                                    Error('');

                            RedistributeTotalsOnAfterValidate;
                            DescriptionSelected := Description <> '';
                        end;
                    }
                }
                group(grpEnterQuantity)
                {
                    Caption = 'Quantity & Price';
                    Visible = Description <> '';
                    field(EnterQuantity; EnterQuantity)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Enter a quantity';
                        ToolTip = 'Specifies if the user enters the quantity of the item or service on the line.';
                    }
                }
                group(grpQuantity)
                {
                    Caption = '';
                    Visible = (Description <> '') AND EnterQuantity;
                    field(LineQuantity; LineQuantity)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Quantity';
                        DecimalPlaces = 0 : 5;
                        Enabled = DescriptionSelected;
                        ToolTip = 'Specifies the quantity of the item or service on the line.';

                        trigger OnValidate()
                        begin
                            Validate(Quantity, LineQuantity);
                            RedistributeTotalsOnAfterValidate;
                            ShowInvoiceDiscountNotification;
                        end;
                    }
                    field("Unit Price"; "Unit Price")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Price';
                        Enabled = DescriptionSelected;
                        ToolTip = 'Specifies the price for one unit on the sales line.';

                        trigger OnValidate()
                        begin
                            RedistributeTotalsOnAfterValidate;
                        end;
                    }
                    field("Unit of Measure"; "Unit of Measure")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Unit';
                        Editable = false;
                        ToolTip = 'Specifies the sales unit of measure for this product or service.';
                        Width = 5;
                    }
                }
                group(grpGiveDiscount)
                {
                    Caption = 'Discount';
                    Visible = Description <> '';
                    field(EnterDiscount; EnterDiscount)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Give a discount';
                        ToolTip = 'Specifies if the user enters the discount on the line.';

                        trigger OnValidate()
                        begin
                            if not EnterDiscount then
                                Validate("Line Discount %", 0);
                        end;
                    }
                }
                group(grpDiscount)
                {
                    Caption = '';
                    Visible = (Description <> '') AND EnterDiscount;
                    field("Line Discount %"; "Line Discount %")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;

                        trigger OnValidate()
                        begin
                            RedistributeTotalsOnAfterValidate;
                            if HasShownInvoiceDiscountNotification then
                                InvoiceDiscountNotification.Recall;
                        end;
                    }
                    field("Line Discount Amount"; "Line Discount Amount")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;

                        trigger OnValidate()
                        var
                            LineDiscountAmount: Decimal;
                        begin
                            GetTotalSalesHeader;
                            LineDiscountAmount :=
                              O365SalesInvoiceMgmt.GetValueWithinBounds(
                                "Line Discount Amount", 0, "Unit Price" * Quantity, AmountOutsideOfBoundsNotificationSend, TotalSalesHeader.RecordId);
                            if LineDiscountAmount <> "Line Discount Amount" then
                                Validate("Line Discount Amount", LineDiscountAmount);
                            RedistributeTotalsOnAfterValidate;
                            if HasShownInvoiceDiscountNotification then
                                InvoiceDiscountNotification.Recall;
                        end;
                    }
                }
            }
            group(Control19)
            {
                ShowCaption = false;
                Visible = Description <> '';
                group(grpEnterTax)
                {
                    Caption = 'Tax';
                    Visible = NOT IsUsingVAT;
                    field("Tax Group Code"; "Tax Group Code")
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Tax Group';
                        Editable = DescriptionSelected;
                        NotBlank = true;
                        ToolTip = 'Specifies the tax group code for the tax-detail entry.';

                        trigger OnValidate()
                        begin
                            RedistributeTotalsOnAfterValidate;
                        end;
                    }
                }
                group(grpTax)
                {
                    Caption = '';
                    Visible = NOT IsUsingVAT;
                    field(TaxRate; TaxRateText)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Tax %';
                        Enabled = TaxRateEditable;
                        QuickEntry = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the VAT % that was used on the sales or purchase lines with this VAT Identifier.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            TaxDetail: Record "Tax Detail";
                            TaxArea: Record "Tax Area";
                            SalesHeader: Record "Sales Header";
                        begin
                            CalcFields("Posting Date");
                            if PAGE.RunModal(PAGE::"O365 Tax Area List", TaxArea) = ACTION::LookupOK then begin
                                if SalesHeader.Get("Document Type", "Document No.") then
                                    SalesHeader.Validate("Tax Area Code", TaxArea.Code);
                                TaxRate := TaxDetail.GetSalesTaxRate("Tax Area Code", "Tax Group Code", "Posting Date", "Tax Liable");
                                UpdateTaxRateText;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            RedistributeTotalsOnAfterValidate;
                        end;
                    }
                }
                group(grpVAT)
                {
                    Caption = 'VAT';
                    Visible = IsUsingVAT;
                    field(VATProductPostingGroupDescription; VATProductPostingGroupDescription)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'VAT';
                        Enabled = DescriptionSelected;
                        NotBlank = true;
                        QuickEntry = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the VAT group code for this item.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            VATProductPostingGroup: Record "VAT Product Posting Group";
                        begin
                            if PAGE.RunModal(PAGE::"O365 VAT Product Posting Gr.", VATProductPostingGroup) = ACTION::LookupOK then begin
                                Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
                                VATProductPostingGroupDescription := VATProductPostingGroup.Description;
                                RedistributeTotalsOnAfterValidate;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            RedistributeTotalsOnAfterValidate;
                        end;
                    }
                }
            }
            group(grpTotal)
            {
                Caption = '';
                Visible = Description <> '';
                field(LineAmountExclVAT; GetLineAmountExclVAT)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Line Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field(LineAmountInclVAT; GetLineAmountInclVAT)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Line Amount Incl. VAT';
                    Editable = false;
                    ToolTip = 'Specifies the net amount, including VAT and excluding any invoice discount, that must be paid for products on the line.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DeleteLine)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Delete Line';
                Gesture = RightSwipe;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                Scope = Repeater;
                ToolTip = 'Delete the selected line.';

                trigger OnAction()
                var
                    EnvInfoProxy: Codeunit "Env. Info Proxy";
                begin
                    if "No." = '' then
                        exit;

                    if not Confirm(DeleteQst, true) then
                        exit;
                    Delete(true);
                    if not EnvInfoProxy.IsInvoicing then
                        CurrPage.Update;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        TaxDetail: Record "Tax Detail";
    begin
        UpdatePageCaption;
        CalcFields("Posting Date");
        TaxRate := TaxDetail.GetSalesTaxRate("Tax Area Code", "Tax Group Code", "Posting Date", "Tax Liable");
        UpdateTaxRateText;
        CalculateTotals;
        DescriptionSelected := Description <> '';
        LineQuantity := Quantity;
        TaxRateEditable := DescriptionSelected and (TaxSetup."Non-Taxable Tax Group Code" <> "Tax Group Code");
        UpdateVATPostingGroupDescription;
    end;

    trigger OnAfterGetRecord()
    begin
        UpdatePriceDescription;
        O365SalesInvoiceMgmt.ConstructCurrencyFormatString(Rec, CurrencyFormat);
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        SalesSetup.Get();
        if TaxSetup.Get then;
        Currency.InitRoundingPrecision;
        O365SalesInvoiceMgmt.ConstructCurrencyFormatString(Rec, CurrencyFormat);
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;
        EnterQuantity := false;
        EnterDiscount := false;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        UpdatePriceDescription
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        Type := Type::Item;
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "Document No.");
        if SalesLine.FindLast then;
        "Line No." := SalesLine."Line No." + 10000;
        TaxRate := 0;
        Clear(VATProductPostingGroupDescription);
    end;

    trigger OnOpenPage()
    begin
        EnterQuantity := Quantity > 1;
        EnterDiscount := ("Line Discount %" > 0) or ("Line Discount Amount" > 0);
    end;

    var
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        TotalSalesHeader: Record "Sales Header";
        TotalSalesLine: Record "Sales Line";
        TaxSetup: Record "Tax Setup";
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        DocumentTotals: Codeunit "Document Totals";
        InvoiceDiscountNotification: Notification;
        CurrencyFormat: Text;
        TaxRateText: Text;
        VATProductPostingGroupDescription: Text[100];
        VATAmount: Decimal;
        TaxRate: Decimal;
        LineQuantity: Decimal;
        TaxRateEditable: Boolean;
        HasShownInvoiceDiscountNotification: Boolean;
        AmountOutsideOfBoundsNotificationSend: Boolean;
        DescriptionSelected: Boolean;
        DeleteQst: Label 'Are you sure?';
        IsUsingVAT: Boolean;
        InvoiceCaptionTxt: Label 'Invoice Line';
        EstimateCaptionTxt: Label 'Estimate Line';
        EnterQuantity: Boolean;
        EnterDiscount: Boolean;
        PercentTxt: Label '%';

    local procedure CalculateTotals()
    begin
        GetTotalSalesHeader;
        if SalesSetup."Calc. Inv. Discount" and ("Document No." <> '') and (TotalSalesHeader."Customer Posting Group" <> '') then
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", Rec);

        DocumentTotals.CalculateSalesTotals(TotalSalesLine, VATAmount, Rec);
    end;

    local procedure RedistributeTotalsOnAfterValidate()
    begin
        CurrPage.SaveRecord;

        TotalSalesHeader.Get("Document Type", "Document No.");
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(Rec, VATAmount, TotalSalesLine);
        CurrPage.Update;
    end;

    local procedure GetTotalSalesHeader()
    begin
        if not TotalSalesHeader.Get("Document Type", "Document No.") then
            Clear(TotalSalesHeader);
        if Currency.Code <> TotalSalesHeader."Currency Code" then
            if not Currency.Get(TotalSalesHeader."Currency Code") then
                Currency.InitRoundingPrecision;
    end;

    local procedure UpdateTaxRateText()
    begin
        TaxRateText := Format(TaxRate) + PercentTxt;
    end;

    local procedure ShowInvoiceDiscountNotification()
    begin
        if HasShownInvoiceDiscountNotification then
            exit;
        if "Line Discount %" = xRec."Line Discount %" then
            exit;
        GetTotalSalesHeader;
        O365SalesInvoiceMgmt.ShowInvoiceDiscountNotification(InvoiceDiscountNotification, TotalSalesHeader.RecordId);
        HasShownInvoiceDiscountNotification := true;
    end;

    local procedure UpdatePageCaption()
    begin
        if "Document Type" = "Document Type"::Invoice then
            CurrPage.Caption := InvoiceCaptionTxt
        else
            if "Document Type" = "Document Type"::Quote then
                CurrPage.Caption := EstimateCaptionTxt;
    end;

    local procedure UpdateVATPostingGroupDescription()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if VATProductPostingGroup.Get("VAT Prod. Posting Group") then
            VATProductPostingGroupDescription := VATProductPostingGroup.Description
        else
            Clear(VATProductPostingGroup);
    end;
}

