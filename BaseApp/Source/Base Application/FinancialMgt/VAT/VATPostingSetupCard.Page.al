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
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for this particular combination of VAT business posting group and VAT product posting group.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this particular combination of VAT business posting group and VAT product posting group is blocked.';
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relevant VAT rate for the particular combination of VAT business posting group and VAT product posting group. Do not enter the percent sign, only the number. For example, if the VAT rate is 25 %, enter 25 in this field.';
                }
                field("Unrealized VAT Type"; Rec."Unrealized VAT Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to handle unrealized VAT, which is VAT that is calculated but not due until the invoice is paid.';
                    Visible = UnrealizedVATVisible;
                }
                field("VAT Identifier"; Rec."VAT Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to group various VAT posting setups with similar attributes, for example VAT percentage.';
                }
                field("VAT Clause Code"; Rec."VAT Clause Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT Clause Code that is associated with the VAT Posting Setup.';
                }
                field("EU Service"; Rec."EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this combination of VAT business posting group and VAT product posting group are to be reported as services in the periodic VAT reports.';
                }
                field("Adjust for Payment Discount"; Rec."Adjust for Payment Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to recalculate VAT amounts when you post payments that trigger payment discounts.';
                    Visible = AdjustForPmtDiscVisible;
                }
                field("VAT Settlement Rate"; Rec."VAT Settlement Rate")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT settlement rate.';
                }
                field("VAT Code"; Rec."VAT Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT Code to be used with this VAT posting setup.';
                }
                field("Certificate of Supply Required"; Rec."Certificate of Supply Required")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if documents that use this combination of VAT business posting group and VAT product posting group require a certificate of supply.';
                }
                field("Tax Category"; Rec."Tax Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT category in connection with electronic document sending. For example, when you send sales documents through the PEPPOL service, the value in this field is used to populate the TaxApplied element in the Supplier group. The number is based on the UNCL5305 standard.';
                }
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Sales VAT Account"; Rec."Sales VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post sales VAT for the particular combination of VAT business posting group and VAT product posting group.';
                }
                field("Sales VAT Unreal. Account"; Rec."Sales VAT Unreal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post unrealized sales VAT (as calculated when you post sales invoices) using this particular combination of VAT business posting group and VAT product posting group.';
                    Visible = UnrealizedVATVisible;
                }
                field("Sales VAT Reporting Code"; Rec."Sales VAT Reporting Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT code to be used with this VAT posting setup for sales reporting.';
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                field("Purchase VAT Account"; Rec."Purchase VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post purchase VAT for the particular combination of business group and product group.';
                }
                field("Purch. VAT Unreal. Account"; Rec."Purch. VAT Unreal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post unrealized purchase VAT (as calculated when you post purchase invoices) using this particular combination of VAT business posting group and VAT product posting group.';
                    Visible = UnrealizedVATVisible;
                }
                field("Reverse Chrg. VAT Acc."; Rec."Reverse Chrg. VAT Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which you want to post reverse charge VAT (purchase VAT) for this combination of VAT business posting group and VAT product posting group, if you have selected the Reverse Charge VAT option in the VAT Calculation Type field.';
                }
                field("Reverse Chrg. VAT Unreal. Acc."; Rec."Reverse Chrg. VAT Unreal. Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which you want to post amounts for unrealized reverse charge VAT (purchase VAT) for this combination of VAT business posting group and VAT product posting group, if you have selected the Reverse Charge VAT option in the VAT Calculation Type field.';
                    Visible = UnrealizedVATVisible;
                }
                field("Calc. Prop. Deduction VAT"; Rec."Calc. Prop. Deduction VAT")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if you want to calculate proportional deduction when you use this VAT Posting Setup.';
                }
                field("Proportional Deduction VAT %"; Rec."Proportional Deduction VAT %")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the relevant proportional deduction VAT rate for the particular combination of VAT business posting group and VAT product posting group.';
                }
                field("Purchase VAT Reporting Code"; Rec."Purchase VAT Reporting Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT code to be used with this VAT posting setup for purchase reporting.';
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
                ToolTip = 'Suggest G/L Accounts for selected setup.';

                trigger OnAction()
                begin
                    SuggestSetupAccounts();
                end;
            }
            action(Copy)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Copy';
                Ellipsis = true;
                Image = Copy;
                ToolTip = 'Copy selected fields or all fields in the VAT Posting Setup window to a new record. Before you start to copy, you must create the new record.';

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    CopyVATPostingSetup.SetVATSetup(Rec);
                    CopyVATPostingSetup.RunModal();
                    Clear(CopyVATPostingSetup);
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SuggestAccounts_Promoted; SuggestAccounts)
                {
                }
                actionref(Copy_Promoted; Copy)
                {
                }
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

