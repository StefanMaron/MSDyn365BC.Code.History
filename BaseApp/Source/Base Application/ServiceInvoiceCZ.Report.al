report 31088 "Service - Invoice CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ServiceInvoiceCZ.rdlc';
    Caption = 'Service - Invoice CZ';
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
        dataitem("Service Invoice Header"; "Service Invoice Header")
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
            column(SalespersonLbl; SalespersonLbl)
            {
            }
            column(UoMLbl; UoMLbl)
            {
            }
            column(CreatorLbl; CreatorLbl)
            {
            }
            column(SubtotalLbl; SubtotalLbl)
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
            column(PaymentsLbl; PaymentsLbl)
            {
            }
            column(DisplayAdditionalFeeNote; DisplayAdditionalFeeNote)
            {
            }
            column(No_ServiceInvoiceHeader; "No.")
            {
            }
            column(VATRegistrationNo_ServiceInvoiceHeaderCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_ServiceInvoiceHeader; "VAT Registration No.")
            {
            }
            column(RegistrationNo_ServiceInvoiceHeaderCaption; FieldCaption("Registration No."))
            {
            }
            column(RegistrationNo_ServiceInvoiceHeader; "Registration No.")
            {
            }
            column(BankAccountNo_ServiceInvoiceHeaderCaption; FieldCaption("Bank Account No."))
            {
            }
            column(BankAccountNo_ServiceInvoiceHeader; "Bank Account No.")
            {
            }
            column(IBAN_ServiceInvoiceHeaderCaption; FieldCaption(IBAN))
            {
            }
            column(IBAN_ServiceInvoiceHeader; IBAN)
            {
            }
            column(BIC_ServiceInvoiceHeaderCaption; FieldCaption("SWIFT Code"))
            {
            }
            column(BIC_ServiceInvoiceHeader; "SWIFT Code")
            {
            }
            column(PostingDate_ServiceInvoiceHeaderCaption; FieldCaption("Posting Date"))
            {
            }
            column(PostingDate_ServiceInvoiceHeader; "Posting Date")
            {
            }
            column(VATDate_ServiceInvoiceHeaderCaption; FieldCaption("VAT Date"))
            {
            }
            column(VATDate_ServiceInvoiceHeader; "VAT Date")
            {
            }
            column(DueDate_ServiceInvoiceHeaderCaption; FieldCaption("Due Date"))
            {
            }
            column(DueDate_ServiceInvoiceHeader; "Due Date")
            {
            }
            column(DocumentDate_ServiceInvoiceHeaderCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_ServiceInvoiceHeader; "Document Date")
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
            column(OrderNoLbl; OrderNoLbl)
            {
            }
            column(OrderNo_ServiceInvoiceHeader; "Order No.")
            {
            }
            column(YourReference_ServiceInvoiceHeaderCaption; FieldCaption("Your Reference"))
            {
            }
            column(YourReference_ServiceInvoiceHeader; "Your Reference")
            {
            }
            column(CurrencyCode_ServiceInvoiceHeader; "Currency Code")
            {
            }
            column(PerformCountryRegionCode; RegistrationCountryRegion."Country/Region Code")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                ObsoleteTag = '15.3';
            }
            column(PerformVATRegistrationNo; RegistrationCountryRegion."VAT Registration No.")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                ObsoleteTag = '15.3';
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
                    DataItemLinkReference = "Service Invoice Header";
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
                dataitem("Service Invoice Line"; "Service Invoice Line")
                {
                    DataItemLink = "Document No." = FIELD("No.");
                    DataItemLinkReference = "Service Invoice Header";
                    DataItemTableView = SORTING("Document No.", "Line No.");
                    column(LineNo_ServiceInvoiceLine; "Line No.")
                    {
                    }
                    column(Type_ServiceInvoiceLine; Format(Type, 0, 2))
                    {
                    }
                    column(No_ServiceInvoiceLineCaption; FieldCaption("No."))
                    {
                    }
                    column(No_ServiceInvoiceLine; "No.")
                    {
                    }
                    column(Description_ServiceInvoiceLineCaption; FieldCaption(Description))
                    {
                    }
                    column(Description_ServiceInvoiceLine; Description)
                    {
                    }
                    column(Quantity_ServiceInvoiceLineCaption; FieldCaption(Quantity))
                    {
                    }
                    column(Quantity_ServiceInvoiceLine; Quantity)
                    {
                    }
                    column(UnitofMeasure_ServiceInvoiceLine; "Unit of Measure")
                    {
                    }
                    column(UnitPrice_ServiceInvoiceLineCaption; FieldCaption("Unit Price"))
                    {
                    }
                    column(UnitPrice_ServiceInvoiceLine; "Unit Price")
                    {
                    }
                    column(LineDiscount_ServiceInvoiceLineCaption; FieldCaption("Line Discount %"))
                    {
                    }
                    column(LineDiscount_ServiceInvoiceLine; "Line Discount %")
                    {
                    }
                    column(VAT_ServiceInvoiceLineCaption; FieldCaption("VAT %"))
                    {
                    }
                    column(VAT_ServiceInvoiceLine; "VAT %")
                    {
                    }
                    column(LineAmount_ServiceInvoiceLineCaption; FieldCaption("Line Amount"))
                    {
                    }
                    column(LineAmount_ServiceInvoiceLine; "Line Amount")
                    {
                    }
                    column(InvDiscountAmount_ServiceInvoiceLineCaption; FieldCaption("Inv. Discount Amount"))
                    {
                    }
                    column(InvDiscountAmount_ServiceInvoiceLine; "Inv. Discount Amount")
                    {
                    }
                    column(Amount_ServiceInvoiceLineCaption; FieldCaption(Amount))
                    {
                    }
                    column(Amount_ServiceInvoiceLine; Amount)
                    {
                    }
                    column(AmountIncludingVAT_ServiceInvoiceLineCaption; FieldCaption("Amount Including VAT"))
                    {
                    }
                    column(AmountIncludingVAT_ServiceInvoiceLine; "Amount Including VAT")
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
                        AutoFormatExpression = "Service Invoice Line".GetCurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Service Invoice Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATBaseLCY; TempVATAmountLine."VAT Base (LCY)")
                    {
                        AutoFormatExpression = "Service Invoice Line".GetCurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmtLCY; TempVATAmountLine."VAT Amount (LCY)")
                    {
                        AutoFormatExpression = "Service Invoice Header"."Currency Code";
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
                            CurrReport.Skip();
                        VATClause.GetDescription("Service Invoice Header");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempVATAmountLine.Count);
                    end;
                }
                dataitem(LineFee; "Integer")
                {
                    DataItemTableView = SORTING(Number) ORDER(Ascending) WHERE(Number = FILTER(1 ..));
                    column(LineFeeCaptionLbl; TempLineFeeNoteOnReportHist.ReportText)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not TempLineFeeNoteOnReportHist.FindSet then
                                CurrReport.Break
                        end else
                            if TempLineFeeNoteOnReportHist.Next = 0 then
                                CurrReport.Break();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not DisplayAdditionalFeeNote then
                            CurrReport.Break();
                        SetRange(Number, 1, TempLineFeeNoteOnReportHist.Count);
                    end;
                }
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLink = "User ID" = FIELD("User ID");
                    DataItemLinkReference = "Service Invoice Header";
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
                        CODEUNIT.Run(CODEUNIT::"Service Inv.-Printed", "Service Invoice Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + Customer."Invoice Copies" + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;

                    SetRange(Number, 1, NoOfLoops);
                end;
            }

            trigger OnAfterGetRecord()
            var
                ServiceInvLine: Record "Service Invoice Line";
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

                FormatAddressFields("Service Invoice Header");
                FormatDocumentFields("Service Invoice Header");

                if not Customer.Get("Bill-to Customer No.") then
                    Clear(Customer);

                if "Tax Corrective Document" then
                    DocumentLbl := DocumentLbl1
                else
                    DocumentLbl := DocumentLbl0;

                ServiceInvLine.CalcVATAmountLines("Service Invoice Header", TempVATAmountLine);

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

                GetLineFeeNoteOnReportHist("No.");

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
                    field(DisplayAdditionalFeeNote; DisplayAdditionalFeeNote)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Additional Fee Note';
                        ToolTip = 'Specifies when the additional fee note is to be show';
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
        ExchRateLbl: Label 'Exchange Rate %1 %2 / %3 %4', Comment = 'Amount Currency / Local Currency';
        DocumentLbl0: Label 'Invoice';
        DocumentLbl1: Label 'Corrective Tax Document';
        PageLbl: Label 'Page';
        CopyLbl: Label 'Copy';
        VendLbl: Label 'Vendor';
        CustLbl: Label 'Customer';
        ShipToLbl: Label 'Ship-to';
        PaymentTermsLbl: Label 'Payment Terms';
        PaymentMethodLbl: Label 'Payment Method';
        SalespersonLbl: Label 'Salesperson';
        UoMLbl: Label 'UoM';
        CreatorLbl: Label 'Posted by';
        SubtotalLbl: Label 'Subtotal';
        DiscPercentLbl: Label 'Discount %';
        VATIdentLbl: Label 'VAT Recapitulation';
        VATPercentLbl: Label 'VAT %';
        VATBaseLbl: Label 'VAT Base';
        VATAmtLbl: Label 'VAT Amount';
        TotalLbl: Label 'total';
        VATLbl: Label 'VAT';
        PaymentsLbl: Label 'Payments List';
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempLineFeeNoteOnReportHist: Record "Line Fee Note on Report Hist." temporary;
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        ReasonCode: Record "Reason Code";
        CurrExchRate: Record "Currency Exchange Rate";
        VATClause: Record "VAT Clause";
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
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
        DocumentLbl: Text;
        CalculatedExchRate: Decimal;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        DisplayAdditionalFeeNote: Boolean;
        OrderNoLbl: Label 'Order No.';

    local procedure GetLineFeeNoteOnReportHist(ServiceInvoiceHeaderNo: Code[20])
    var
        LineFeeNoteOnReportHist: Record "Line Fee Note on Report Hist.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
    begin
        TempLineFeeNoteOnReportHist.DeleteAll();
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", ServiceInvoiceHeaderNo);
        if not CustLedgerEntry.FindFirst then
            exit;

        if not Customer.Get(CustLedgerEntry."Customer No.") then
            exit;

        LineFeeNoteOnReportHist.SetRange("Cust. Ledger Entry No", CustLedgerEntry."Entry No.");
        LineFeeNoteOnReportHist.SetRange("Language Code", Customer."Language Code");
        if LineFeeNoteOnReportHist.FindSet then begin
            repeat
                TempLineFeeNoteOnReportHist.Init();
                TempLineFeeNoteOnReportHist.Copy(LineFeeNoteOnReportHist);
                TempLineFeeNoteOnReportHist.Insert();
            until LineFeeNoteOnReportHist.Next = 0;
        end else begin
            LineFeeNoteOnReportHist.SetRange("Language Code", Language.GetUserLanguageCode);
            if LineFeeNoteOnReportHist.FindSet then
                repeat
                    TempLineFeeNoteOnReportHist.Init();
                    TempLineFeeNoteOnReportHist.Copy(LineFeeNoteOnReportHist);
                    TempLineFeeNoteOnReportHist.Insert();
                until LineFeeNoteOnReportHist.Next = 0;
        end;
    end;

    local procedure FormatDocumentFields(ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        with ServiceInvoiceHeader do begin
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

    local procedure FormatAddressFields(ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        FormatAddr.ServiceInvBillTo(CustAddr, ServiceInvoiceHeader);
        FormatAddr.ServiceInvShipTo(ShipToAddr, CustAddr, ServiceInvoiceHeader);
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;
}

