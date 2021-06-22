page 2311 "BC O365 Sales Inv. Line Subp."
{
    AutoSplitKey = true;
    Caption = 'Invoice Line';
    DelayedInsert = true;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    PromotedActionCategories = 'New,Process,Report,Manage';
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Sales Line";

    layout
    {
        area(content)
        {
            repeater(grpGeneral)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies the number of the record.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        RedistributeTotalsOnAfterValidate;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    LookupPageID = "BC O365 Item List";
                    ToolTip = 'Specifies a description of the item or service on the line.';

                    trigger OnValidate()
                    begin
                        O365SalesInvoiceMgmt.ValidateItemDescription(Rec, DescriptionSelected);
                        RedistributeTotalsOnAfterValidate;
                        DescriptionSelected := Description <> '';
                    end;
                }
                field(LineQuantity; LineQuantity)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Enabled = DescriptionSelected;
                    ToolTip = 'Specifies the quantity of the item or service on the line.';
                    Width = 5;

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
                    Width = 10;

                    trigger OnValidate()
                    begin
                        O365SalesInvoiceMgmt.ValidateItemPrice(Rec);
                        RedistributeTotalsOnAfterValidate;
                    end;
                }
                field(UnitOfMeasure; UnitOfMeasure)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Price per';
                    Enabled = DescriptionSelected;
                    LookupPageID = "O365 Units of Measure List";
                    TableRelation = "Unit of Measure";
                    ToolTip = 'Specifies the sales unit of measure for this product or service.';
                    Width = 5;

                    trigger OnValidate()
                    begin
                        if UnitOfMeasure = '' then
                            UnitOfMeasure := CopyStr(xRec."Unit of Measure", 1, MaxStrLen(UnitOfMeasure));

                        if UnitOfMeasure = xRec."Unit of Measure" then
                            exit;

                        "Unit of Measure" := UnitOfMeasure;
                        O365SalesInvoiceMgmt.ValidateItemUnitOfMeasure(Rec);
                        UnitOfMeasure := CopyStr("Unit of Measure", 1, MaxStrLen(UnitOfMeasure));
                    end;
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Enabled = DescriptionSelected;
                    Width = 5;

                    trigger OnValidate()
                    begin
                        RedistributeTotalsOnAfterValidate;
                        if HasShownInvoiceDiscountNotification then
                            InvoiceDiscountNotification.Recall;
                    end;
                }
                field(VATProductPostingGroupDescription; VATProductPostingGroupDescription)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'VAT';
                    Enabled = DescriptionSelected;
                    NotBlank = true;
                    QuickEntry = false;
                    ToolTip = 'Specifies the VAT group code for this item.';
                    Visible = IsUsingVAT;
                    Width = 8;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VATProductPostingGroup: Record "VAT Product Posting Group";
                    begin
                        if PAGE.RunModal(PAGE::"O365 VAT Product Posting Gr.", VATProductPostingGroup) = ACTION::LookupOK then begin
                            Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
                            VATProductPostingGroupDescription := VATProductPostingGroup.Description;
                            O365SalesInvoiceMgmt.ValidateVATRate(Rec);
                            RedistributeTotalsOnAfterValidate;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        RedistributeTotalsOnAfterValidate;
                    end;
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Enabled = DescriptionSelected;

                    trigger OnValidate()
                    begin
                        RedistributeTotalsOnAfterValidate;
                    end;
                }
                field("Price description"; "Price description")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Visible = ShowOnlyOnBrick AND IsDevice;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OpenPrice)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'View Price';
                Image = View;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Opens the price card.';

                trigger OnAction()
                var
                    Item: Record Item;
                begin
                    if "No." = '' then
                        exit;
                    if Item.Get("No.") then
                        PAGE.RunModal(PAGE::"BC O365 Item Card", Item);
                end;
            }
            action(DeleteLine)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Delete Line';
                Gesture = RightSwipe;
                Image = DeleteRow;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Delete the selected line.';

                trigger OnAction()
                begin
                    if "No." = '' then
                        exit;

                    if not Confirm(DeleteQst, true) then
                        exit;
                    Delete(true);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DescriptionSelected := Description <> '';
    end;

    trigger OnAfterGetRecord()
    begin
        UpdatePriceDescription;
        UnitOfMeasure := CopyStr("Unit of Measure", 1, MaxStrLen(UnitOfMeasure));
        O365SalesInvoiceMgmt.ConstructCurrencyFormatString(Rec, CurrencyFormat);
        CalcFields("Posting Date");
        LineQuantity := Quantity;
        UpdateVATPostingGroupDescription;
        ShowOnlyOnBrick := false;
    end;

    trigger OnInit()
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        SalesSetup.Get;
        if TaxSetup.Get then;
        Currency.InitRoundingPrecision;
        O365SalesInvoiceMgmt.ConstructCurrencyFormatString(Rec, CurrencyFormat);
        IsUsingVAT := O365SalesInitialSetup.IsUsingVAT;
        IsDevice := ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone];
        ShowOnlyOnBrick := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        UpdatePriceDescription;
        Modify(true);
        CalculateTotals;
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
        LineQuantity := 1;
        Clear(VATProductPostingGroupDescription);
    end;

    var
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        TotalSalesHeader: Record "Sales Header";
        TotalSalesLine: Record "Sales Line";
        TaxSetup: Record "Tax Setup";
        ClientTypeManagement: Codeunit "Client Type Management";
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        DocumentTotals: Codeunit "Document Totals";
        InvoiceDiscountNotification: Notification;
        CurrencyFormat: Text;
        VATProductPostingGroupDescription: Text[100];
        UnitOfMeasure: Text[10];
        VATAmount: Decimal;
        LineQuantity: Decimal;
        HasShownInvoiceDiscountNotification: Boolean;
        DescriptionSelected: Boolean;
        DeleteQst: Label 'Are you sure?';
        IsUsingVAT: Boolean;
        ShowOnlyOnBrick: Boolean;
        IsDevice: Boolean;

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

    local procedure ShowInvoiceDiscountNotification()
    begin
        if HasShownInvoiceDiscountNotification then
            exit;
        if "Line Discount %" = xRec."Line Discount %" then
            exit;
        O365SalesInvoiceMgmt.ShowInvoiceDiscountNotification(InvoiceDiscountNotification, RecordId);
        HasShownInvoiceDiscountNotification := true;
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

