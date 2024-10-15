report 31097 "Sales - Credit Memo CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './SalesCreditMemoCZ.rdlc';
    Caption = 'Sales - Credit Memo CZ';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Company Information"; "Company Information")
        {
            DataItemTableView = SORTING("Primary Key");
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(RegistrationNo_CompanyInformation; "Registration No.")
            {
            }
            column(VATRegistrationNo_CompanyInformation; "VAT Registration No.")
            {
            }
            column(HomePage_CompanyInformation; "Home Page")
            {
            }
            column(Picture_CompanyInformation; Picture)
            {
            }
            dataitem("Sales & Receivables Setup"; "Sales & Receivables Setup")
            {
                DataItemTableView = SORTING("Primary Key");
                column(LogoPositiononDocuments_SalesReceivablesSetup; Format("Logo Position on Documents", 0, 2))
                {
                }
                dataitem("General Ledger Setup"; "General Ledger Setup")
                {
                    DataItemTableView = SORTING("Primary Key");
                    column(LCYCode_GeneralLedgerSetup; "LCY Code")
                    {
                    }
                }
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.Company(CompanyAddr, "Company Information");
            end;
        }
        dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
        {
            column(DocumentLbl; DocumentLbl)
            {
            }
            column(PageLbl; PageLbl)
            {
            }
            column(CopyLbl; CopyLbl)
            {
            }
            column(VendorLbl; VendLbl)
            {
            }
            column(CustomerLbl; CustLbl)
            {
            }
            column(ShipToLbl; ShipToLbl)
            {
            }
            column(PaymentTermsLbl; PaymentTermsLbl)
            {
            }
            column(PaymentMethodLbl; PaymentMethodLbl)
            {
            }
            column(ShipmentMethodLbl; ShipmentMethodLbl)
            {
            }
            column(ToInvoiceLbl; ToInvoiceLbl)
            {
            }
            column(YourReferenceLbl; YourReferenceLbl)
            {
            }
            column(SalespersonLbl; SalespersonLbl)
            {
            }
            column(UoMLbl; UoMLbl)
            {
            }
            column(CreatorLbl; CreatorLbl)
            {
            }
            column(SubtottalLbl; SubtottalLbl)
            {
            }
            column(DiscPercentLbl; DiscPercentLbl)
            {
            }
            column(VATIdentLbl; VATIdentLbl)
            {
            }
            column(VATPercentLbl; VATPercentLbl)
            {
            }
            column(VATBaseLbl; VATBaseLbl)
            {
            }
            column(VATAmtLbl; VATAmtLbl)
            {
            }
            column(TotalLbl; TotalLbl)
            {
            }
            column(VATLbl; VATLbl)
            {
            }
            column(Type2Text1; Type2Text1Lbl)
            {
            }
            column(Type2Text2; Type2Text2Lbl)
            {
            }
            column(Type2Text3; Type2Text3Lbl)
            {
            }
            column(Type2Text4; Type2Text4Lbl)
            {
            }
            column(Type3Text; Type3TextLbl)
            {
            }
            column(No_SalesCrMemoHeader; "No.")
            {
            }
            column(CreditMemoType_SalesCrMemoHeader; Format("Credit Memo Type", 0, 2))
            {
            }
            column(VATRegistrationNo_SalesCrMemoHeaderCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_SalesCrMemoHeader; "VAT Registration No.")
            {
            }
            column(RegistrationNo_SalesCrMemoHeaderCaption; FieldCaption("Registration No."))
            {
            }
            column(RegistrationNo_SalesCrMemoHeader; "Registration No.")
            {
            }
            column(BankAccountNo_SalesCrMemoHeaderCaption; FieldCaption("Bank Account No."))
            {
            }
            column(BankAccountNo_SalesCrMemoHeader; "Bank Account No.")
            {
            }
            column(IBAN_SalesCrMemoHeaderCaption; FieldCaption(IBAN))
            {
            }
            column(IBAN_SalesCrMemoHeader; IBAN)
            {
            }
            column(BIC_SalesCrMemoHeaderCaption; FieldCaption("SWIFT Code"))
            {
            }
            column(BIC_SalesCrMemoHeader; "SWIFT Code")
            {
            }
            column(PostingDate_SalesCrMemoHeaderCaption; FieldCaption("Posting Date"))
            {
            }
            column(PostingDate_SalesCrMemoHeader; "Posting Date")
            {
            }
            column(VATDate_SalesCrMemoHeaderCaption; FieldCaption("VAT Date"))
            {
            }
            column(VATDate_SalesCrMemoHeader; "VAT Date")
            {
            }
            column(DueDate_SalesCrMemoHeaderCaption; FieldCaption("Due Date"))
            {
            }
            column(DueDate_SalesCrMemoHeader; "Due Date")
            {
            }
            column(DocumentDate_SalesCrMemoHeaderCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_SalesCrMemoHeader; "Document Date")
            {
            }
            column(PmntSymbol1; PaymentSymbolLabel[1])
            {
            }
            column(PmntSymbol2; PaymentSymbol[1])
            {
            }
            column(PmntSymbol3; PaymentSymbolLabel[2])
            {
            }
            column(PmntSymbol4; PaymentSymbol[2])
            {
            }
            column(PaymentTerms; PaymentTerms.Description)
            {
            }
            column(PaymentMethod; PaymentMethod.Description)
            {
            }
            column(ReasonCode; ReasonCode.Description)
            {
            }
            column(AppliestoDocNo_SalesCrMemoHeader; "Applies-to Doc. No.")
            {
            }
            column(ExternalDocumentNo_SalesCrMemoHeader; "External Document No.")
            {
            }
            column(ShipmentMethod; ShipmentMethod.Description)
            {
            }
            column(CurrencyCode_SalesCrMemoHeader; "Currency Code")
            {
            }
            column(Amount_SalesCrMemoHeaderCaption; FieldCaption(Amount))
            {
            }
            column(Amount_SalesCrMemoHeader; Amount)
            {
            }
            column(AmountIncludingVAT_SalesCrMemoHeaderCaption; FieldCaption("Amount Including VAT"))
            {
            }
            column(AmountIncludingVAT_SalesCrMemoHeader; "Amount Including VAT")
            {
            }
            column(PostponedVAT_SalesCrMemoHeader; "Postponed VAT")
            {
            }
            column(PerformCountryRegionCode; RegCountryRegion."Country/Region Code")
            {
            }
            column(PerformVATRegistrationNo; RegCountryRegion."VAT Registration No.")
            {
            }
            column(CalculatedExchRate; CalculatedExchRate)
            {
            }
            column(ExchRateText; ExchRateText)
            {
            }
            column(DocFooterText; DocFooterText)
            {
            }
            column(CustAddr1; CustAddr[1])
            {
            }
            column(CustAddr2; CustAddr[2])
            {
            }
            column(CustAddr3; CustAddr[3])
            {
            }
            column(CustAddr4; CustAddr[4])
            {
            }
            column(CustAddr5; CustAddr[5])
            {
            }
            column(CustAddr6; CustAddr[6])
            {
            }
            column(ShipToAddr1; ShipToAddr[1])
            {
            }
            column(ShipToAddr2; ShipToAddr[2])
            {
            }
            column(ShipToAddr3; ShipToAddr[3])
            {
            }
            column(ShipToAddr4; ShipToAddr[4])
            {
            }
            column(ShipToAddr5; ShipToAddr[5])
            {
            }
            column(ShipToAddr6; ShipToAddr[6])
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(CopyNo; Number)
                {
                }
                dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
                {
                    DataItemLink = Code = FIELD("Salesperson Code");
                    DataItemLinkReference = "Sales Cr.Memo Header";
                    DataItemTableView = SORTING(Code);
                    column(Name_SalespersonPurchaser; Name)
                    {
                    }
                    column(EMail_SalespersonPurchaser; "E-Mail")
                    {
                    }
                    column(PhoneNo_SalespersonPurchaser; "Phone No.")
                    {
                    }
                }
                dataitem("Sales Cr.Memo Line"; "Sales Cr.Memo Line")
                {
                    DataItemLink = "Document No." = FIELD("No.");
                    DataItemLinkReference = "Sales Cr.Memo Header";
                    DataItemTableView = SORTING("Document No.", "Line No.");
                    column(LineNo_SalesCrMemoLine; "Line No.")
                    {
                    }
                    column(Type_SalesCrMemoLine; Format(Type, 0, 2))
                    {
                    }
                    column(No_SalesCrMemoLineCaption; FieldCaption("No."))
                    {
                    }
                    column(No_SalesCrMemoLine; "No.")
                    {
                    }
                    column(Description_SalesCrMemoLineCaption; FieldCaption(Description))
                    {
                    }
                    column(Description_SalesCrMemoLine; Description)
                    {
                    }
                    column(Quantity_SalesCrMemoLineCaption; FieldCaption(Quantity))
                    {
                    }
                    column(Quantity_SalesCrMemoLine; Quantity)
                    {
                    }
                    column(UnitofMeasure_SalesCrMemoLine; "Unit of Measure")
                    {
                    }
                    column(UnitPrice_SalesCrMemoLineCaption; FieldCaption("Unit Price"))
                    {
                    }
                    column(UnitPrice_SalesCrMemoLine; "Unit Price")
                    {
                    }
                    column(LineDiscount_SalesCrMemoLineCaption; FieldCaption("Line Discount %"))
                    {
                    }
                    column(LineDiscount_SalesCrMemoLine; "Line Discount %")
                    {
                    }
                    column(VAT_SalesCrMemoLineCaption; FieldCaption("VAT %"))
                    {
                    }
                    column(VAT_SalesCrMemoLine; "VAT %")
                    {
                    }
                    column(LineAmount_SalesCrMemoLineCaption; FieldCaption("Line Amount"))
                    {
                    }
                    column(LineAmount_SalesCrMemoLine; "Line Amount")
                    {
                    }
                    column(InvDiscountAmount_SalesCrMemoLineCaption; FieldCaption("Inv. Discount Amount"))
                    {
                    }
                    column(InvDiscountAmount_SalesCrMemoLine; "Inv. Discount Amount")
                    {
                    }
                }
                dataitem(VATCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(VATAmtLineVATIdentifier; TempVATAmountLine."VAT Identifier")
                    {
                    }
                    column(VATAmtLineVATPer; TempVATAmountLine."VAT %")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(VATAmtLineVATBase; TempVATAmountLine."VAT Base")
                    {
                        AutoFormatExpression = "Sales Cr.Memo Line".GetCurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATBaseLCY; TempVATAmountLine."VAT Base (LCY)")
                    {
                        AutoFormatExpression = "Sales Cr.Memo Line".GetCurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmtLCY; TempVATAmountLine."VAT Amount (LCY)")
                    {
                        AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempVATAmountLine.Count);
                    end;
                }
                dataitem(VATClauseEntryCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(VATClauseIdentifier; TempVATAmountLine."VAT Identifier")
                    {
                    }
                    column(VATClauseDescription; VATClause.Description)
                    {
                    }
                    column(VATClauseDescription2; VATClause."Description 2")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);
                        if not VATClause.Get(TempVATAmountLine."VAT Clause Code") then
                            CurrReport.Skip;
                        VATClause.GetDescription("Sales Cr.Memo Header");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempVATAmountLine.Count);
                    end;
                }
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLink = "User ID" = FIELD("User ID");
                    DataItemLinkReference = "Sales Cr.Memo Header";
                    DataItemTableView = SORTING("User ID");
                    dataitem(Employee; Employee)
                    {
                        DataItemLink = "No." = FIELD("Employee No.");
                        DataItemTableView = SORTING("No.");
                        column(FullName_Employee; FullName)
                        {
                        }
                        column(PhoneNo_Employee; "Phone No.")
                        {
                        }
                        column(CompanyEMail_Employee; "Company E-Mail")
                        {
                        }
                    }
                }

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode then
                        CODEUNIT.Run(CODEUNIT::"Sales Cr. Memo-Printed", "Sales Cr.Memo Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + Cust."Invoice Copies" + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;

                    SetRange(Number, 1, NoOfLoops);
                end;
            }

            trigger OnAfterGetRecord()
            var
                SalesCrMemoLine: Record "Sales Cr.Memo Line";
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                FormatAddressFields("Sales Cr.Memo Header");
                FormatDocumentFields("Sales Cr.Memo Header");

                if not Cust.Get("Bill-to Customer No.") then
                    Clear(Cust);

                case "Credit Memo Type" of
                    0,
                  "Credit Memo Type"::"Corrective Tax Document":
                        DocumentLbl := DocumentLbl1;
                    "Credit Memo Type"::"Internal Correction":
                        DocumentLbl := DocumentLbl2;
                    "Credit Memo Type"::"Insolvency Tax Document":
                        DocumentLbl := DocumentLbl3;
                end;

                SalesCrMemoLine.CalcVATAmountLines("Sales Cr.Memo Header", TempVATAmountLine);

                if "Currency Code" = '' then
                    "Currency Code" := "General Ledger Setup"."LCY Code";

                if ("Currency Factor" <> 0) and ("Currency Factor" <> 1) then begin
                    CurrExchRate.FindCurrency("Posting Date", "Currency Code", 1);
                    CalculatedExchRate := Round(1 / "Currency Factor" * CurrExchRate."Exchange Rate Amount", 0.00001);
                    ExchRateText :=
                      StrSubstNo(ExchRateLbl, CalculatedExchRate, "General Ledger Setup"."LCY Code",
                        CurrExchRate."Exchange Rate Amount", "Currency Code");
                end else
                    CalculatedExchRate := 1;

                if LogInteraction and not IsReportInPreviewMode then
                    if "Bill-to Contact No." <> '' then
                        SegMgt.LogDocument(
                          6, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.", "Salesperson Code",
                          "Campaign No.", "Posting Description", '')
                    else
                        SegMgt.LogDocument(
                          6, "No.", 0, 0, DATABASE::Customer, "Sell-to Customer No.", "Salesperson Code",
                          "Campaign No.", "Posting Description", '');

                if not RegCountryRegion.Get(
                     RegCountryRegion."Account Type"::"Company Information", '', "Perform. Country/Region Code")
                then
                    Clear(RegCountryRegion)
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies the number of copies to print.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the program to record the sales credit memo you print as Interactions and add them to the Interaction Log Entry table.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            InitLogInteraction;
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction;
    end;

    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Cust: Record Customer;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        ShipmentMethod: Record "Shipment Method";
        ReasonCode: Record "Reason Code";
        CurrExchRate: Record "Currency Exchange Rate";
        VATClause: Record "VAT Clause";
        RegCountryRegion: Record "Registration Country/Region";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegMgt: Codeunit SegManagement;
        ExchRateText: Text[50];
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        DocFooterText: Text[250];
        PaymentSymbol: array[2] of Text;
        PaymentSymbolLabel: array[2] of Text;
        DocumentLbl: Text;
        CalculatedExchRate: Decimal;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        LogInteraction: Boolean;
        ExchRateLbl: Label 'Exchange Rate %1 %2 / %3 %4', Comment = 'Amount Currency / Local Currency';
        DocumentLbl1: Label 'Corrective Tax Document';
        DocumentLbl2: Label 'Internal Correction';
        DocumentLbl3: Label 'Insolvency Tax Document';
        PageLbl: Label 'Page';
        CopyLbl: Label 'Copy';
        VendLbl: Label 'Vendor';
        CustLbl: Label 'Customer';
        ShipToLbl: Label 'Ship-to';
        PaymentTermsLbl: Label 'Payment Terms';
        PaymentMethodLbl: Label 'Payment Method';
        ShipmentMethodLbl: Label 'Shipment Method';
        ToInvoiceLbl: Label 'To Invoice';
        YourReferenceLbl: Label 'Your Reference';
        SalespersonLbl: Label 'Salesperson';
        UoMLbl: Label 'UoM';
        CreatorLbl: Label 'Posted by';
        SubtottalLbl: Label 'Subtotal';
        DiscPercentLbl: Label 'Discount %';
        VATIdentLbl: Label 'VAT Recapitulation';
        VATPercentLbl: Label 'VAT %';
        VATBaseLbl: Label 'VAT Base';
        VATAmtLbl: Label 'VAT Amount';
        TotalLbl: Label 'total';
        VATLbl: Label 'VAT';
        Type2Text1Lbl: Label 'According to Law 235/2004 Collection of Value Added Tax confirm receipt of Corrective Tax Document.';
        Type2Text2Lbl: Label 'Delivery Date';
        Type2Text3Lbl: Label 'Signature and Stamp of the Customer';
        Type2Text4Lbl: Label 'Confirmed Corrective Tax Document indicating the Date of Receipt sent back please.';
        Type3TextLbl: Label 'Tax Certificate when performing Correction the Duties of Receivables from Debtors in Bankruptcy Proceedings';
        [InDataSet]
        LogInteractionEnable: Boolean;

    [Scope('OnPrem')]
    procedure InitLogInteraction()
    begin
        LogInteraction := SegMgt.FindInteractTmplCode(6) <> '';
    end;

    local procedure FormatDocumentFields(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        with SalesCrMemoHeader do begin
            FormatDocument.SetPaymentTerms(PaymentTerms, "Payment Terms Code", "Language Code");
            FormatDocument.SetShipmentMethod(ShipmentMethod, "Shipment Method Code", "Language Code");
            FormatDocument.SetPaymentMethod(PaymentMethod, "Payment Method Code", "Language Code");

            if "Reason Code" = '' then
                ReasonCode.Init
            else
                ReasonCode.Get("Reason Code");

            FormatDocument.SetPaymentSymbols(
              PaymentSymbol, PaymentSymbolLabel,
              "Variable Symbol", FieldCaption("Variable Symbol"),
              "Constant Symbol", FieldCaption("Constant Symbol"),
              "Specific Symbol", FieldCaption("Specific Symbol"));
            DocFooterText := FormatDocument.GetDocumentFooterText("Language Code");
        end;
    end;

    local procedure FormatAddressFields(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        FormatAddr.SalesCrMemoBillTo(CustAddr, SalesCrMemoHeader);
        FormatAddr.SalesCrMemoShipTo(ShipToAddr, CustAddr, SalesCrMemoHeader);
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;
}

