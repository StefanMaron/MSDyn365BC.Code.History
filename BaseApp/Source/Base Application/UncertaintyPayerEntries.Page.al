#if not CLEAN17
page 11760 "Uncertainty Payer Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Uncertainty Payer Entries (Obsolete)';
    Editable = false;
    PageType = List;
    SourceTable = "Uncertainty Payer Entry";
    UsageCategory = Lists;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Control1220012)
            {
                ShowCaption = false;
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of vendor.';
                }
                field("Vendor Name"; "Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of vendor.';
                    Visible = false;
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number. The field will be used when you do business with partners from EU countries/regions.';
                }
                field("Uncertainty Payer"; "Uncertainty Payer")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if vendor is uncertainty payer.';
                }
                field("Check Date"; "Check Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when uncertainty payer report was checked.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the entry.';
                }
                field("Public Date"; "Public Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account public date (if entry type = bank account) or date when vendor was registered as uncertainty payer (if entry type = payer).';
                }
                field("End Public Date"; "End Public Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account end public date (if entry type = bank account) or date when vendor was registered as certainty payer (if entry type = payer).';
                }
                field("Full Bank Account No."; "Full Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the full bank account number.';
                }
                field("Bank Account No. Type"; "Bank Account No. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies type of bank account. Option: standard (if bank account number is standard account) or No standard (if bank account is IBAN).';
                }
                field("Tax Office Number"; "Tax Office Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax office number for reporting.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number that is assigned to the entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}


#endif