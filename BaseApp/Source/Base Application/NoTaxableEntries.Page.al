page 10740 "No Taxable Entries"
{
    ApplicationArea = VAT;
    Caption = 'No Taxable Entries';
    Editable = false;
    PageType = List;
    SourceTable = "No Taxable Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Base; Base)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Reversed; Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reversed by Entry No."; "Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reversed Entry No."; "Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("EU Service"; "EU Service")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Not In 347"; "Not In 347")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Delivery Operation Code"; "Delivery Operation Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("No Taxable Type"; "No Taxable Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Intracommunity; Intracommunity)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Base (LCY)"; "Base (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base (ACY)"; "Base (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount (ACY)"; "Amount (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

