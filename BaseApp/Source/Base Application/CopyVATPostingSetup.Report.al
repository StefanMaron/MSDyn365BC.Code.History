report 85 "Copy - VAT Posting Setup"
{
    Caption = 'Copy - VAT Posting Setup';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Posting Setup"; "VAT Posting Setup")
        {
            DataItemTableView = SORTING("VAT Bus. Posting Group", "VAT Prod. Posting Group");

            trigger OnAfterGetRecord()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                VATPostingSetup.Find;
                if VATSetup then begin
                    "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                    "VAT %" := VATPostingSetup."VAT %";
                    "Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type";
                    "Adjust for Payment Discount" := VATPostingSetup."Adjust for Payment Discount";

                    // NAVCZ
                    "VAT Clause Code" := VATPostingSetup."VAT Clause Code";
                    "Reverse Charge Check" := VATPostingSetup."Reverse Charge Check";
                    "VAT Identifier" := VATPostingSetup."VAT Identifier";
                    "Allow Blank VAT Date" := VATPostingSetup."Allow Blank VAT Date";
                    "VAT Rate" := VATPostingSetup."VAT Rate";
                    "Supplies Mode Code" := VATPostingSetup."Supplies Mode Code";
                    "Corrections for Bad Receivable" := VATPostingSetup."Corrections for Bad Receivable";
                    "Ratio Coefficient" := VATPostingSetup."Ratio Coefficient";
                    // NAVCZ
                end;

                if Sales then begin
                    "Sales VAT Account" := VATPostingSetup."Sales VAT Account";
                    "Sales VAT Unreal. Account" := VATPostingSetup."Sales VAT Unreal. Account";

                    // NAVCZ
                    "Sales VAT Delay Account" := VATPostingSetup."Sales VAT Delay Account";
                    // NAVCZ
                end;

                if Purch then begin
                    "Purchase VAT Account" := VATPostingSetup."Purchase VAT Account";
                    "Purch. VAT Unreal. Account" := VATPostingSetup."Purch. VAT Unreal. Account";
                    "Reverse Chrg. VAT Acc." := VATPostingSetup."Reverse Chrg. VAT Acc.";
                    "Reverse Chrg. VAT Unreal. Acc." := VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.";
                    "Purchase VAT Delay Account" := VATPostingSetup."Purchase VAT Delay Account"; // NAVCZ
                end;

                // NAVCZ
                if VIES then begin
                    "EU Service" := VATPostingSetup."EU Service";
                    "VIES Purchases" := VATPostingSetup."VIES Purchases";
                    "VIES Sales" := VATPostingSetup."VIES Sales";
                end;
                if Adv then begin
                    "Sales Advance Offset VAT Acc." := VATPostingSetup."Sales Advance Offset VAT Acc.";
                    "Purch. Advance Offset VAT Acc." := VATPostingSetup."Purch. Advance Offset VAT Acc.";
                    "Sales Advance VAT Account" := VATPostingSetup."Sales Advance VAT Account";
                    "Purch. Advance VAT Account" := VATPostingSetup."Purch. Advance VAT Account";
                    "Sales Ded. VAT Base Adj. Acc." := VATPostingSetup."Sales Ded. VAT Base Adj. Acc.";
                    "Purch. Ded. VAT Base Adj. Acc." := VATPostingSetup."Purch. Ded. VAT Base Adj. Acc.";
                end;
                // NAVCZ

                OnAfterCopyVATPostingSetup("VAT Posting Setup", VATPostingSetup, Sales, Purch);

                if ConfirmManagement.GetResponseOrDefault(Text000, true) then
                    Modify;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("VAT Bus. Posting Group", UseVATPostingSetup."VAT Bus. Posting Group");
                SetRange("VAT Prod. Posting Group", UseVATPostingSetup."VAT Prod. Posting Group");
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
                    field(VATBusPostingGroup; VATPostingSetup."VAT Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Bus. Posting Group';
                        TableRelation = "VAT Business Posting Group";
                        ToolTip = 'Specifies the VAT business posting group to copy from.';
                    }
                    field(VATProdPostingGroup; VATPostingSetup."VAT Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Prod. Posting Group';
                        TableRelation = "VAT Product Posting Group";
                        ToolTip = 'Specifies the VAT product posting group to copy from.';
                    }
                    field(Copy; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy';
                        OptionCaption = 'All fields,Selected fields';
                        ToolTip = 'Specifies if all fields or only selected fields are copied.';

                        trigger OnValidate()
                        begin
                            if Selection = Selection::"All fields" then
                                AllfieldsSelectionOnValidate;
                        end;
                    }
                    field(VATetc; VATSetup)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT % etc.';
                        ToolTip = 'Specifies if you want to copy the VAT rate.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields";
                        end;
                    }
                    field(SalesAccounts; Sales)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Accounts';
                        ToolTip = 'Specifies if you want to copy the sales VAT accounts.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields";
                        end;
                    }
                    field(PurchaseAccounts; Purch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Accounts';
                        ToolTip = 'Specifies if you want to copy the purchase VAT accounts.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields";
                        end;
                    }
                    field(VIES; VIES)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VIES';
                        ToolTip = 'Specifies if vies fields will be copied';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields"; // NAVCZ
                        end;
                    }
                    field(Adv; Adv)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Advance';
                        ToolTip = 'Specifies if the advance G/L accounts have to be copied.';

                        trigger OnValidate()
                        begin
                            Selection := Selection::"Selected fields"; // NAVCZ
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if Selection = Selection::"All fields" then begin
                VATSetup := true;
                Sales := true;
                Purch := true;
                // NAVCZ
                VIES := true;
                Adv := true;
                // NAVCZ
            end;
        end;
    }

    labels
    {
    }

    var
        Text000: Label 'Copy VAT Posting Setup?';
        UseVATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATSetup: Boolean;
        Sales: Boolean;
        Purch: Boolean;
        Selection: Option "All fields","Selected fields";
        VIES: Boolean;
        Adv: Boolean;

    procedure SetVATSetup(VATPostingSetup2: Record "VAT Posting Setup")
    begin
        UseVATPostingSetup := VATPostingSetup2;
    end;

    local procedure AllfieldsSelectionOnPush()
    begin
        VATSetup := true;
        Sales := true;
        Purch := true;
        // NAVCZ
        VIES := true;
        Adv := true;
        // NAVCZ
    end;

    local procedure AllfieldsSelectionOnValidate()
    begin
        AllfieldsSelectionOnPush;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; FromVATPostingSetup: Record "VAT Posting Setup"; Sales: Boolean; Purch: Boolean)
    begin
    end;
}

