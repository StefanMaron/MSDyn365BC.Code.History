#if not CLEAN21
page 2157 "O365 Sales Invoice Line Card"
{
    Caption = 'Invoice Line';
    DeleteAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Sales Line";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(grpGeneral)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        RedistributeTotalsOnAfterValidate();
                    end;
                }
                group(grpPricelist)
                {
                    Caption = '';
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Choose from price list';
                        LookupPageID = "O365 Sales Item Lookup";
                        ShowCaption = false;
                        ToolTip = 'Specifies a description of the item or service on the line.';

                        trigger OnValidate()
                        begin
                            Rec.RestoreLookupSelection();

                            if Rec.IsLookupRequested() then
                                if not O365SalesInvoiceMgmt.LookupDescription(Rec, Rec.Description, DescriptionSelected) then
                                    Error('');

                            RedistributeTotalsOnAfterValidate();
                            DescriptionSelected := Rec.Description <> '';
                        end;

                        trigger OnAfterLookup(Selected: RecordRef)
                        begin
                            Rec.SaveLookupSelection(Selected);
                        end;
                    }
                }
                group(grpEnterQuantity)
                {
                    Caption = 'Quantity & Price';
                    Visible = Rec.Description <> '';
                    field(EnterQuantity; EnterQuantity)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Enter a quantity';
                        ToolTip = 'Specifies if the user enters the quantity of the item or service on the line.';
                    }
                }
                group(grpQuantity)
                {
                    Caption = '';
                    Visible = (Rec.Description <> '') AND EnterQuantity;
                    field(LineQuantity; LineQuantity)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Quantity';
                        DecimalPlaces = 0 : 5;
                        Enabled = DescriptionSelected;
                        ToolTip = 'Specifies the quantity of the item or service on the line.';

                        trigger OnValidate()
                        begin
                            Rec.Validate(Quantity, LineQuantity);
                            RedistributeTotalsOnAfterValidate();
                            ShowInvoiceDiscountNotification();
                        end;
                    }
                    field("Unit Price"; Rec."Unit Price")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Price';
                        Enabled = DescriptionSelected;
                        ToolTip = 'Specifies the price for one unit on the sales line.';

                        trigger OnValidate()
                        begin
                            RedistributeTotalsOnAfterValidate();
                        end;
                    }
                    field("Unit of Measure"; Rec."Unit of Measure")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Unit';
                        Editable = false;
                        ToolTip = 'Specifies the sales unit of measure for this product or service.';
                        Width = 5;
                    }
                }
                group(grpGiveDiscount)
                {
                    Caption = 'Discount';
                    Visible = Rec.Description <> '';
                    field(EnterDiscount; EnterDiscount)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Give a discount';
                        ToolTip = 'Specifies if the user enters the discount on the line.';

                        trigger OnValidate()
                        begin
                            if not EnterDiscount then
                                Rec.Validate("Line Discount %", 0);
                        end;
                    }
                }
                group(grpDiscount)
                {
                    Caption = '';
                    Visible = (Rec.Description <> '') AND EnterDiscount;
                    field("Line Discount %"; Rec."Line Discount %")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;

                        trigger OnValidate()
                        begin
                            RedistributeTotalsOnAfterValidate();
                            if HasShownInvoiceDiscountNotification then
                                InvoiceDiscountNotification.Recall();
                        end;
                    }
                    field("Line Discount Amount"; Rec."Line Discount Amount")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;

                        trigger OnValidate()
                        var
                            LineDiscountAmount: Decimal;
                        begin
                            GetTotalSalesHeader();
                            LineDiscountAmount :=
                              O365SalesInvoiceMgmt.GetValueWithinBounds(
                                Rec."Line Discount Amount", 0, Rec."Unit Price" * Rec.Quantity, AmountOutsideOfBoundsNotificationSend, TotalSalesHeader.RecordId);
                            if LineDiscountAmount <> Rec."Line Discount Amount" then
                                Rec.Validate("Line Discount Amount", LineDiscountAmount);
                            RedistributeTotalsOnAfterValidate();
                            if HasShownInvoiceDiscountNotification then
                                InvoiceDiscountNotification.Recall();
                        end;
                    }
                }
            }
            group(Control19)
            {
                ShowCaption = false;
                Visible = Rec.Description <> '';
                group(grpEnterTax)
                {
                    Caption = 'Tax';
                    Visible = NOT IsUsingVAT;
                    field("Tax Group Code"; Rec."Tax Group Code")
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Caption = 'Tax Group';
                        Editable = DescriptionSelected;
                        NotBlank = true;
                        ToolTip = 'Specifies the tax group code for the tax-detail entry.';

                        trigger OnValidate()
                        begin
                            RedistributeTotalsOnAfterValidate();
                        end;
                    }
                }
                group(grpTax)
                {
                    Caption = '';
                    Visible = NOT IsUsingVAT;
                    field(TaxRate; TaxRateText)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
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
                            Rec.CalcFields("Posting Date");
                            if PAGE.RunModal(PAGE::"O365 Tax Area List", TaxArea) = ACTION::LookupOK then begin
                                if SalesHeader.Get(Rec."Document Type", Rec."Document No.") then
                                    SalesHeader.Validate("Tax Area Code", TaxArea.Code);
                                TaxRate := TaxDetail.GetSalesTaxRate(Rec."Tax Area Code", Rec."Tax Group Code", Rec."Posting Date", Rec."Tax Liable");
                                UpdateTaxRateText();
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            RedistributeTotalsOnAfterValidate();
                        end;
                    }
                }
                group(grpVAT)
                {
                    Caption = 'VAT';
                    Visible = IsUsingVAT;
                    field(VATProductPostingGroupDescription; VATProductPostingGroupDescription)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
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
                                Rec.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
                                VATProductPostingGroupDescription := VATProductPostingGroup.Description;
                                RedistributeTotalsOnAfterValidate();
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            RedistributeTotalsOnAfterValidate();
                        end;
                    }
                }
            }
            group(grpTotal)
            {
                Caption = '';
                Visible = Rec.Description <> '';
                field(LineAmountExclVAT; Rec.GetLineAmountExclVAT())
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = CurrencyFormat;
                    AutoFormatType = 11;
                    Caption = 'Line Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field(LineAmountInclVAT; Rec.GetLineAmountInclVAT())
                {
                    ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Delete Line';
                Gesture = RightSwipe;
                Image = Delete;
                Scope = Repeater;
                ToolTip = 'Delete the selected line.';

                trigger OnAction()
                var
                    EnvInfoProxy: Codeunit "Env. Info Proxy";
                begin
                    if Rec."No." = '' then
                        exit;

                    if not Confirm(DeleteQst, true) then
                        exit;
                    Rec.Delete(true);
                    if not EnvInfoProxy.IsInvoicing() then
                        CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(DeleteLine_Promoted; DeleteLine)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        TaxDetail: Record "Tax Detail";
    begin
        UpdatePageCaption();
        Rec.CalcFields("Posting Date");
        TaxRate := TaxDetail.GetSalesTaxRate(Rec."Tax Area Code", Rec."Tax Group Code", Rec."Posting Date", Rec."Tax Liable");
        UpdateTaxRateText();
        CalculateTotals();
        DescriptionSelected := Rec.Description <> '';
        LineQuantity := Rec.Quantity;
        TaxRateEditable := DescriptionSelected and (TaxSetup."Non-Taxable Tax Group Code" <> Rec."Tax Group Code");
        UpdateVATPostingGroupDescription();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.UpdatePriceDescription();
        O365SalesInvoiceMgmt.ConstructCurrencyFormatString(Rec, CurrencyFormat);
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        SalesSetup.Get();
        if TaxSetup.Get() then;
        Currency.InitRoundingPrecision();
        O365SalesInvoiceMgmt.ConstructCurrencyFormatString(Rec, CurrencyFormat);
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT();
        EnterQuantity := false;
        EnterDiscount := false;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.UpdatePriceDescription();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        Rec.Type := Rec.Type::Item;
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Document No.", Rec."Document No.");
        if SalesLine.FindLast() then;
        Rec."Line No." := SalesLine."Line No." + 10000;
        TaxRate := 0;
        Clear(VATProductPostingGroupDescription);
    end;

    trigger OnOpenPage()
    begin
        EnterQuantity := Rec.Quantity > 1;
        EnterDiscount := (Rec."Line Discount %" > 0) or (Rec."Line Discount Amount" > 0);
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
        GetTotalSalesHeader();
        if SalesSetup."Calc. Inv. Discount" and (Rec."Document No." <> '') and (TotalSalesHeader."Customer Posting Group" <> '') then
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", Rec);

        DocumentTotals.CalculateSalesTotals(TotalSalesLine, VATAmount, Rec);
    end;

    local procedure RedistributeTotalsOnAfterValidate()
    begin
        CurrPage.SaveRecord();

        TotalSalesHeader.Get(Rec."Document Type", Rec."Document No.");
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(Rec, VATAmount, TotalSalesLine);
        CurrPage.Update();
    end;

    local procedure GetTotalSalesHeader()
    begin
        if not TotalSalesHeader.Get(Rec."Document Type", Rec."Document No.") then
            Clear(TotalSalesHeader);
        if Currency.Code <> TotalSalesHeader."Currency Code" then
            if not Currency.Get(TotalSalesHeader."Currency Code") then
                Currency.InitRoundingPrecision();
    end;

    local procedure UpdateTaxRateText()
    begin
        TaxRateText := Format(TaxRate) + PercentTxt;
    end;

    local procedure ShowInvoiceDiscountNotification()
    begin
        if HasShownInvoiceDiscountNotification then
            exit;
        if Rec."Line Discount %" = xRec."Line Discount %" then
            exit;
        GetTotalSalesHeader();
        O365SalesInvoiceMgmt.ShowInvoiceDiscountNotification(InvoiceDiscountNotification, TotalSalesHeader.RecordId);
        HasShownInvoiceDiscountNotification := true;
    end;

    local procedure UpdatePageCaption()
    begin
        if Rec."Document Type" = Rec."Document Type"::Invoice then
            CurrPage.Caption := InvoiceCaptionTxt
        else
            if Rec."Document Type" = Rec."Document Type"::Quote then
                CurrPage.Caption := EstimateCaptionTxt;
    end;

    local procedure UpdateVATPostingGroupDescription()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if VATProductPostingGroup.Get(Rec."VAT Prod. Posting Group") then
            VATProductPostingGroupDescription := VATProductPostingGroup.Description
        else
            Clear(VATProductPostingGroup);
    end;
}
#endif
