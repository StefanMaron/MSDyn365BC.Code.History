#if not CLEAN19
report 31002 "Sales - Advance Credit Memo CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './SalesAdvanceCreditMemoCZ.rdlc';
    Caption = 'Sales - Advance Credit Memo CZ (Obsolete)';
    PreviewMode = PrintLayout;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

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

            trigger OnPreDataItem()
            begin
                CalcFields(Picture);
            end;
        }
        dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
        {
            DataItemTableView = SORTING("Letter No.") WHERE("Letter No." = FILTER(<> ''));
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
            column(SalespersonLbl; SalespersonLbl)
            {
            }
            column(CreatorLbl; CreatorLbl)
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
            column(AdvanceLetterLbl; AdvanceLetterLbl)
            {
            }
            column(No_SalesCrMemoHeader; "No.")
            {
            }
            column(VATRegistrationNo_SalesCrMemoHeaderCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_SalesCrMemoHeader; "VAT Registration No.")
            {
            }
#if CLEAN17
            column(RegistrationNo_SalesCrMemoHeaderCaption; FieldCaptionDictionary.Get(RegistrationNoFldTok))
            {
            }
            column(RegistrationNo_SalesCrMemoHeader; FieldValueDictionary.Get(RegistrationNoFldTok))
            {
            }
#else
            column(RegistrationNo_SalesCrMemoHeaderCaption; FieldCaption("Registration No."))
            {
            }
            column(RegistrationNo_SalesCrMemoHeader; "Registration No.")
            {
            }
#endif
#if CLEAN18
            column(BankAccountNo_SalesCrMemoHeaderCaption; FieldCaptionDictionary.Get(BankAccountNoFldTok))
            {
            }
            column(BankAccountNo_SalesCrMemoHeader; FieldValueDictionary.Get(BankAccountNoFldTok))
            {
            }
            column(IBAN_SalesCrMemoHeaderCaption; FieldCaptionDictionary.Get(IBANFldTok))
            {
            }
            column(IBAN_SalesCrMemoHeader; FieldValueDictionary.Get(IBANFldTok))
            {
            }
            column(BIC_SalesCrMemoHeaderCaption; FieldCaptionDictionary.Get(SWIFTCodeFldTok))
            {
            }
            column(BIC_SalesCrMemoHeader; FieldValueDictionary.Get(SWIFTCodeFldTok))
            {
            }
#else
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
#endif
            column(DocumentDate_SalesCrMemoHeaderCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_SalesCrMemoHeader; "Document Date")
            {
            }
#if CLEAN17
            column(VATDate_SalesCrMemoHeaderCaption; FieldCaptionDictionary.Get(VATDateFldTok))
            {
            }
            column(VATDate_SalesCrMemoHeader; FieldValueDictionary.Get(VATDateFldTok))
            {
            }
#else
            column(VATDate_SalesCrMemoHeaderCaption; FieldCaption("VAT Date"))
            {
            }
            column(VATDate_SalesCrMemoHeader; "VAT Date")
            {
            }
#endif
            column(PaymentTerms; PaymentTerms.Description)
            {
            }
            column(PaymentMethod; PaymentMethod.Description)
            {
            }
            column(CurrencyCode_SalesCrMemoHeader; "Currency Code")
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
            column(LetterNo_SalesCrMemoHeader; "Letter No.")
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
            column(OrigAdvanceInvoiceLbl; OrigAdvanceInvoiceLbl)
            {
            }
            column(No_SalesInvoiceHeader; SalesInvoiceHeader."No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(CopyNo; CopyNo)
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
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemLink = "Document No." = FIELD("No."), "Posting Date" = FIELD("Posting Date");
                    DataItemLinkReference = "Sales Cr.Memo Header";
                    DataItemTableView = SORTING("Document No.", "Posting Date");

                    trigger OnAfterGetRecord()
                    begin
                        if not VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                            VATPostingSetup.Init();

                        TempVATAmountLine.Init();
#if CLEAN18
                        TempVATAmountLine."VAT Identifier" := VATPostingSetup."VAT Identifier";
#else
                        TempVATAmountLine."VAT Identifier" := "VAT Identifier";
#endif
                        TempVATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                        TempVATAmountLine."Tax Group Code" := "Tax Group Code";
                        TempVATAmountLine."VAT %" := VATPostingSetup."VAT %";
                        TempVATAmountLine."VAT Base" := "Advance Base";
                        TempVATAmountLine."Amount Including VAT" := "Advance Base" + Amount;
                        TempVATAmountLine.InsertLine;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TempVATAmountLine.DeleteAll();
                    end;
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
                        AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
#if CLEAN18
                    column(VATAmtLineVATBaseLCY; VATAmountLineVATBaseLCY)
#else
                    column(VATAmtLineVATBaseLCY; TempVATAmountLine."VAT Base (LCY)")
#endif
                    {
                        AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }
#if CLEAN18
                    column(VATAmtLineVATAmtLCY; VATAmountLineVATAmountLCY)
#else
                    column(VATAmtLineVATAmtLCY; TempVATAmountLine."VAT Amount (LCY)")
#endif
                    {
                        AutoFormatExpression = "Sales Cr.Memo Header"."Currency Code";
                        AutoFormatType = 1;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        TempVATAmountLine.GetLine(Number);

                        if CalculatedExchRate <> 1 then begin
#if CLEAN18
                            VATAmountLineVATBaseLCY := TempVATAmountLine."VAT Base";
                            VATAmountLineVATAmountLCY := TempVATAmountLine."VAT Amount";
                            TempVATAmountLine."VAT Base" := Round(VATAmountLineVATBaseLCY / CalculatedExchRate * CurrExchRate."Exchange Rate Amount");
                            TempVATAmountLine."VAT Amount" := Round(VATAmountLineVATBaseLCY / CalculatedExchRate * CurrExchRate."Exchange Rate Amount");
#else                            
                            TempVATAmountLine."VAT Base (LCY)" := TempVATAmountLine."VAT Base";
                            TempVATAmountLine."VAT Amount (LCY)" := TempVATAmountLine."VAT Amount";
                            TempVATAmountLine."VAT Base" :=
                              Round(TempVATAmountLine."VAT Base (LCY)" / CalculatedExchRate * CurrExchRate."Exchange Rate Amount");
                            TempVATAmountLine."VAT Amount" :=
                              Round(TempVATAmountLine."VAT Amount (LCY)" / CalculatedExchRate * CurrExchRate."Exchange Rate Amount");
#endif
                        end;
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
#if not CLEAN18
                        DataItemLink = "No." = FIELD("Employee No.");
#endif
                        DataItemTableView = SORTING("No.");
                        column(FullName_Employee; Employee.FullName)
                        {
                        }
                        column(PhoneNo_Employee; Employee."Phone No.")
                        {
                        }
                        column(CompanyEMail_Employee; Employee."Company E-Mail")
                        {
                        }
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        CopyNo := 1
                    else
                        CopyNo += 1;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode then
                        CODEUNIT.Run(CODEUNIT::"Sales Cr. Memo-Printed", "Sales Cr.Memo Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;

                    SetRange(Number, 1, NoOfLoops);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageIdOrDefault("Language Code");

#if CLEAN17
                DocFooterText := FormatDocument.GetDocumentFooterText("Language Code");
#else
                DocFooter.SetFilter("Language Code", '%1|%2', '', "Language Code");
                if DocFooter.FindLast then
                    DocFooterText := DocFooter."Footer Text"
                else
                    DocFooterText := '';
#endif                

                if "Currency Code" = '' then
                    "Currency Code" := "General Ledger Setup"."LCY Code";

                if ("Currency Factor" <> 0) and ("Currency Factor" <> 1) then begin
                    CurrExchRate.FindCurrency("Posting Date", "Currency Code", 1);
                    CalculatedExchRate := Round(1 / "Currency Factor" * CurrExchRate."Exchange Rate Amount", 0.00001);
                    ExchRateText :=
                      StrSubstNo(Text009Txt, CalculatedExchRate, "General Ledger Setup"."LCY Code",
                        CurrExchRate."Exchange Rate Amount", "Currency Code");
                end else
                    CalculatedExchRate := 1;
                FormatAddr.SalesCrMemoBillTo(CustAddr, "Sales Cr.Memo Header");

                if "Payment Terms Code" = '' then
                    PaymentTerms.Init
                else begin
                    PaymentTerms.Get("Payment Terms Code");
                    PaymentTerms.TranslateDescription(PaymentTerms, "Language Code");
                end;
                if "Payment Method Code" = '' then
                    PaymentMethod.Init
                else
                    PaymentMethod.Get("Payment Method Code");

                SalesInvoiceHeader.SetRange("Reversed By Cr. Memo No.", "No.");
                if not SalesInvoiceHeader.FindFirst then
                    SalesInvoiceHeader.Init();
#if CLEAN17

                EnlistExtensionFields(FieldValueDictionary, FieldCaptionDictionary);
                ExtensionFieldsManagement.GetRecordExtensionFields("Sales Cr.Memo Header".RecordId, FieldValueDictionary, FieldCaptionDictionary);
#endif
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
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        CurrExchRate: Record "Currency Exchange Rate";
#if not CLEAN17
        DocFooter: Record "Document Footer";
#endif
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
#if CLEAN17
        FormatDocument: Codeunit "Format Document";
        ExtensionFieldsManagement: Codeunit "Extension Fields Management";
        FieldValueDictionary: Dictionary of [Text[30], Text];
        FieldCaptionDictionary: Dictionary of [Text[30], Text];
        RegistrationNoFldTok: Label 'Registration No. CZL', Locked = true;
        VATDateFldTok: Label 'VAT Date CZL', Locked = true;
#endif
#if CLEAN18
        BankAccountNoFldTok: Label 'Bank Account No. CZL', Locked = true;
        IBANFldTok: Label 'IBAN CZL', Locked = true;
        SWIFTCodeFldTok: Label 'SWIFT Code CZL', Locked = true;
#endif
        ExchRateText: Text[50];
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        DocFooterText: Text[250];
        CalculatedExchRate: Decimal;
#if CLEAN18
        VATAmountLineVATBaseLCY: Decimal;
        VATAmountLineVATAmountLCY: Decimal;
#endif
        NoOfCopies: Integer;
        CopyNo: Integer;
        NoOfLoops: Integer;
        Text009Txt: Label 'Exchange Rate %1 %2 / %3 %4', Comment = '%1=calculatedexchrate;%2=general ledger setup.LCY Code;%3=currexchrate.exchange rate amount;%4=currency code';
        DocumentLbl: Label 'VAT Credit Memo to Received Payment';
        PageLbl: Label 'Page';
        CopyLbl: Label 'Copy';
        VendLbl: Label 'Vendor';
        CustLbl: Label 'Customer';
        SalespersonLbl: Label 'Salesperson';
        CreatorLbl: Label 'Posted by';
        VATIdentLbl: Label 'VAT Recapitulation';
        VATPercentLbl: Label 'VAT %';
        VATBaseLbl: Label 'VAT Base';
        VATAmtLbl: Label 'VAT Amount';
        TotalLbl: Label 'total';
        VATLbl: Label 'VAT';
        AdvanceLetterLbl: Label 'VAT Document to Advance Letter';
        OrigAdvanceInvoiceLbl: Label 'Original VAT Document';

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;
#if CLEAN17

    local procedure EnlistExtensionFields(var FieldValueDictionary: Dictionary of [Text[30], Text]; var FieldCaptionDictionary: Dictionary of [Text[30], Text])
    begin
        FieldValueDictionary.Add(RegistrationNoFldTok, '');
        FieldValueDictionary.Add(VATDateFldTok, '');
#if CLEAN18
        FieldValueDictionary.Add(BankAccountNoFldTok, '');
        FieldValueDictionary.Add(IBANFldTok, '');
        FieldValueDictionary.Add(SWIFTCodeFldTok, '');
#endif

        ExtensionFieldsManagement.CopyDictionaryKeys(FieldValueDictionary, FieldCaptionDictionary);
    end;
#endif
}
#endif
