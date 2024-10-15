page 473 "VAT Posting Setup Card"
{
    Caption = 'VAT Posting Setup Card';
    DataCaptionFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";
    PageType = Card;
    SourceTable = "VAT Posting Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Calculation Type"; "VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for this particular combination of VAT business posting group and VAT product posting group.';
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relevant VAT rate for the particular combination of VAT business posting group and VAT product posting group. Do not enter the percent sign, only the number. For example, if the VAT rate is 25 %, enter 25 in this field.';
                }
                field("Unrealized VAT Type"; "Unrealized VAT Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to handle unrealized VAT, which is VAT that is calculated but not due until the invoice is paid.';
                    Visible = UnrealizedVATVisible;
                }
                field("VAT Identifier"; "VAT Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to group various VAT posting setups with similar attributes, for example VAT percentage.';
                }
                field("VAT Clause Code"; "VAT Clause Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT Clause Code that is associated with the VAT Posting Setup.';
                }
                field("EU Service"; "EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this combination of VAT business posting group and VAT product posting group are to be reported as services in the periodic VAT reports.';
                }
                field("Intrastat Service"; "Intrastat Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this combination of VAT business posting group and VAT product posting group is used to the intrastat journal.';
                }
                field("Adjust for Payment Discount"; "Adjust for Payment Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to recalculate VAT amounts when you post payments that trigger payment discounts.';
                    Visible = AdjustForPmtDiscVisible;
                }
                field("Certificate of Supply Required"; "Certificate of Supply Required")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if documents that use this combination of VAT business posting group and VAT product posting group require a certificate of supply.';
                }
                field("Allow Blank VAT Date"; "Allow Blank VAT Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies to post entries with blank VAT dates.';
                }
                field("Non Deduct. VAT Corr. Account"; "Non Deduct. VAT Corr. Account")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the G/L account for correction non deductible VAT entries.';
                }
                field("Reverse Charge Check"; "Reverse Charge Check")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the reverse charge will be checked';
                }
                field("Tax Category"; "Tax Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT category in connection with electronic document sending. For example, when you send sales documents through the PEPPOL service, the value in this field is used to populate the TaxApplied element in the Supplier group. The number is based on the UNCL5305 standard.';
                }
                field("VAT Rate"; "VAT Rate")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies typ of VAT rate - base, reduced or reduced 2.';
                }
                field("Supplies Mode Code"; "Supplies Mode Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies supplies mode code from VAT layer. The setting is used in the VAT control report.';
                }
                field("Corrections for Bad Receivable"; "Corrections for Bad Receivable")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the designation of the receivable for the purposes of VAT control report.';
                }
                field("Ratio Coefficient"; "Ratio Coefficient")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies ratio coefficient';
                }
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Sales VAT Account"; "Sales VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post sales VAT for the particular combination of VAT business posting group and VAT product posting group.';
                }
                field("Sales VAT Unreal. Account"; "Sales VAT Unreal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post unrealized sales VAT (as calculated when you post sales invoices) using this particular combination of VAT business posting group and VAT product posting group.';
                    Visible = UnrealizedVATVisible;
                }
                field("VIES Sales"; "VIES Sales")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies this option to include the posting group in VAT sales declarations.';
                }
                field("Sales VAT Postponed Account"; "Sales VAT Postponed Account")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the sales VAT postponed account for VAT posting setup.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality of Postponing VAT on Sales Cr.Memo will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                    ObsoleteTag = '15.3';
                }
                field("Sales VAT Delay Account"; "Sales VAT Delay Account")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the auxiliary account which will be used for posting date and VAT date by posting the different exchange rate.';
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                field("Purchase VAT Account"; "Purchase VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post purchase VAT for the particular combination of business group and product group.';
                }
                field("Purch. VAT Unreal. Account"; "Purch. VAT Unreal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post unrealized purchase VAT (as calculated when you post purchase invoices) using this particular combination of VAT business posting group and VAT product posting group.';
                    Visible = UnrealizedVATVisible;
                }
                field("Reverse Chrg. VAT Acc."; "Reverse Chrg. VAT Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which you want to post reverse charge VAT (purchase VAT) for this combination of VAT business posting group and VAT product posting group, if you have selected the Reverse Charge VAT option in the VAT Calculation Type field.';
                }
                field("Reverse Chrg. VAT Unreal. Acc."; "Reverse Chrg. VAT Unreal. Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which you want to post amounts for unrealized reverse charge VAT (purchase VAT) for this combination of VAT business posting group and VAT product posting group, if you have selected the Reverse Charge VAT option in the VAT Calculation Type field.';
                    Visible = UnrealizedVATVisible;
                }
                field("Allow Non Deductible VAT"; "Allow Non Deductible VAT")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies to enable non-deductible VAT for VAT posting setup.';
                }
                field("VIES Purchases"; "VIES Purchases")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies this option to include the posting group in VAT purchase declarations.';
                }
                field("Purchase VAT Delay Account"; "Purchase VAT Delay Account")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the auxiliary account which will be used for posting date and VAT date by posting the different exchange rate.';
                }
            }
            group(Advances)
            {
                Caption = 'Advances';
                field("Sales Advance Offset VAT Acc."; "Sales Advance Offset VAT Acc.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the sales advance VAT account for VAT posting setup.';
                }
                field("Sales Advance VAT Account"; "Sales Advance VAT Account")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the sales advance VAT account for VAT posting setup.';
                }
                field("Sales Ded. VAT Base Adj. Acc."; "Sales Ded. VAT Base Adj. Acc.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies he number of the general ledger account for sales ded. vat base adj. Account';
                }
                field("Purch. Advance Offset VAT Acc."; "Purch. Advance Offset VAT Acc.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the purchase advance offset VAT account for VAT posting setup.';
                }
                field("Purch. Advance VAT Account"; "Purch. Advance VAT Account")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the purchase advance VAT account number for VAT posting setup.';
                }
                field("Purch. Ded. VAT Base Adj. Acc."; "Purch. Ded. VAT Base Adj. Acc.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies he number of the general ledger account for purch. ded. vat base adj. account';
                }
            }
            group(Usage)
            {
                Caption = 'Usage';
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SuggestAccounts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Suggest Accounts';
                Image = Default;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Suggest G/L Accounts for selected setup.';

                trigger OnAction()
                begin
                    SuggestSetupAccounts;
                end;
            }
            action(Copy)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Copy';
                Ellipsis = true;
                Image = Copy;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Copy selected fields or all fields in the VAT Posting Setup window to a new record. Before you start to copy, you must create the new record.';

                trigger OnAction()
                begin
                    CurrPage.SaveRecord;
                    CopyVATPostingSetup.SetVATSetup(Rec);
                    CopyVATPostingSetup.RunModal;
                    Clear(CopyVATPostingSetup);
                    CurrPage.Update;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetAccountsVisibility(UnrealizedVATVisible, AdjustForPmtDiscVisible);
    end;

    var
        CopyVATPostingSetup: Report "Copy - VAT Posting Setup";
        UnrealizedVATVisible: Boolean;
        AdjustForPmtDiscVisible: Boolean;
}

