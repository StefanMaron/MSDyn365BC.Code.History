#if not CLEAN19
report 31022 "Purchase - Advance Cr. Memo CZ"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PurchaseAdvanceCrMemoCZ.rdlc';
    Caption = 'Purchase - Advance Cr. Memo CZ (Obsolete)';
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
        dataitem("Purch. Cr. Memo Hdr."; "Purch. Cr. Memo Hdr.")
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
            column(PurchaserLbl; PurchaserLbl)
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
            column(No_PurchCrMemoHdr; "No.")
            {
            }
            column(VATRegistrationNo_PurchCrMemoHdrCaption; FieldCaption("VAT Registration No."))
            {
            }
            column(VATRegistrationNo_PurchCrMemoHdr; "VAT Registration No.")
            {
            }
            column(RegistrationNo_PurchCrMemoHdrCaption; FieldCaptionDictionary.Get(RegistrationNoFldTok))
            {
            }
            column(RegistrationNo_PurchCrMemoHdr; FieldValueDictionary.Get(RegistrationNoFldTok))
            {
            }
#if CLEAN18
            column(BankAccountNo_PurchCrMemoHdrCaption; FieldCaptionDictionary.Get(BankAccountNoFldTok))
            {
            }
            column(BankAccountNo_PurchCrMemoHdr; FieldValueDictionary.Get(BankAccountNoFldTok))
            {
            }
            column(IBAN_PurchCrMemoHdrCaption; FieldCaptionDictionary.Get(IBANFldTok))
            {
            }
            column(IBAN_PurchCrMemoHdr; FieldValueDictionary.Get(IBANFldTok))
            {
            }
            column(BIC_PurchCrMemoHdrCaption; FieldCaptionDictionary.Get(SWIFTCodeFldTok))
            {
            }
            column(BIC_PurchCrMemoHdr; FieldValueDictionary.Get(SWIFTCodeFldTok))
            {
            }
#else
            column(BankAccountNo_PurchCrMemoHdrCaption; FieldCaption("Bank Account No."))
            {
            }
            column(BankAccountNo_PurchCrMemoHdr; "Bank Account No.")
            {
            }
            column(IBAN_PurchCrMemoHdrCaption; FieldCaption(IBAN))
            {
            }
            column(IBAN_PurchCrMemoHdr; IBAN)
            {
            }
            column(BIC_PurchCrMemoHdrCaption; FieldCaption("SWIFT Code"))
            {
            }
            column(BIC_PurchCrMemoHdr; "SWIFT Code")
            {
            }
#endif
            column(DocumentDate_PurchCrMemoHdrCaption; FieldCaption("Document Date"))
            {
            }
            column(DocumentDate_PurchCrMemoHdr; "Document Date")
            {
            }
            column(VATDate_PurchCrMemoHdrCaption; FieldCaptionDictionary.Get(VATDateFldTok))
            {
            }
            column(VATDate_PurchCrMemoHdr; FieldValueDictionary.Get(VATDateFldTok))
            {
            }
            column(PaymentTerms; PaymentTerms.Description)
            {
            }
            column(PaymentMethod; PaymentMethod.Description)
            {
            }
            column(CurrencyCode_PurchCrMemoHdr; "Currency Code")
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
            column(LetterNo_PurchCrMemoHdr; "Letter No.")
            {
            }
            column(VendAddr1; VendAddr[1])
            {
            }
            column(VendAddr2; VendAddr[2])
            {
            }
            column(VendAddr3; VendAddr[3])
            {
            }
            column(VendAddr4; VendAddr[4])
            {
            }
            column(VendAddr5; VendAddr[5])
            {
            }
            column(VendAddr6; VendAddr[6])
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
                    DataItemLink = Code = FIELD("Purchaser Code");
                    DataItemLinkReference = "Purch. Cr. Memo Hdr.";
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
                    DataItemLinkReference = "Purch. Cr. Memo Hdr.";
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
                        TempVATAmountLine."VAT Base" := -"Advance Base";
                        TempVATAmountLine."Amount Including VAT" := -"Advance Base" - Amount;
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
                        AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                    {
                        AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                        AutoFormatType = 1;
                    }
#if CLEAN18
                    column(VATAmtLineVATBaseLCY; VATAmountLineVATBaseLCY)
#else
                    column(VATAmtLineVATBaseLCY; TempVATAmountLine."VAT Base (LCY)")
#endif
                    {
                        AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                        AutoFormatType = 1;
                    }
#if CLEAN18
                    column(VATAmtLineVATAmtLCY; VATAmountLineVATAmountLCY)
#else
                    column(VATAmtLineVATAmtLCY; TempVATAmountLine."VAT Amount (LCY)")
#endif                    
                    {
                        AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
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
                dataitem("User Setup"; "User Setup")
                {
                    DataItemLink = "User ID" = FIELD("User ID");
                    DataItemLinkReference = "Purch. Cr. Memo Hdr.";
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
                        CODEUNIT.Run(CODEUNIT::"PurchCrMemo-Printed", "Purch. Cr. Memo Hdr.");
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

                DocFooterText := FormatDocument.GetDocumentFooterTextByLanguage("Language Code");

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
                FormatAddr.PurchCrMemoPayTo(VendAddr, "Purch. Cr. Memo Hdr.");   // /???

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

                EnlistExtensionFields(FieldValueDictionary, FieldCaptionDictionary);
                ExtensionFieldsManagement.GetRecordExtensionFields("Purch. Cr. Memo Hdr.".RecordId, FieldValueDictionary, FieldCaptionDictionary);
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
        VATPostingSetup: Record "VAT Posting Setup";
        Language: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        ExtensionFieldsManagement: Codeunit "Extension Fields Management";
        FieldValueDictionary: Dictionary of [Text[30], Text];
        FieldCaptionDictionary: Dictionary of [Text[30], Text];
        RegistrationNoFldTok: Label 'Registration No. CZL', Locked = true;
        VATDateFldTok: Label 'VAT Date CZL', Locked = true;
#if CLEAN18
        BankAccountNoFldTok: Label 'Bank Account No. CZL', Locked = true;
        IBANFldTok: Label 'IBAN CZL', Locked = true;
        SWIFTCodeFldTok: Label 'SWIFT Code CZL', Locked = true;
#endif
        ExchRateText: Text[50];
        CompanyAddr: array[8] of Text[100];
        VendAddr: array[8] of Text[100];
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
        DocumentLbl: Label 'VAT Credit Memo to Paid Payment';
        PageLbl: Label 'Page';
        CopyLbl: Label 'Copy';
        VendLbl: Label 'Vendor';
        CustLbl: Label 'Customer';
        PurchaserLbl: Label 'Purchaser';
        CreatorLbl: Label 'Posted by';
        VATIdentLbl: Label 'VAT Recapitulation';
        VATPercentLbl: Label 'VAT %';
        VATBaseLbl: Label 'VAT Base';
        VATAmtLbl: Label 'VAT Amount';
        TotalLbl: Label 'total';
        VATLbl: Label 'VAT';
        AdvanceLetterLbl: Label 'VAT Document to Advance Letter';

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;

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
}
#endif