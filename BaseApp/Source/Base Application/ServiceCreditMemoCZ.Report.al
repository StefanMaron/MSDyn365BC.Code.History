report 31089 "Service - Credit Memo CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ServiceCreditMemoCZ.rdlc';
    Caption = 'Service - Credit Memo CZ';
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
            dataitem("Service Mgt. Setup"; "Service Mgt. Setup")
            {
                DataItemTableView = SORTING("Primary Key");
                column(LogoPositiononDocuments_ServiceMgtSetup; Format("Logo Position on Documents", 0, 2))
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
        dataitem("Service Cr.Memo Header"; "Service Cr.Memo Header")
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
            column(ToInvoiceLbl; ToInvoiceLbl)
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
            column(No_ServiceCrMemoHeader; "No.")
            {
            }
            column(VATRegistrationNo_ServiceCrMemoHeaderCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_ServiceCrMemoHeader; "VAT Registration No.")
            {
            }
            column(RegistrationNo_ServiceCrMemoHeaderCaption; FieldCaption("Registration No."))
            {
            }
            column(RegistrationNo_ServiceCrMemoHeader; "Registration No.")
            {
            }
            column(BankAccountNo_ServiceCrMemoHeaderCaption; FieldCaption("Bank Account No."))
            {
            }
            column(BankAccountNo_ServiceCrMemoHeader; "Bank Account No.")
            {
            }
            column(IBAN_ServiceCrMemoHeaderCaption; FieldCaption(IBAN))
            {
            }
            column(IBAN_ServiceCrMemoHeader; IBAN)
            {
            }
            column(BIC_ServiceCrMemoHeaderCaption; FieldCaption("SWIFT Code"))
            {
            }
            column(BIC_ServiceCrMemoHeader; "SWIFT Code")
            {
            }
            column(PostingDate_ServiceCrMemoHeaderCaption; FieldCaption("Posting Date"))
            {
            }
            column(PostingDate_ServiceCrMemoHeader; "Posting Date")
            {
            }
            column(VATDate_ServiceCrMemoHeaderCaption; FieldCaption("VAT Date"))
            {
            }
            column(VATDate_ServiceCrMemoHeader; "VAT Date")
            {
            }
            column(DueDate_ServiceCrMemoHeaderCaption; FieldCaption("Due Date"))
            {
            }
            column(DueDate_ServiceCrMemoHeader; "Due Date")
            {
            }
            column(DocumentDate_ServiceCrMemoHeaderCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_ServiceCrMemoHeader; "Document Date")
            {
            }
            column(YourReference_ServiceCrMemoHeaderCaption; FieldCaption("Your Reference"))
            {
            }
            column(YourReference_ServiceCrMemoHeader; "Your Reference")
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
            column(AppliestoDocNo_ServiceCrMemoHeader; "Applies-to Doc. No.")
            {
            }
            column(CurrencyCode_ServiceCrMemoHeader; "Currency Code")
            {
            }
            column(PerformCountryRegionCode; RegistrationCountryRegion."Country/Region Code")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            }
            column(PerformVATRegistrationNo; RegistrationCountryRegion."VAT Registration No.")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
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
                    DataItemLinkReference = "Service Cr.Memo Header";
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
                dataitem("Service Cr.Memo Line"; "Service Cr.Memo Line")
                {
                    DataItemLink = "Document No." = FIELD("No.");
                    DataItemLinkReference = "Service Cr.Memo Header";
                    DataItemTableView = SORTING("Document No.", "Line No.");
                    column(LineNo_ServiceCrMemoLine; "Line No.")
                    {
                    }
                    column(Type_ServiceCrMemoLine; Format(Type, 0, 2))
                    {
                    }
                    column(No_ServiceCrMemoLineCaption; FieldCaption("No."))
                    {
                    }
                    column(No_ServiceCrMemoLine; "No.")
                    {
                    }
                    column(Description_ServiceCrMemoLineCaption; FieldCaption(Description))
                    {
                    }
                    column(Description_ServiceCrMemoLine; Description)
                    {
                    }
                    column(Quantity_ServiceCrMemoLineCaption; FieldCaption(Quantity))
                    {
                    }
                    column(Quantity_ServiceCrMemoLine; Quantity)
                    {
                    }
                    column(UnitofMeasure_ServiceCrMemoLine; "Unit of Measure")
                    {
                    }
                    column(UnitPrice_ServiceCrMemoLineCaption; FieldCaption("Unit Price"))
                    {
                    }
                    column(UnitPrice_ServiceCrMemoLine; "Unit Price")
                    {
                    }
                    column(LineDiscount_ServiceCrMemoLineCaption; FieldCaption("Line Discount %"))
                    {
                    }
                    column(LineDiscount_ServiceCrMemoLine; "Line Discount %")
                    {
                    }
                    column(VAT_ServiceCrMemoLineCaption; FieldCaption("VAT %"))
                    {
                    }
                    column(VAT_ServiceCrMemoLine; "VAT %")
                    {
                    }
                    column(LineAmount_ServiceCrMemoLineCaption; FieldCaption("Line Amount"))
                    {
                    }
                    column(LineAmount_ServiceCrMemoLine; "Line Amount")
                    {
                    }
                    column(InvDiscountAmount_ServiceCrMemoLineCaption; FieldCaption("Inv. Discount Amount"))
                    {
                    }
                    column(InvDiscountAmount_ServiceCrMemoLine; "Inv. Discount Amount")
                    {
                    }
                    column(Amount_ServiceCrMemoLineCaption; FieldCaption(Amount))
                    {
                    }
                    column(Amount_ServiceCrMemoLine; Amount)
                    {
                    }
                    column(AmountIncludingVAT_ServiceCrMemoLineCaption; FieldCaption("Amount Including VAT"))
                    {
                    }
                    column(AmountIncludingVAT_ServiceCrMemoLine; "Amount Including VAT")
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
                        AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATBaseLCY; TempVATAmountLine."VAT Base (LCY)")
                    {
                        AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmtLCY; TempVATAmountLine."VAT Amount (LCY)")
                    {
                        AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
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
                        VATClause.GetDescription("Service Cr.Memo Header");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempVATAmountLine.Count);
                    end;
                }
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLink = "User ID" = FIELD("User ID");
                    DataItemLinkReference = "Service Cr.Memo Header";
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
                        CODEUNIT.Run(CODEUNIT::"Service Cr. Memo-Printed", "Service Cr.Memo Header");
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
                ServiceCrMemoLine: Record "Service Cr.Memo Line";
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                FormatAddressFields("Service Cr.Memo Header");
                FormatDocumentFields("Service Cr.Memo Header");

                if not Cust.Get("Bill-to Customer No.") then
                    Clear(Cust);

                ServiceCrMemoLine.CalcVATAmountLines("Service Cr.Memo Header", TempVATAmountLine);

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

                if not RegistrationCountryRegion.Get(
                     RegistrationCountryRegion."Account Type"::"Company Information", '', "Perform. Country/Region Code")
                then
                    Clear(RegistrationCountryRegion);
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
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Cust: Record Customer;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        ReasonCode: Record "Reason Code";
        CurrExchRate: Record "Currency Exchange Rate";
        VATClause: Record "VAT Clause";
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)')]
        RegistrationCountryRegion: Record "Registration Country/Region";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        ExchRateText: Text[50];
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        DocFooterText: Text[250];
        PaymentSymbol: array[2] of Text;
        PaymentSymbolLabel: array[2] of Text;
        CalculatedExchRate: Decimal;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        ExchRateLbl: Label 'Exchange Rate %1 %2 / %3 %4', Comment = 'Amount Currency / Local Currency';
        DocumentLbl: Label 'Service - Credit Memo';
        PageLbl: Label 'Page';
        CopyLbl: Label 'Copy';
        VendLbl: Label 'Vendor';
        CustLbl: Label 'Customer';
        ShipToLbl: Label 'Ship-to';
        PaymentTermsLbl: Label 'Payment Terms';
        PaymentMethodLbl: Label 'Payment Method';
        ToInvoiceLbl: Label 'To Invoice';
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

    local procedure FormatDocumentFields(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        with ServiceCrMemoHeader do begin
            FormatDocument.SetPaymentTerms(PaymentTerms, "Payment Terms Code", "Language Code");
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

    local procedure FormatAddressFields(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        FormatAddr.ServiceCrMemoBillTo(CustAddr, ServiceCrMemoHeader);
        FormatAddr.ServiceCrMemoShipTo(ShipToAddr, CustAddr, ServiceCrMemoHeader);
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;
}

