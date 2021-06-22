page 472 "VAT Posting Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Posting Setup';
    CardPageID = "VAT Posting Setup Card";
    DataCaptionFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";
    Editable = true;
    PageType = List;
    SourceTable = "VAT Posting Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
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
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT posting setup';
                }
                field("VAT Identifier"; "VAT Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to group various VAT posting setups with similar attributes, for example VAT percentage.';
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relevant VAT rate for the particular combination of VAT business posting group and VAT product posting group. Do not enter the percent sign, only the number. For example, if the VAT rate is 25 %, enter 25 in this field.';
                    Width = 1;
                }
                field("VAT Calculation Type"; "VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
                }
                field("Unrealized VAT Type"; "Unrealized VAT Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to handle unrealized VAT, which is VAT that is calculated but not due until the invoice is paid.';
                    Visible = UnrealizedVATVisible;
                }
                field("Adjust for Payment Discount"; "Adjust for Payment Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to recalculate VAT amounts when you post payments that trigger payment discounts.';
                    Visible = AdjustForPmtDiscVisible;
                }
                field("Sales VAT Account"; "Sales VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the general ledger account number to which to post sales VAT for the particular combination of VAT business posting group and VAT product posting group.';
                    Width = 1;
                }
                field("Sales VAT Unreal. Account"; "Sales VAT Unreal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger account to post unrealized sales VAT to.';
                    Visible = UnrealizedVATVisible;
                    Width = 1;
                }
                field("Purchase VAT Account"; "Purchase VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the general ledger account number to which to post purchase VAT for the particular combination of business group and product group.';
                    Width = 1;
                }
                field("Purch. VAT Unreal. Account"; "Purch. VAT Unreal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger account to post unrealized purchase VAT to.';
                    Visible = UnrealizedVATVisible;
                    Width = 1;
                }
                field("Reverse Chrg. VAT Acc."; "Reverse Chrg. VAT Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which you want to post reverse charge VAT (purchase VAT) for this combination of VAT business posting group and VAT product posting group, if you have selected the Reverse Charge VAT option in the VAT Calculation Type field.';
                    Width = 1;
                }
                field("Reverse Chrg. VAT Unreal. Acc."; "Reverse Chrg. VAT Unreal. Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger account to post amounts for unrealized reverse charge VAT to.';
                    Visible = UnrealizedVATVisible;
                    Width = 1;
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
                field("Certificate of Supply Required"; "Certificate of Supply Required")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if documents that use this combination of VAT business posting group and VAT product posting group require a certificate of supply.';
                    Visible = false;
                }
                field("Tax Category"; "Tax Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT category in connection with electronic document sending. For example, when you send sales documents through the PEPPOL service, the value in this field is used to populate the TaxApplied element in the Supplier group. The number is based on the UNCL5305 standard.';
                }
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

