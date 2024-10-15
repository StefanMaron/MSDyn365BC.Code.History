report 11762 "Uncertainty Payer List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './UncertaintyPayerList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Uncertain Payers (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Vendor Posting Group", "Country/Region Code", "Tax Area Code";
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(OnlyErrors_fld; Format(OnlyErrors))
            {
            }
            column(VendorFilters; GetFilters)
            {
            }
            column(No_Vendor_fld; "No.")
            {
            }
            column(Name_Vendor_fld; Name)
            {
            }
            column(CountryCode_Vendor_fld; "Country/Region Code")
            {
            }
            column(VATRegNo_Vendor_fld; "VAT Registration No.")
            {
            }
            column(CheckDate_Vendor_var; Format(UncPayEntry."Check Date"))
            {
            }
            column(UncertPayer_Vendor_var; Format(UncPayEntry."Uncertainty Payer"))
            {
            }
            column(TaxOfficeNo_Vendor_var; UncPayEntry."Tax Office Number")
            {
            }
            column(WarningText_Vendor_var; WarningText)
            {
            }
            dataitem("Vendor Bank Account"; "Vendor Bank Account")
            {
                DataItemLink = "Vendor No." = FIELD("No.");
                DataItemTableView = SORTING("Vendor No.", Code);
                column(BankAccNo_VBA_fld; "Bank Account No.")
                {
                }
                column(IBAN_VBA_fld; IBAN)
                {
                }
                column(PublicBA_VBA_var; Format(PublicBankAccount))
                {
                }
                column(BankAccType_VBA_var; Format(UncPayEntry2."Bank Account No. Type"))
                {
                }
                column(PublicDate_VBA_var; Format(UncPayEntry2."Public Date"))
                {
                }
                column(EndPublicDate_VBA_var; Format(UncPayEntry2."End Public Date"))
                {
                }
                column(RecCount_VBA_var; RecCount)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Vendor VAT Registration No.");
                    PublicBankAccount := UncPayMgmt.IsPublicBankAccount("Vendor No.", "Vendor VAT Registration No.",
                        "Bank Account No.", IBAN);

                    UncPayEntry2.SetRange("VAT Registration No.", "Vendor VAT Registration No.");
                    UncPayEntry2.SetFilter("Full Bank Account No.", '%1|%2', "Bank Account No.", IBAN);
                    if not UncPayEntry2.FindLast then
                        Clear(UncPayEntry2);

                    if OnlyErrors and PublicBankAccount then
                        CurrReport.Skip();

                    RecCount += 1;
                end;

                trigger OnPreDataItem()
                begin
                    if not PrintVendBankAcc then
                        CurrReport.Break();

                    UncPayEntry2.Reset();
                    UncPayEntry2.SetCurrentKey("VAT Registration No.");
                    UncPayEntry2.SetRange("Entry Type", UncPayEntry2."Entry Type"::"Bank Account");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Privacy Blocked" then
                    CurrReport.Skip();

                case Blocked of
                    Blocked::" ":
                        ;
                    Blocked::Payment:
                        ;
                    Blocked::All:
                        CurrReport.Skip();
                end;

                Clear(RecCount);
                Clear(WarningText);

                if "VAT Registration No." <> '' then begin
                    if not UncPayMgmt.IsVATRegNoExportPossible("VAT Registration No.", "Country/Region Code") then
                        CurrReport.Skip();
                end else
                    WarningText := Text004;

                Clear(UncPayEntry);
                if WarningText = '' then begin
                    UncPayEntry.SetRange("VAT Registration No.", "VAT Registration No.");
                    UncPayEntry.SetRange("Entry Type", UncPayEntry."Entry Type"::Payer);
                    if not UncPayEntry.FindLast then begin
                        WarningText := Text001;
                    end else
                        case UncPayEntry."Uncertainty Payer" of
                            UncPayEntry."Uncertainty Payer"::YES:
                                WarningText := Text002;
                            UncPayEntry."Uncertainty Payer"::NOTFOUND:
                                WarningText := Text001;
                        end;
                end;

                if OnlyErrors and (WarningText = '') then begin
                    VendBankAccount.SetRange("Vendor No.", "No.");
                    if VendBankAccount.FindSet then
                        repeat
                            VendBankAccount.CalcFields("Vendor VAT Registration No.");
                            PublicBankAccount := UncPayMgmt.IsPublicBankAccount(VendBankAccount."Vendor No.",
                                VendBankAccount."Vendor VAT Registration No.",
                                VendBankAccount."Bank Account No.", VendBankAccount.IBAN);
                            if not PublicBankAccount then
                                WarningText := Text005;
                        until (VendBankAccount.Next = 0) or (WarningText <> '');
                end;

                if OnlyErrors and (WarningText = '') then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                UncPayEntry.SetCurrentKey("VAT Registration No.");
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
                    field(PrintVendBankAcc; PrintVendBankAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Vendor Bank Accounts';
                        ToolTip = 'Specifies if vendor bank accounts have to be printed.';
                    }
                    field(OnlyErrors; OnlyErrors)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print only errors';
                        ToolTip = 'Specifies if only errors entries have to be printed.';
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
        ReportCaptionLbl = 'VAT pay uncertainty status list';
        VendorTableCaption = 'Vendor';
        PageCaptionLbl = 'Page';
        OnlyErrorsLbl = 'Print only errors:';
        No_Vendor_Lbl = 'No.';
        Name_Vendor_Lbl = 'Name';
        CountryCode_Vendor_Lbl = 'Country Code';
        VATRegNo_Vendor_Lbl = 'VAT Registration No.';
        CheckDate_Vendor_Lbl = 'Check Date';
        UncertPayer_Vendor_Lbl = 'No Reliability Payer';
        TaxOffNo_Vendor_Lbl = 'Tax Office No.';
        AccNo_VBA_Lbl = 'Bank Account No.';
        IBAN_VBA_Lbl = 'IBAN';
        PublicBankAcc_VBA_Lbl = 'Public Bank Account';
        BankAccType_VBA_Lbl = 'Bank Acc. Type';
        PublicDate_VBA_Lbl = 'Public Date';
        UnPublicDate_VBA_Lbl = 'End public Date';
        Printed_Lbl = 'Printed';
        Pages_Of_Report_Lbl = 'Page Of Report';
    }

    var
        UncPayEntry: Record "Uncertainty Payer Entry";
        UncPayEntry2: Record "Uncertainty Payer Entry";
        VendBankAccount: Record "Vendor Bank Account";
        UncPayMgmt: Codeunit "Unc. Payer Mgt.";
        WarningText: Text[250];
        PrintVendBankAcc: Boolean;
        OnlyErrors: Boolean;
        PublicBankAccount: Boolean;
        RecCount: Integer;
        Text001: Label 'Payer uncertainty doesn£ check.';
        Text002: Label 'VAT payer is uncertainty!';
        Text004: Label 'VAT Reg. No. not use!';
        Text005: Label 'Contains non public bank accounts.';
}

